import { callMcpTool } from "./client.js";
import { QUERY_TIMEOUT_MS } from "@strava-chat/shared/constants";

export interface ToolExecutionResult {
    callId: string;
    toolName: string;
    output: Record<string, unknown>;
    isError: boolean;
    duration_ms: number;
}

export async function executeTool(
    callId: string,
    toolName: string,
    input: Record<string, unknown>,
): Promise<ToolExecutionResult> {
    const start = Date.now();

    const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(
            () => reject(new Error(`Tool "${toolName}" timed out after ${QUERY_TIMEOUT_MS}ms`)),
            QUERY_TIMEOUT_MS,
        ),
    );

    try {
        const { content, isError } = await Promise.race([
            callMcpTool(toolName, input),
            timeoutPromise,
        ]);

        return {
            callId,
            toolName,
            output: content,
            isError,
            duration_ms: Date.now() - start,
        };
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : "Unknown error";
        return {
            callId,
            toolName,
            output: { error: "tool_execution_error", message },
            isError: true,
            duration_ms: Date.now() - start,
        };
    }
}
