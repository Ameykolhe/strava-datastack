import type { FastifyInstance } from "fastify";
import bcrypt from "bcryptjs";
import { signToken } from "../auth/jwt.js";
import { createLoginRateLimiter } from "../middleware/rate-limit.js";
import type { Config } from "../config.js";

interface LoginBody {
    password: string;
}

export async function registerAuthRoutes(
    server: FastifyInstance,
    config: Config,
): Promise<void> {
    const loginRateLimiter = createLoginRateLimiter();

    server.post<{ Body: LoginBody }>(
        "/api/auth/login",
        {
            preHandler: loginRateLimiter,
        },
        async (request, reply) => {
            const { password } = request.body ?? {};

            if (!password || typeof password !== "string") {
                return reply.status(400).send({
                    error: "bad_request",
                    message: "password is required",
                });
            }

            const valid = await bcrypt.compare(password, config.CHAT_PASSWORD_HASH);
            if (!valid) {
                request.log.warn({ event: "login_failed" }, "Invalid login attempt");
                return reply.status(401).send({
                    error: "invalid_credentials",
                    message: "Invalid password",
                });
            }

            const { token, expires_at } = signToken(config);
            request.log.info({ event: "login_success" }, "Login successful");
            return reply.status(200).send({ token, expires_at });
        },
    );
}
