import {afterAll, beforeAll} from "vitest";
import {Database} from "duckdb-async";
import {readFileSync} from "fs";
import {dirname, join} from "path";
import {fileURLToPath} from "url";
import {closeDatabase, setDatabase} from "../src/db/connection.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

beforeAll(async () => {
    const testDb = await Database.create(":memory:");
    const seedSql = readFileSync(join(__dirname, "fixtures", "seed.sql"), "utf-8");

    // Strip comment-only lines, then split into statements
    const stripped = seedSql
        .split("\n")
        .filter((line) => !line.trimStart().startsWith("--"))
        .join("\n");

    const statements = stripped
        .split(";")
        .map((s) => s.trim())
        .filter((s) => s.length > 0);

    for (const stmt of statements) {
        await testDb.run(stmt);
    }

    // Inject test DB into the connection module
    setDatabase(testDb);
});

afterAll(async () => {
    await closeDatabase();
});
