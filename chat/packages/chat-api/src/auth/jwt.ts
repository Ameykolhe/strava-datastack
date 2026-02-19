import jwt from "jsonwebtoken";
import { JWT_EXPIRY_SECONDS } from "@strava-chat/shared/constants";
import type { Config } from "../config.js";

export interface JwtPayload {
    sub: string;
    iat: number;
    exp: number;
}

export function signToken(config: Config): { token: string; expires_at: string } {
    const token = jwt.sign({ sub: "owner" }, config.CHAT_JWT_SECRET, {
        expiresIn: JWT_EXPIRY_SECONDS,
    });
    const expires_at = new Date(
        Date.now() + JWT_EXPIRY_SECONDS * 1000,
    ).toISOString();
    return { token, expires_at };
}

export function verifyToken(token: string, config: Config): JwtPayload {
    return jwt.verify(token, config.CHAT_JWT_SECRET) as JwtPayload;
}
