import type {Conversation, ConversationSummary} from "./conversation.js";

export interface LoginRequest {
    password: string;
}

export interface LoginResponse {
    token: string;
    expires_at: string;
}

export interface CreateConversationRequest {
    title?: string;
}

export interface UpdateConversationRequest {
    title: string;
}

export interface SendMessageRequest {
    content: string;
    settings?: {
        model?: string;
        temperature?: number;
    };
}

export interface ListConversationsResponse {
    conversations: ConversationSummary[];
    total: number;
    has_more: boolean;
}

export type GetConversationResponse = Conversation;

export interface ErrorResponse {
    error: string;
    message: string;
}

export interface HealthResponse {
    status: "healthy" | "degraded" | "unhealthy";
    version: string;
    checks: Record<string, "ok" | "error">;
}
