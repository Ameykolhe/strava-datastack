import type { StreamEvent } from '@strava-chat/shared/types';
import { API_BASE } from './client.js';

export interface StreamOptions {
    conversationId: string;
    content: string;
    model?: string;
    temperature?: number;
    signal?: AbortSignal;
}

/**
 * POST a message and stream back SSE events.
 * Yields typed StreamEvent objects.
 */
export async function* streamMessage(opts: StreamOptions): AsyncGenerator<StreamEvent> {
    const token = typeof localStorage !== 'undefined' ? localStorage.getItem('chat_token') : null;

    const response = await fetch(
        `${API_BASE}/api/chat/conversations/${opts.conversationId}/messages`,
        {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Accept: 'text/event-stream',
                ...(token ? { Authorization: `Bearer ${token}` } : {}),
            },
            body: JSON.stringify({
                content: opts.content,
                settings: {
                    model: opts.model,
                    temperature: opts.temperature,
                },
            }),
            signal: opts.signal,
        },
    );

    if (!response.ok) {
        const body = await response.json().catch(() => ({ message: response.statusText }));
        throw new Error(body.message ?? `HTTP ${response.status}`);
    }

    if (!response.body) throw new Error('No response body');

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    try {
        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split('\n');
            buffer = lines.pop() ?? '';

            let eventType = '';
            let dataLine = '';

            for (const line of lines) {
                if (line.startsWith('event: ')) {
                    eventType = line.slice(7).trim();
                } else if (line.startsWith('data: ')) {
                    dataLine = line.slice(6).trim();
                } else if (line === '') {
                    if (eventType && dataLine && dataLine !== '[DONE]') {
                        try {
                            const parsed = JSON.parse(dataLine) as StreamEvent;
                            yield parsed;
                        } catch {
                            // Skip malformed event
                        }
                    }
                    eventType = '';
                    dataLine = '';
                }
            }
        }
    } finally {
        reader.releaseLock();
    }
}
