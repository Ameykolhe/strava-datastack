import {getDatabase} from "../db/connection.js";

export const SCHEMA_RESOURCE_DESCRIPTION =
    "Database schema metadata for the Strava reporting tables (table names, column names, column types).";

export async function getSchemaResource(): Promise<string> {
    const db = await getDatabase();
    const conn = await db.connect();

    const tables = (await conn.all(`SELECT table_name
                                    FROM information_schema.tables
                                    WHERE table_schema = 'reporting'
                                    ORDER BY table_name
    `)) as Record<string, unknown>[];

    const schema: Record<string, { column_name: string; data_type: string }[]> = {};

    for (const table of tables) {
        const tableName = String(table["table_name"]);
        const columns = (await conn.all(
            `
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_schema = 'reporting'
                  AND table_name = $1
                ORDER BY ordinal_position
            `,
            tableName,
        )) as Record<string, unknown>[];

        schema[tableName] = columns.map((col) => ({
            column_name: String(col["column_name"]),
            data_type: String(col["data_type"]),
        }));
    }

    return JSON.stringify(schema, null, 2);
}
