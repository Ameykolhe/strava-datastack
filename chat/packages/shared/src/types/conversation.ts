import type {Message} from "./message.js";

export interface Conversation {
    id: string;
    title: string;
    created_at: string;
    updated_at: string;
    archived_at: string | null;
    messages: Message[];
}

export interface ConversationSummary {
    id: string;
    title: string;
    created_at: string;
    updated_at: string;
    message_count: number;
    last_message_preview: string | null;
}
