import { randomUUID } from "crypto";
import type Database from "better-sqlite3";
import type { Conversation, ConversationSummary } from "@strava-chat/shared/types";

interface ConversationRow {
    id: string;
    title: string;
    created_at: string;
    updated_at: string;
    archived_at: string | null;
}

export function createConversation(
    db: Database.Database,
    title?: string,
): ConversationSummary {
    const id = `conv_${randomUUID().replace(/-/g, "").slice(0, 12)}`;
    const now = new Date().toISOString();
    const resolvedTitle = title?.trim() || "New conversation";

    db.prepare(
        `INSERT INTO conversations (id, title, created_at, updated_at) VALUES (?, ?, ?, ?)`,
    ).run(id, resolvedTitle, now, now);

    return {
        id,
        title: resolvedTitle,
        created_at: now,
        updated_at: now,
        message_count: 0,
        last_message_preview: null,
    };
}

export function listConversations(
    db: Database.Database,
    limit: number,
    offset: number,
): { conversations: ConversationSummary[]; total: number } {
    const total = (
        db
            .prepare(
                `SELECT COUNT(*) as count FROM conversations WHERE archived_at IS NULL`,
            )
            .get() as { count: number }
    ).count;

    const rows = db
        .prepare(
            `
            SELECT c.id, c.title, c.created_at, c.updated_at,
                   COUNT(m.id)   AS message_count,
                   (SELECT m2.content FROM messages m2
                    WHERE m2.conversation_id = c.id
                    ORDER BY m2.created_at DESC LIMIT 1) AS last_message_preview
            FROM conversations c
            LEFT JOIN messages m ON m.conversation_id = c.id
            WHERE c.archived_at IS NULL
            GROUP BY c.id
            ORDER BY c.updated_at DESC
            LIMIT ? OFFSET ?
        `,
        )
        .all(limit, offset) as Array<
        ConversationRow & {
            message_count: number;
            last_message_preview: string | null;
        }
    >;

    const conversations: ConversationSummary[] = rows.map((r) => ({
        id: r.id,
        title: r.title,
        created_at: r.created_at,
        updated_at: r.updated_at,
        message_count: r.message_count,
        last_message_preview: r.last_message_preview
            ? r.last_message_preview.slice(0, 100)
            : null,
    }));

    return { conversations, total };
}

export function getConversationById(
    db: Database.Database,
    id: string,
): Conversation | null {
    const row = db
        .prepare(`SELECT * FROM conversations WHERE id = ? AND archived_at IS NULL`)
        .get(id) as ConversationRow | undefined;

    if (!row) return null;

    const messageRows = db
        .prepare(
            `SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC`,
        )
        .all(id) as Array<{
        id: string;
        conversation_id: string;
        role: string;
        content: string;
        tool_calls: string;
        model: string | null;
        tokens_used: string | null;
        created_at: string;
    }>;

    return {
        id: row.id,
        title: row.title,
        created_at: row.created_at,
        updated_at: row.updated_at,
        archived_at: row.archived_at,
        messages: messageRows.map((m) => ({
            id: m.id,
            conversation_id: m.conversation_id,
            role: m.role as "user" | "assistant" | "system",
            content: m.content,
            tool_calls: JSON.parse(m.tool_calls) as [],
            model: m.model,
            tokens_used: m.tokens_used
                ? (JSON.parse(m.tokens_used) as { input: number; output: number })
                : null,
            created_at: m.created_at,
        })),
    };
}

export function updateConversationTitle(
    db: Database.Database,
    id: string,
    title: string,
): { id: string; title: string } | null {
    const now = new Date().toISOString();
    const info = db
        .prepare(
            `UPDATE conversations SET title = ?, updated_at = ? WHERE id = ? AND archived_at IS NULL`,
        )
        .run(title.trim(), now, id);

    if (info.changes === 0) return null;
    return { id, title: title.trim() };
}

export function archiveConversation(db: Database.Database, id: string): boolean {
    const now = new Date().toISOString();
    const info = db
        .prepare(
            `UPDATE conversations SET archived_at = ? WHERE id = ? AND archived_at IS NULL`,
        )
        .run(now, id);
    return info.changes > 0;
}

export function touchConversation(db: Database.Database, id: string): void {
    db.prepare(`UPDATE conversations SET updated_at = ? WHERE id = ?`).run(
        new Date().toISOString(),
        id,
    );
}
