import type { ToolDefinition } from "@strava-chat/shared/types";

/**
 * Internal message format used by the orchestrator.
 * Converted to provider-specific format by each adapter.
 */
export interface OrchestratorMessage {
    role: "user" | "assistant";
    /** Text content (user messages and assistant text) */
    content?: string;
    /** Tool calls made by the assistant (accumulated from tool_use blocks) */
    toolCalls?: Array<{
        id: string;
        name: string;
        input: Record<string, unknown>;
    }>;
    /** Tool results (sent back as a "user" role message in Anthropic's format) */
    toolResults?: Array<{
        callId: string;
        content: string;
        isError: boolean;
    }>;
}

export interface ChatOptions {
    model: string;
    temperature: number;
    system: string;
    tools: ToolDefinition[];
    maxTokens?: number;
}

/** Streamed text delta from the LLM */
export interface TextDeltaChunk {
    type: "text_delta";
    text: string;
}

/** Final summary after the streaming call completes */
export interface DoneChunk {
    type: "done";
    stopReason: string;
    tokens: { input: number; output: number };
    pendingToolCalls: Array<{
        id: string;
        name: string;
        input: Record<string, unknown>;
    }>;
    accumulatedText: string;
}

export type ProviderChunk = TextDeltaChunk | DoneChunk;

export interface LLMProvider {
    streamChat(
        messages: OrchestratorMessage[],
        options: ChatOptions,
    ): AsyncGenerator<ProviderChunk>;
}
