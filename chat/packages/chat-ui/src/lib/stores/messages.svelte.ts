import type { Message, ToolCallReference } from '@strava-chat/shared/types';
import { streamMessage } from '$lib/api/stream.js';
import { conversationsStore } from './conversations.svelte.js';

export interface ActiveToolCall {
    id: string;
    toolName: string;
    input: Record<string, unknown>;
    output?: Record<string, unknown>;
    durationMs?: number;
    status: 'pending' | 'done' | 'error';
}

export interface StreamingMessage {
    id: string;
    role: 'assistant';
    partialText: string;
    toolCalls: ActiveToolCall[];
    model: string;
}

class MessagesStore {
    messages = $state<Message[]>([]);
    streaming = $state<StreamingMessage | null>(null);
    isStreaming = $state(false);
    error = $state<string | null>(null);
    conversationId = $state<string | null>(null);

    private abortController: AbortController | null = null;

    loadMessages(messages: Message[], convId: string): void {
        this.messages = messages;
        this.conversationId = convId;
        this.streaming = null;
        this.error = null;
    }

    async send(content: string, model?: string, temperature?: number): Promise<void> {
        if (!this.conversationId) throw new Error('No active conversation');

        // Optimistically add user message
        const userMsg: Message = {
            id: `local_${Date.now()}`,
            conversation_id: this.conversationId,
            role: 'user',
            content,
            tool_calls: [],
            model: null,
            tokens_used: null,
            created_at: new Date().toISOString(),
        };
        this.messages = [...this.messages, userMsg];
        this.error = null;
        this.isStreaming = true;

        this.abortController = new AbortController();

        this.streaming = {
            id: '',
            role: 'assistant',
            partialText: '',
            toolCalls: [],
            model: model ?? 'claude-sonnet-4-6',
        };

        try {
            const gen = streamMessage({
                conversationId: this.conversationId,
                content,
                model,
                temperature,
                signal: this.abortController.signal,
            });

            for await (const event of gen) {
                switch (event.type) {
                    case 'message_start':
                        this.streaming = {
                            id: event.id,
                            role: 'assistant',
                            partialText: '',
                            toolCalls: [],
                            model: event.model,
                        };
                        break;

                    case 'content_delta':
                        if (this.streaming) {
                            this.streaming = {
                                ...this.streaming,
                                partialText: this.streaming.partialText + event.text,
                            };
                        }
                        break;

                    case 'tool_use_start':
                        if (this.streaming) {
                            const newTool: ActiveToolCall = {
                                id: event.id,
                                toolName: event.tool_name,
                                input: event.input,
                                status: 'pending',
                            };
                            this.streaming = {
                                ...this.streaming,
                                toolCalls: [...this.streaming.toolCalls, newTool],
                            };
                        }
                        break;

                    case 'tool_result':
                        if (this.streaming) {
                            const updatedTools: ActiveToolCall[] = this.streaming.toolCalls.map((t) =>
                                t.id === event.id
                                    ? {
                                          ...t,
                                          output: event.output,
                                          durationMs: event.duration_ms,
                                          status: 'done' as const,
                                      }
                                    : t,
                            );
                            this.streaming = { ...this.streaming, toolCalls: updatedTools };
                        }
                        break;

                    case 'message_end': {
                        // Convert streaming state to a real message
                        if (this.streaming) {
                            const toolRefs: ToolCallReference[] = this.streaming.toolCalls.map(
                                (t) => ({
                                    id: t.id,
                                    tool_name: t.toolName,
                                    input: t.input,
                                    output: t.output ?? null,
                                    duration_ms: t.durationMs ?? null,
                                }),
                            );
                            const finalMsg: Message = {
                                id: event.id,
                                conversation_id: this.conversationId!,
                                role: 'assistant',
                                content: this.streaming.partialText,
                                tool_calls: toolRefs,
                                model: this.streaming.model,
                                tokens_used: event.tokens_used,
                                created_at: new Date().toISOString(),
                            };
                            // Replace optimistic user message with server version and add assistant message
                            this.messages = [
                                ...this.messages.filter((m) => m.id !== userMsg.id),
                                finalMsg,
                            ];
                            // Reload to get the persisted user message from the server
                            const conv = await conversationsStore.getConversation(
                                this.conversationId!,
                            );
                            this.messages = conv.messages;
                            await conversationsStore.load();
                        }
                        this.streaming = null;
                        break;
                    }

                    case 'error':
                        this.error = event.message;
                        this.streaming = null;
                        break;
                }
            }
        } catch (err) {
            if ((err as Error).name === 'AbortError') {
                // User stopped — keep partial content
                if (this.streaming?.partialText) {
                    const partialMsg: Message = {
                        id: `partial_${Date.now()}`,
                        conversation_id: this.conversationId!,
                        role: 'assistant',
                        content: this.streaming.partialText + '\n\n*(stopped)*',
                        tool_calls: [],
                        model: this.streaming.model,
                        tokens_used: null,
                        created_at: new Date().toISOString(),
                    };
                    this.messages = [...this.messages, partialMsg];
                }
            } else {
                this.error = err instanceof Error ? err.message : 'Stream failed';
                // Remove optimistic user message on error
                this.messages = this.messages.filter((m) => m.id !== userMsg.id);
            }
            this.streaming = null;
        } finally {
            this.isStreaming = false;
            this.abortController = null;
        }
    }

    stop(): void {
        this.abortController?.abort();
    }

    clearError(): void {
        this.error = null;
    }
}

export const messagesStore = new MessagesStore();
