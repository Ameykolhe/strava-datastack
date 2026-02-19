import Fastify from "fastify";
import cors from "@fastify/cors";
import type Database from "better-sqlite3";
import type { LLMProvider } from "./providers/base.js";
import type { Config } from "./config.js";
import { registerAuthRoutes } from "./routes/auth.js";
import { registerConversationRoutes } from "./routes/conversations.js";
import { registerHealthRoutes } from "./routes/health.js";
import { registerAuditLogger } from "./middleware/audit-log.js";

export async function createServer(
    config: Config,
    db: Database.Database,
    provider: LLMProvider,
) {
    const server = Fastify({
        logger: {
            level: config.LOG_LEVEL,
            ...(config.NODE_ENV === "development"
                ? {
                      transport: {
                          target: "pino-pretty",
                          options: { colorize: true },
                      },
                  }
                : {}),
        },
    });

    await server.register(cors, {
        origin: [config.CHAT_UI_ORIGIN],
        methods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
        allowedHeaders: ["Content-Type", "Authorization"],
        credentials: true,
    });

    registerAuditLogger(server);
    registerHealthRoutes(server, db);
    await registerAuthRoutes(server, config);
    await registerConversationRoutes(server, db, provider, config);

    return server;
}
