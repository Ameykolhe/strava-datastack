import { randomUUID } from "crypto";
import type Database from "better-sqlite3";
import type { StreamEvent } from "@strava-chat/shared/types";
import {
    MAX_TOOL_ROUNDS,
    DEFAULT_MODEL,
    DEFAULT_TEMPERATURE,
} from "@strava-chat/shared/constants";
import type { LLMProvider, OrchestratorMessage } from "../providers/base.js";
import { getTools } from "../mcp/client.js";
import { executeTool } from "../mcp/tool-executor.js";
import { buildSystemPrompt } from "./system-prompt.js";
import {
    insertMessage,
    getMessagesForConversation,
} from "../db/repositories/message.js";
import { touchConversation } from "../db/repositories/conversation.js";
import type { Message, ToolCallReference } from "@strava-chat/shared/types";

export interface ChatSettings {
    model?: string;
    temperature?: number;
}

export async function* orchestrateChat(
    db: Database.Database,
    provider: LLMProvider,
    conversationId: string,
    userContent: string,
    settings?: ChatSettings,
): AsyncGenerator<StreamEvent> {
    const messageId = `msg_${randomUUID().replace(/-/g, "").slice(0, 12)}`;
    const model = settings?.model ?? DEFAULT_MODEL;
    const temperature = settings?.temperature ?? DEFAULT_TEMPERATURE;

    // Load conversation history and convert to orchestrator format
    const history = getMessagesForConversation(db, conversationId);
    const messages: OrchestratorMessage[] = buildOrchestratorMessages(history);

    // Add the new user message
    messages.push({ role: "user", content: userContent });

    // Persist user message immediately
    insertMessage(db, {
        conversation_id: conversationId,
        role: "user",
        content: userContent,
    });

    // Signal stream start
    yield {
        type: "message_start",
        id: messageId,
        role: "assistant",
        model,
    } satisfies StreamEvent;

    const tools = getTools();
    const systemPrompt = buildSystemPrompt();
    const chatOptions = { model, temperature, system: systemPrompt, tools };

    // Accumulated state across tool rounds
    let finalText = "";
    const allToolCalls: ToolCallReference[] = [];
    let totalInputTokens = 0;
    let totalOutputTokens = 0;
    let stopReason = "end_turn";

    for (let round = 0; round < MAX_TOOL_ROUNDS; round++) {
        let roundText = "";
        const roundToolCalls: Array<{
            id: string;
            name: string;
            input: Record<string, unknown>;
        }> = [];

        // Stream from LLM
        for await (const chunk of provider.streamChat(messages, chatOptions)) {
            if (chunk.type === "text_delta") {
                roundText += chunk.text;
                yield { type: "content_delta", text: chunk.text } satisfies StreamEvent;
            } else if (chunk.type === "done") {
                stopReason = chunk.stopReason;
                totalInputTokens += chunk.tokens.input;
                totalOutputTokens += chunk.tokens.output;
                roundToolCalls.push(...chunk.pendingToolCalls);
                // If there's leftover text not already yielded
                // (shouldn't happen since we yield text_delta in real-time)
            }
        }

        finalText += roundText;

        if (stopReason !== "tool_use" || roundToolCalls.length === 0) {
            break;
        }

        // Add assistant message with tool calls to the conversation
        messages.push({
            role: "assistant",
            content: roundText || undefined,
            toolCalls: roundToolCalls,
        });

        // Execute tool calls and collect results
        const toolResults: OrchestratorMessage["toolResults"] = [];

        for (const tc of roundToolCalls) {
            // Signal tool invocation to client
            yield {
                type: "tool_use_start",
                id: tc.id,
                tool_name: tc.name,
                input: tc.input,
            } satisfies StreamEvent;

            const result = await executeTool(tc.id, tc.name, tc.input);

            // Signal tool result to client
            yield {
                type: "tool_result",
                id: tc.id,
                output: result.output,
                duration_ms: result.duration_ms,
            } satisfies StreamEvent;

            // Record for persistence
            allToolCalls.push({
                id: tc.id,
                tool_name: tc.name,
                input: tc.input,
                output: result.output,
                duration_ms: result.duration_ms,
            });

            toolResults.push({
                callId: tc.id,
                content: JSON.stringify(result.output),
                isError: result.isError,
            });
        }

        // Add tool results as next user message
        messages.push({
            role: "user",
            toolResults,
        });
    }

    // Persist assistant message with all tool calls
    insertMessage(db, {
        conversation_id: conversationId,
        role: "assistant",
        content: finalText,
        tool_calls: allToolCalls,
        model,
        tokens_used: { input: totalInputTokens, output: totalOutputTokens },
    });

    // Update conversation timestamp
    touchConversation(db, conversationId);

    yield {
        type: "message_end",
        id: messageId,
        tokens_used: { input: totalInputTokens, output: totalOutputTokens },
        stop_reason: stopReason,
    } satisfies StreamEvent;
}

function buildOrchestratorMessages(history: Message[]): OrchestratorMessage[] {
    const result: OrchestratorMessage[] = [];

    for (const msg of history) {
        if (msg.role === "user") {
            result.push({ role: "user", content: msg.content });
        } else if (msg.role === "assistant") {
            const orchestratorMsg: OrchestratorMessage = {
                role: "assistant",
                content: msg.content || undefined,
            };

            if (msg.tool_calls && msg.tool_calls.length > 0) {
                orchestratorMsg.toolCalls = msg.tool_calls.map((tc) => ({
                    id: tc.id,
                    name: tc.tool_name,
                    input: tc.input,
                }));

                // Tool results need to follow as a "user" message
                const toolResults = msg.tool_calls
                    .filter((tc) => tc.output !== null)
                    .map((tc) => ({
                        callId: tc.id,
                        content: JSON.stringify(tc.output),
                        isError: false,
                    }));

                result.push(orchestratorMsg);

                if (toolResults.length > 0) {
                    result.push({ role: "user", toolResults });
                }
                continue;
            }

            result.push(orchestratorMsg);
        }
    }

    return result;
}
