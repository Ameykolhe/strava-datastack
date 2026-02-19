import Database from "better-sqlite3";
import type { Config } from "../config.js";

const MIGRATION_SQL = `
CREATE TABLE IF NOT EXISTS conversations (
    id          TEXT PRIMARY KEY,
    title       TEXT NOT NULL,
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL,
    archived_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_conversations_updated_at
    ON conversations (updated_at);

CREATE TABLE IF NOT EXISTS messages (
    id              TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL REFERENCES conversations (id),
    role            TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content         TEXT NOT NULL,
    tool_calls      TEXT NOT NULL DEFAULT '[]',
    model           TEXT,
    tokens_used     TEXT,
    created_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id
    ON messages (conversation_id);
`;

let db: Database.Database | null = null;

export function getDatabase(config?: Config): Database.Database {
    if (db) return db;
    if (!config) throw new Error("Config required to initialize database");

    db = new Database(config.CHAT_DB_PATH);
    db.pragma("journal_mode = WAL");
    db.pragma("foreign_keys = ON");
    db.exec(MIGRATION_SQL);
    return db;
}

export function closeDatabase(): void {
    db?.close();
    db = null;
}
