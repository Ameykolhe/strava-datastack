import OpenAI from "openai";
import type {
    ChatCompletionMessageParam,
    ChatCompletionTool,
} from "openai/resources/chat/completions.js";
import type {
    LLMProvider,
    OrchestratorMessage,
    ChatOptions,
    ProviderChunk,
} from "./base.js";
import type { Config } from "../config.js";

export function createOpenAICompatProvider(config: Config): LLMProvider {
    const client = new OpenAI({
        baseURL: config.OPENAI_API_BASE_URL,
        apiKey: config.OPENAI_API_KEY,
    });

    return {
        async *streamChat(
            messages: OrchestratorMessage[],
            options: ChatOptions,
        ): AsyncGenerator<ProviderChunk> {
            const convertedMessages = convertMessages(messages);
            const convertedTools = convertTools(options);

            const stream = await client.chat.completions.create({
                model: config.OPENAI_MODEL!,
                temperature: options.temperature,
                stream: true,
                messages: convertedMessages,
                ...(convertedTools.length > 0 ? { tools: convertedTools } : {}),
            });

            // Accumulate tool call deltas per index
            const toolCallBuffers = new Map<
                number,
                { id: string; name: string; argsBuffer: string }
            >();
            let accumulatedText = "";
            let stopReason = "stop";

            for await (const chunk of stream) {
                const choice = chunk.choices[0];
                if (!choice) continue;

                const delta = choice.delta;

                if (delta.content) {
                    accumulatedText += delta.content;
                    yield { type: "text_delta", text: delta.content };
                }

                if (delta.tool_calls) {
                    for (const tc of delta.tool_calls) {
                        const idx = tc.index;
                        if (!toolCallBuffers.has(idx)) {
                            toolCallBuffers.set(idx, {
                                id: tc.id ?? "",
                                name: tc.function?.name ?? "",
                                argsBuffer: "",
                            });
                        }
                        const buf = toolCallBuffers.get(idx)!;
                        // id and name only arrive on first chunk for this index
                        if (tc.id) buf.id = tc.id;
                        if (tc.function?.name) buf.name = tc.function.name;
                        if (tc.function?.arguments) buf.argsBuffer += tc.function.arguments;
                    }
                }

                if (choice.finish_reason) {
                    stopReason = choice.finish_reason;
                }
            }

            const pendingToolCalls: Array<{
                id: string;
                name: string;
                input: Record<string, unknown>;
            }> = [];

            for (const buf of toolCallBuffers.values()) {
                try {
                    const input = JSON.parse(buf.argsBuffer || "{}") as Record<
                        string,
                        unknown
                    >;
                    pendingToolCalls.push({ id: buf.id, name: buf.name, input });
                } catch {
                    pendingToolCalls.push({ id: buf.id, name: buf.name, input: {} });
                }
            }

            yield {
                type: "done",
                stopReason,
                tokens: { input: 0, output: 0 },
                pendingToolCalls,
                accumulatedText,
            };
        },
    };
}

function convertMessages(
    messages: OrchestratorMessage[],
): ChatCompletionMessageParam[] {
    const result: ChatCompletionMessageParam[] = [];

    for (const msg of messages) {
        if (msg.role === "user" && msg.toolResults && msg.toolResults.length > 0) {
            // Each tool result becomes a separate "tool" role message
            for (const tr of msg.toolResults) {
                result.push({
                    role: "tool",
                    tool_call_id: tr.callId,
                    content: tr.content,
                });
            }
        } else if (msg.role === "user" && msg.content) {
            result.push({ role: "user", content: msg.content });
        } else if (msg.role === "assistant") {
            const assistantMsg: ChatCompletionMessageParam = {
                role: "assistant",
                content: msg.content ?? null,
                ...(msg.toolCalls && msg.toolCalls.length > 0
                    ? {
                          tool_calls: msg.toolCalls.map((tc) => ({
                              id: tc.id,
                              type: "function" as const,
                              function: {
                                  name: tc.name,
                                  arguments: JSON.stringify(tc.input),
                              },
                          })),
                      }
                    : {}),
            };
            result.push(assistantMsg);
        }
    }

    return result;
}

function convertTools(options: ChatOptions): ChatCompletionTool[] {
    return options.tools.map((t) => ({
        type: "function" as const,
        function: {
            name: t.name,
            description: t.description,
            parameters: t.input_schema as Record<string, unknown>,
        },
    }));
}
