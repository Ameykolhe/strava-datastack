import Anthropic from "@anthropic-ai/sdk";
import type {
    MessageParam,
    Tool,
    ContentBlockParam,
    ToolResultBlockParam,
} from "@anthropic-ai/sdk/resources/messages.js";
import type {
    LLMProvider,
    OrchestratorMessage,
    ChatOptions,
    ProviderChunk,
} from "./base.js";
import type { Config } from "../config.js";

export function createAnthropicProvider(config: Config): LLMProvider {
    const client = new Anthropic({ apiKey: config.ANTHROPIC_API_KEY });

    return {
        async *streamChat(
            messages: OrchestratorMessage[],
            options: ChatOptions,
        ): AsyncGenerator<ProviderChunk> {
            const anthropicMessages = convertMessages(messages);
            const anthropicTools = convertTools(options);

            const stream = client.messages.stream({
                model: options.model,
                max_tokens: options.maxTokens ?? 4096,
                temperature: options.temperature,
                system: options.system,
                messages: anthropicMessages,
                ...(anthropicTools.length > 0 ? { tools: anthropicTools } : {}),
            });

            // Per-block state for accumulating tool use inputs
            const toolUseBlocks = new Map<
                number,
                { id: string; name: string; partialJson: string }
            >();
            let accumulatedText = "";
            let stopReason = "end_turn";
            let inputTokens = 0;
            let outputTokens = 0;

            for await (const event of stream) {
                switch (event.type) {
                    case "message_start":
                        inputTokens = event.message.usage?.input_tokens ?? 0;
                        break;

                    case "content_block_start":
                        if (event.content_block.type === "tool_use") {
                            toolUseBlocks.set(event.index, {
                                id: event.content_block.id,
                                name: event.content_block.name,
                                partialJson: "",
                            });
                        }
                        break;

                    case "content_block_delta":
                        if (event.delta.type === "text_delta") {
                            accumulatedText += event.delta.text;
                            yield { type: "text_delta", text: event.delta.text };
                        } else if (event.delta.type === "input_json_delta") {
                            const block = toolUseBlocks.get(event.index);
                            if (block) {
                                block.partialJson += event.delta.partial_json;
                            }
                        }
                        break;

                    case "content_block_stop":
                        // Tool use blocks are complete — we'll emit them in the done chunk
                        break;

                    case "message_delta":
                        stopReason = event.delta.stop_reason ?? "end_turn";
                        outputTokens = event.usage?.output_tokens ?? 0;
                        break;

                    case "message_stop":
                        break;
                }
            }

            // Parse all accumulated tool calls
            const pendingToolCalls: Array<{
                id: string;
                name: string;
                input: Record<string, unknown>;
            }> = [];

            for (const block of toolUseBlocks.values()) {
                try {
                    const input = JSON.parse(block.partialJson || "{}") as Record<
                        string,
                        unknown
                    >;
                    pendingToolCalls.push({ id: block.id, name: block.name, input });
                } catch {
                    pendingToolCalls.push({ id: block.id, name: block.name, input: {} });
                }
            }

            yield {
                type: "done",
                stopReason,
                tokens: { input: inputTokens, output: outputTokens },
                pendingToolCalls,
                accumulatedText,
            };
        },
    };
}

function convertMessages(messages: OrchestratorMessage[]): MessageParam[] {
    const result: MessageParam[] = [];

    for (const msg of messages) {
        if (msg.role === "user" && msg.toolResults && msg.toolResults.length > 0) {
            // Tool results go back as user-role messages
            const toolResultContent: ToolResultBlockParam[] = msg.toolResults.map(
                (tr) => ({
                    type: "tool_result" as const,
                    tool_use_id: tr.callId,
                    content: tr.content,
                    is_error: tr.isError,
                }),
            );
            result.push({ role: "user", content: toolResultContent });
        } else if (msg.role === "user" && msg.content) {
            result.push({ role: "user", content: msg.content });
        } else if (msg.role === "assistant") {
            const content: ContentBlockParam[] = [];
            if (msg.content) {
                content.push({ type: "text", text: msg.content });
            }
            if (msg.toolCalls && msg.toolCalls.length > 0) {
                for (const tc of msg.toolCalls) {
                    content.push({
                        type: "tool_use",
                        id: tc.id,
                        name: tc.name,
                        input: tc.input,
                    });
                }
            }
            if (content.length > 0) {
                result.push({ role: "assistant", content });
            }
        }
    }

    return result;
}

function convertTools(options: ChatOptions): Tool[] {
    return options.tools.map((t) => ({
        name: t.name,
        description: t.description,
        input_schema: t.input_schema as Tool["input_schema"],
    }));
}
