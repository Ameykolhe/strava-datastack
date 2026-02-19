import type { FastifyInstance } from "fastify";

const REDACTED_PATTERNS = [
    /token/i,
    /secret/i,
    /password/i,
    /key/i,
    /authorization/i,
];

function redactSensitiveFields(obj: Record<string, unknown>): Record<string, unknown> {
    const result: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(obj)) {
        if (REDACTED_PATTERNS.some((p) => p.test(k))) {
            result[k] = "[REDACTED]";
        } else if (v && typeof v === "object" && !Array.isArray(v)) {
            result[k] = redactSensitiveFields(v as Record<string, unknown>);
        } else {
            result[k] = v;
        }
    }
    return result;
}

export function registerAuditLogger(server: FastifyInstance): void {
    server.addHook("onRequest", async (request) => {
        request.log.info(
            {
                event: "http_request",
                method: request.method,
                url: request.url,
                ip: request.ip,
            },
            "incoming request",
        );
    });

    server.addHook("onResponse", async (request, reply) => {
        request.log.info(
            {
                event: "http_response",
                method: request.method,
                url: request.url,
                status: reply.statusCode,
                duration_ms: reply.elapsedTime,
            },
            "request completed",
        );
    });
}

export function auditLlmCall(
    log: FastifyInstance["log"],
    params: {
        conversation_id: string;
        model: string;
        prompt_preview: string;
    },
): void {
    log.info(
        {
            event: "llm_call_start",
            conversation_id: params.conversation_id,
            model: params.model,
            prompt_preview: params.prompt_preview.slice(0, 500),
        },
        "LLM call started",
    );
}

export function auditToolCall(
    log: FastifyInstance["log"],
    params: {
        conversation_id: string;
        tool_name: string;
        input: Record<string, unknown>;
        duration_ms: number;
        row_count?: number;
    },
): void {
    log.info(
        {
            event: "tool_call_completed",
            conversation_id: params.conversation_id,
            tool_name: params.tool_name,
            input: redactSensitiveFields(params.input),
            duration_ms: params.duration_ms,
            ...(params.row_count !== undefined ? { row_count: params.row_count } : {}),
        },
        "tool call completed",
    );
}
