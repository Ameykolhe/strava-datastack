export interface ToolDefinition {
    name: string;
    description: string;
    input_schema: Record<string, unknown>;
}

export interface ToolCall {
    id: string;
    tool_name: string;
    input: Record<string, unknown>;
}

export interface ToolResult {
    id: string;
    tool_name: string;
    output: Record<string, unknown>;
    is_error: boolean;
    duration_ms: number;
}
