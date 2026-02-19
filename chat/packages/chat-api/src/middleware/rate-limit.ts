import type { FastifyRequest, FastifyReply } from "fastify";
import { RATE_LIMITS } from "@strava-chat/shared/constants";

interface WindowCounter {
    count: number;
    windowStart: number;
}

// In-memory rate limit state (single-user app)
const minuteWindow: WindowCounter = { count: 0, windowStart: Date.now() };
const dayWindow: WindowCounter = { count: 0, windowStart: Date.now() };
const loginWindow: WindowCounter = { count: 0, windowStart: Date.now() };

function checkWindow(
    window: WindowCounter,
    limit: number,
    windowMs: number,
): { allowed: boolean; retryAfterMs: number } {
    const now = Date.now();
    if (now - window.windowStart >= windowMs) {
        window.count = 0;
        window.windowStart = now;
    }
    if (window.count >= limit) {
        const retryAfterMs = windowMs - (now - window.windowStart);
        return { allowed: false, retryAfterMs };
    }
    window.count++;
    return { allowed: true, retryAfterMs: 0 };
}

export function createMessageRateLimiter() {
    return async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
        const perMinute = checkWindow(minuteWindow, RATE_LIMITS.messages_per_minute, 60_000);
        if (!perMinute.allowed) {
            const retryAfterSecs = Math.ceil(perMinute.retryAfterMs / 1000);
            reply.header("Retry-After", String(retryAfterSecs));
            await reply.status(429).send({
                error: "rate_limit_exceeded",
                message: `Too many messages. Try again in ${retryAfterSecs} seconds.`,
            });
            return;
        }

        const perDay = checkWindow(dayWindow, RATE_LIMITS.messages_per_day, 86_400_000);
        if (!perDay.allowed) {
            reply.header("Retry-After", "86400");
            await reply.status(429).send({
                error: "rate_limit_exceeded",
                message: "Daily message limit reached. Try again tomorrow.",
            });
        }
    };
}

export function createLoginRateLimiter() {
    return async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
        const result = checkWindow(loginWindow, RATE_LIMITS.login_attempts_per_minute, 60_000);
        if (!result.allowed) {
            const retryAfterSecs = Math.ceil(result.retryAfterMs / 1000);
            reply.header("Retry-After", String(retryAfterSecs));
            await reply.status(429).send({
                error: "rate_limit_exceeded",
                message: `Too many login attempts. Try again in ${retryAfterSecs} seconds.`,
            });
        }
    };
}
