import {getDatabase} from "./connection.js";
import {DEFAULT_ROW_LIMIT, MAX_ROW_LIMIT, QUERY_TIMEOUT_MS,} from "@strava-chat/shared/constants";

export interface QueryResult {
    rows: Record<string, unknown>[];
    row_count: number;
    has_more: boolean;
}

export interface QueryOptions {
    limit?: number;
    offset?: number;
    timeout_ms?: number;
}

/**
 * Execute a parameterized read-only query against the reporting DuckDB.
 *
 * - All parameters are passed via DuckDB's parameterized query interface (no string interpolation).
 * - Row count is capped at MAX_ROW_LIMIT (500).
 * - Queries time out after QUERY_TIMEOUT_MS (30s) by default.
 */
export async function executeQuery(
    sql: string,
    params: unknown[] = [],
    options: QueryOptions = {},
): Promise<QueryResult> {
    const limit = Math.min(options.limit ?? DEFAULT_ROW_LIMIT, MAX_ROW_LIMIT);
    const offset = options.offset ?? 0;
    const timeoutMs = options.timeout_ms ?? QUERY_TIMEOUT_MS;

    const db = await getDatabase();
    const conn = await db.connect();

    // Fetch limit + 1 to detect if there are more rows
    const wrappedSql = `SELECT *
                        FROM (${sql}) AS __q LIMIT ${limit + 1}
                        OFFSET ${offset}`;

    const queryPromise = conn.all(wrappedSql, ...params) as Promise<Record<string, unknown>[]>;
    const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error("Query timed out")), timeoutMs),
    );

    const rows = await Promise.race([queryPromise, timeoutPromise]);

    const hasMore = rows.length > limit;
    if (hasMore) {
        rows.pop();
    }

    return {
        rows,
        row_count: rows.length,
        has_more: hasMore,
    };
}

/**
 * Execute a parameterized query expecting a single row (or null).
 */
export async function executeQuerySingle(
    sql: string,
    params: unknown[] = [],
): Promise<Record<string, unknown> | null> {
    const result = await executeQuery(sql, params, {limit: 1});
    return result.rows[0] ?? null;
}

/**
 * Execute a count query. Useful for total_count in paginated results.
 */
export async function executeCount(
    sql: string,
    params: unknown[] = [],
): Promise<number> {
    const db = await getDatabase();
    const conn = await db.connect();
    const countSql = `SELECT COUNT(*) AS cnt
                      FROM (${sql}) AS __q`;
    const rows = (await conn.all(countSql, ...params)) as Record<string, unknown>[];
    return Number(rows[0]?.["cnt"] ?? 0);
}
