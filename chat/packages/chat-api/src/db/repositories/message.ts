import { randomUUID } from "crypto";
import type Database from "better-sqlite3";
import type { Message, ToolCallReference, TokenUsage } from "@strava-chat/shared/types";

export function insertMessage(
    db: Database.Database,
    params: {
        conversation_id: string;
        role: "user" | "assistant" | "system";
        content: string;
        tool_calls?: ToolCallReference[];
        model?: string;
        tokens_used?: TokenUsage;
    },
): Message {
    const id = `msg_${randomUUID().replace(/-/g, "").slice(0, 12)}`;
    const now = new Date().toISOString();
    const tool_calls = JSON.stringify(params.tool_calls ?? []);
    const tokens_used = params.tokens_used
        ? JSON.stringify(params.tokens_used)
        : null;

    db.prepare(
        `INSERT INTO messages (id, conversation_id, role, content, tool_calls, model, tokens_used, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    ).run(
        id,
        params.conversation_id,
        params.role,
        params.content,
        tool_calls,
        params.model ?? null,
        tokens_used,
        now,
    );

    return {
        id,
        conversation_id: params.conversation_id,
        role: params.role,
        content: params.content,
        tool_calls: params.tool_calls ?? [],
        model: params.model ?? null,
        tokens_used: params.tokens_used ?? null,
        created_at: now,
    };
}

export function getMessagesForConversation(
    db: Database.Database,
    conversation_id: string,
): Message[] {
    const rows = db
        .prepare(
            `SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC`,
        )
        .all(conversation_id) as Array<{
        id: string;
        conversation_id: string;
        role: string;
        content: string;
        tool_calls: string;
        model: string | null;
        tokens_used: string | null;
        created_at: string;
    }>;

    return rows.map((r) => ({
        id: r.id,
        conversation_id: r.conversation_id,
        role: r.role as "user" | "assistant" | "system",
        content: r.content,
        tool_calls: JSON.parse(r.tool_calls) as ToolCallReference[],
        model: r.model,
        tokens_used: r.tokens_used
            ? (JSON.parse(r.tokens_used) as TokenUsage)
            : null,
        created_at: r.created_at,
    }));
}
