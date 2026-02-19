import type { FastifyInstance, FastifyRequest, FastifyReply } from "fastify";
import type Database from "better-sqlite3";
import {
    createConversation,
    listConversations,
    getConversationById,
    updateConversationTitle,
    archiveConversation,
} from "../db/repositories/conversation.js";
import { getMessagesForConversation } from "../db/repositories/message.js";
import { orchestrateChat } from "../chat/orchestrator.js";
import { initSseResponse, writeSseEvent, startHeartbeat } from "../chat/stream.js";
import { createAuthMiddleware } from "../auth/middleware.js";
import { createMessageRateLimiter } from "../middleware/rate-limit.js";
import type { LLMProvider } from "../providers/base.js";
import type { Config } from "../config.js";
import type { Message } from "@strava-chat/shared/types";
import { MAX_MESSAGE_LENGTH } from "@strava-chat/shared/constants";

interface CreateConversationBody {
    title?: string;
}

interface UpdateConversationBody {
    title: string;
}

interface SendMessageBody {
    content: string;
    settings?: {
        model?: string;
        temperature?: number;
    };
}

interface ListQuery {
    limit?: string;
    offset?: string;
}

interface ExportQuery {
    format?: string;
}

export async function registerConversationRoutes(
    server: FastifyInstance,
    db: Database.Database,
    provider: LLMProvider,
    config: Config,
): Promise<void> {
    const auth = createAuthMiddleware(config);
    const msgRateLimiter = createMessageRateLimiter();

    // POST /api/chat/conversations — create new conversation
    server.post<{ Body: CreateConversationBody }>(
        "/api/chat/conversations",
        { preHandler: auth },
        async (request, reply) => {
            const conversation = createConversation(db, request.body?.title);
            return reply.status(201).send(conversation);
        },
    );

    // GET /api/chat/conversations — list conversations
    server.get<{ Querystring: ListQuery }>(
        "/api/chat/conversations",
        { preHandler: auth },
        async (request, reply) => {
            const limit = Math.min(Number(request.query.limit ?? 20), 100);
            const offset = Number(request.query.offset ?? 0);
            const result = listConversations(db, limit, offset);
            return reply.send({
                ...result,
                has_more: offset + result.conversations.length < result.total,
            });
        },
    );

    // GET /api/chat/conversations/:id — get conversation with messages
    server.get<{ Params: { id: string } }>(
        "/api/chat/conversations/:id",
        { preHandler: auth },
        async (request, reply) => {
            const conversation = getConversationById(db, request.params.id);
            if (!conversation) {
                return reply
                    .status(404)
                    .send({ error: "not_found", message: "Conversation not found" });
            }
            return reply.send(conversation);
        },
    );

    // PATCH /api/chat/conversations/:id — update title
    server.patch<{ Params: { id: string }; Body: UpdateConversationBody }>(
        "/api/chat/conversations/:id",
        { preHandler: auth },
        async (request, reply) => {
            const { title } = request.body ?? {};
            if (!title?.trim()) {
                return reply
                    .status(400)
                    .send({ error: "bad_request", message: "title is required" });
            }
            const result = updateConversationTitle(db, request.params.id, title);
            if (!result) {
                return reply
                    .status(404)
                    .send({ error: "not_found", message: "Conversation not found" });
            }
            return reply.send(result);
        },
    );

    // DELETE /api/chat/conversations/:id — archive conversation
    server.delete<{ Params: { id: string } }>(
        "/api/chat/conversations/:id",
        { preHandler: auth },
        async (request, reply) => {
            const archived = archiveConversation(db, request.params.id);
            if (!archived) {
                return reply
                    .status(404)
                    .send({ error: "not_found", message: "Conversation not found" });
            }
            return reply.status(204).send();
        },
    );

    // POST /api/chat/conversations/:id/messages — send message (SSE stream)
    server.post<{ Params: { id: string }; Body: SendMessageBody }>(
        "/api/chat/conversations/:id/messages",
        { preHandler: [auth, msgRateLimiter] },
        async (
            request: FastifyRequest<{ Params: { id: string }; Body: SendMessageBody }>,
            reply: FastifyReply,
        ) => {
            const { id } = request.params;
            const { content, settings } = request.body ?? {};

            // Validate
            if (!content?.trim()) {
                return reply
                    .status(400)
                    .send({ error: "bad_request", message: "content is required" });
            }
            if (content.length > MAX_MESSAGE_LENGTH) {
                return reply.status(400).send({
                    error: "bad_request",
                    message: `Message too long (max ${MAX_MESSAGE_LENGTH} characters)`,
                });
            }
            const conversation = getConversationById(db, id);
            if (!conversation) {
                return reply
                    .status(404)
                    .send({ error: "not_found", message: "Conversation not found" });
            }

            // Hijack response for SSE
            reply.hijack();
            const res = reply.raw;
            initSseResponse(res);

            const heartbeat = startHeartbeat(res);

            try {
                for await (const event of orchestrateChat(
                    db,
                    provider,
                    id,
                    content.trim(),
                    settings,
                )) {
                    if (!res.writableEnded) {
                        writeSseEvent(res, event);
                    }
                }
            } catch (error: unknown) {
                const message =
                    error instanceof Error ? error.message : "An unexpected error occurred";
                request.log.error({ error, conversation_id: id }, "Chat orchestration error");

                if (!res.writableEnded) {
                    writeSseEvent(res, {
                        type: "error",
                        code: "orchestration_error",
                        message,
                        retryable: true,
                    });
                }
            } finally {
                clearInterval(heartbeat);
                if (!res.writableEnded) res.end();
            }
        },
    );

    // GET /api/chat/conversations/:id/export — export as markdown
    server.get<{ Params: { id: string }; Querystring: ExportQuery }>(
        "/api/chat/conversations/:id/export",
        { preHandler: auth },
        async (request, reply) => {
            const conversation = getConversationById(db, request.params.id);
            if (!conversation) {
                return reply
                    .status(404)
                    .send({ error: "not_found", message: "Conversation not found" });
            }

            const format = request.query.format ?? "markdown";
            if (format !== "markdown") {
                return reply
                    .status(400)
                    .send({ error: "bad_request", message: "Only format=markdown is supported" });
            }

            const messages = getMessagesForConversation(db, conversation.id);
            const markdown = buildMarkdownExport(conversation.title, messages);
            const filename = `${slugify(conversation.title)}-${conversation.created_at.slice(0, 10)}.md`;

            return reply
                .status(200)
                .header("Content-Type", "text/markdown; charset=utf-8")
                .header("Content-Disposition", `attachment; filename="${filename}"`)
                .send(markdown);
        },
    );
}

function buildMarkdownExport(title: string, messages: Message[]): string {
    const lines: string[] = [
        `# ${title}`,
        "",
        `*Exported on ${new Date().toLocaleDateString()}*`,
        "",
        "---",
        "",
    ];

    for (const msg of messages) {
        if (msg.role === "user") {
            lines.push(`**You:** ${msg.content}`, "");
        } else if (msg.role === "assistant") {
            lines.push("**Assistant:**", "");
            lines.push(msg.content, "");

            if (msg.tool_calls && msg.tool_calls.length > 0) {
                for (const tc of msg.tool_calls) {
                    lines.push(
                        `> 🔧 **Tool:** \`${tc.tool_name}\``,
                        `> Input: \`${JSON.stringify(tc.input)}\``,
                        "",
                    );
                }
            }
        }
        lines.push("---", "");
    }

    return lines.join("\n");
}

function slugify(text: string): string {
    return text
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-+|-+$/g, "")
        .slice(0, 50);
}
