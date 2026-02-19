import type { FastifyRequest, FastifyReply } from "fastify";
import { verifyToken } from "./jwt.js";
import type { Config } from "../config.js";

export function createAuthMiddleware(config: Config) {
    return async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
        const authHeader = request.headers.authorization;
        if (!authHeader?.startsWith("Bearer ")) {
            await reply.status(401).send({
                error: "unauthorized",
                message: "Missing or invalid Authorization header",
            });
            return;
        }
        const token = authHeader.slice(7);
        try {
            verifyToken(token, config);
        } catch {
            await reply.status(401).send({
                error: "unauthorized",
                message: "Invalid or expired token",
            });
        }
    };
}
