import type { ConversationSummary, Conversation } from '@strava-chat/shared/types';
import { apiGet, apiPost, apiPatch, apiDelete } from '$lib/api/client.js';

interface ListResponse {
    conversations: ConversationSummary[];
    total: number;
    has_more: boolean;
}

interface CreateResponse {
    id: string;
    title: string;
    created_at: string;
    message_count: number;
}

class ConversationsStore {
    list = $state<ConversationSummary[]>([]);
    loading = $state(false);
    error = $state<string | null>(null);

    async load(): Promise<void> {
        this.loading = true;
        this.error = null;
        try {
            const data = await apiGet<ListResponse>('/api/chat/conversations?limit=50&offset=0');
            this.list = data.conversations;
        } catch (err) {
            this.error = err instanceof Error ? err.message : 'Failed to load conversations';
        } finally {
            this.loading = false;
        }
    }

    async create(title?: string): Promise<string> {
        const data = await apiPost<CreateResponse>('/api/chat/conversations', title ? { title } : {});
        // Reload list after create
        await this.load();
        return data.id;
    }

    async rename(id: string, title: string): Promise<void> {
        await apiPatch(`/api/chat/conversations/${id}`, { title });
        const idx = this.list.findIndex((c) => c.id === id);
        if (idx !== -1) {
            this.list[idx] = { ...this.list[idx], title };
        }
    }

    async remove(id: string): Promise<void> {
        await apiDelete(`/api/chat/conversations/${id}`);
        this.list = this.list.filter((c) => c.id !== id);
    }

    async getConversation(id: string): Promise<Conversation> {
        return apiGet<Conversation>(`/api/chat/conversations/${id}`);
    }
}

export const conversationsStore = new ConversationsStore();
