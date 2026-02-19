/**
 * SSE stream event types — discriminated union on `type` field.
 * Each event corresponds to one SSE `event:` line sent to the client.
 */

export interface MessageStartEvent {
    type: "message_start";
    id: string;
    role: "assistant";
    model: string;
}

export interface ContentDeltaEvent {
    type: "content_delta";
    text: string;
}

export interface ToolUseStartEvent {
    type: "tool_use_start";
    id: string;
    tool_name: string;
    input: Record<string, unknown>;
}

export interface ToolResultEvent {
    type: "tool_result";
    id: string;
    output: Record<string, unknown>;
    duration_ms: number;
}

export interface MessageEndEvent {
    type: "message_end";
    id: string;
    tokens_used: { input: number; output: number };
    stop_reason: string;
}

export interface StreamErrorEvent {
    type: "error";
    code: string;
    message: string;
    retryable: boolean;
}

export type StreamEvent =
    | MessageStartEvent
    | ContentDeltaEvent
    | ToolUseStartEvent
    | ToolResultEvent
    | MessageEndEvent
    | StreamErrorEvent;
