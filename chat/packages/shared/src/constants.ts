/** Maximum characters allowed in a single user message */
export const MAX_MESSAGE_LENGTH = 4000;

/** Maximum tool call rounds per message (prevents infinite loops) */
export const MAX_TOOL_ROUNDS = 5;

/** Default row limit for paginated tool results */
export const DEFAULT_ROW_LIMIT = 50;

/** Maximum row limit for paginated tool results */
export const MAX_ROW_LIMIT = 500;

/** Maximum result payload size in bytes (50KB) */
export const MAX_RESULT_BYTES = 50 * 1024;

/** DuckDB query timeout in milliseconds */
export const QUERY_TIMEOUT_MS = 30_000;

/** SSE heartbeat interval in milliseconds */
export const SSE_HEARTBEAT_MS = 15_000;

/** Maximum SSE stream duration in milliseconds (5 minutes) */
export const MAX_STREAM_DURATION_MS = 5 * 60 * 1000;

/** JWT token expiry in seconds (24 hours) */
export const JWT_EXPIRY_SECONDS = 24 * 60 * 60;

/** Rate limits */
export const RATE_LIMITS = {
    messages_per_minute: 30,
    messages_per_day: 500,
    tool_calls_per_minute: 60,
    login_attempts_per_minute: 5,
} as const;

/** Default model */
export const DEFAULT_MODEL = "claude-sonnet-4-6";

/** Default temperature */
export const DEFAULT_TEMPERATURE = 0.7;

/** Chat API default port */
export const CHAT_API_PORT = 3001;

/** Chat UI default port */
export const CHAT_UI_PORT = 3002;
