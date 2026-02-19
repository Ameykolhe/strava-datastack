import type { FastifyInstance } from "fastify";
import type Database from "better-sqlite3";
import { isMcpConnected } from "../mcp/client.js";
import type { HealthResponse } from "@strava-chat/shared/types";

export function registerHealthRoutes(
    server: FastifyInstance,
    db: Database.Database,
): void {
    server.get("/health", async (_request, reply) => {
        const checks: HealthResponse["checks"] = {
            mcp_server: isMcpConnected() ? "ok" : "error",
            sqlite: "ok",
        };

        // Verify SQLite is responsive
        try {
            db.prepare("SELECT 1").get();
        } catch {
            checks["sqlite"] = "error";
        }

        const allOk = Object.values(checks).every((v) => v === "ok");
        const status: HealthResponse["status"] = allOk ? "healthy" : "degraded";

        return reply.status(allOk ? 200 : 503).send({
            status,
            version: "0.1.0",
            checks,
        } satisfies HealthResponse);
    });
}
