import type { IncomingMessage, ServerResponse } from "http";
import type { StreamEvent } from "@strava-chat/shared/types";
import { SSE_HEARTBEAT_MS } from "@strava-chat/shared/constants";

export function initSseResponse(res: ServerResponse<IncomingMessage>): void {
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.setHeader("X-Accel-Buffering", "no");
    res.flushHeaders();
}

export function writeSseEvent(
    res: ServerResponse<IncomingMessage>,
    event: StreamEvent,
): void {
    const data = JSON.stringify(event);
    res.write(`event: ${event.type}\ndata: ${data}\n\n`);
}

export function writeSseHeartbeat(res: ServerResponse<IncomingMessage>): void {
    res.write(": heartbeat\n\n");
}

export function startHeartbeat(
    res: ServerResponse<IncomingMessage>,
): NodeJS.Timeout {
    return setInterval(() => {
        if (!res.writableEnded) {
            writeSseHeartbeat(res);
        }
    }, SSE_HEARTBEAT_MS);
}
