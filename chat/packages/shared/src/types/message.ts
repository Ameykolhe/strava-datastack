export type Role = "user" | "assistant" | "system";

export interface ToolCallReference {
    id: string;
    tool_name: string;
    input: Record<string, unknown>;
    output: Record<string, unknown> | null;
    duration_ms: number | null;
}

export interface TokenUsage {
    input: number;
    output: number;
}

export interface Message {
    id: string;
    conversation_id: string;
    role: Role;
    content: string;
    tool_calls: ToolCallReference[];
    model: string | null;
    tokens_used: TokenUsage | null;
    created_at: string;
}
