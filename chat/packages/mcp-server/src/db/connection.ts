import {Database} from "duckdb-async";

let db: Database | null = null;

export async function getDatabase(): Promise<Database> {
    if (db) return db;

    const dbPath = process.env["DUCKDB_REPORTING_PATH"];
    if (!dbPath) {
        throw new Error("DUCKDB_REPORTING_PATH environment variable is required");
    }

    db = await Database.create(dbPath, {access_mode: "READ_ONLY"});
    return db;
}

/**
 * Inject a database instance (used for testing with in-memory DuckDB).
 */
export function setDatabase(database: Database): void {
    db = database;
}

export async function closeDatabase(): Promise<void> {
    if (db) {
        await db.close();
        db = null;
    }
}
