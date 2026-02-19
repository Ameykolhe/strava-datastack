import { loadConfig } from "./config.js";
import { getDatabase, closeDatabase } from "./db/sqlite.js";
import { initMcpClient, closeMcpClient } from "./mcp/client.js";
import { createProvider } from "./providers/factory.js";
import { createServer } from "./server.js";

async function main(): Promise<void> {
    const config = loadConfig();

    // Initialize SQLite
    const db = getDatabase(config);

    // Initialize MCP client (spawns mcp-server subprocess)
    await initMcpClient(config);

    // Initialize LLM provider
    const provider = createProvider(config);

    // Create and start Fastify server
    const server = await createServer(config, db, provider);

    // Graceful shutdown
    const shutdown = async (signal: string) => {
        server.log.info(`Received ${signal}, shutting down…`);
        await server.close();
        await closeMcpClient();
        closeDatabase();
        process.exit(0);
    };

    process.on("SIGINT", () => void shutdown("SIGINT"));
    process.on("SIGTERM", () => void shutdown("SIGTERM"));

    await server.listen({ port: config.CHAT_API_PORT, host: "0.0.0.0" });
}

main().catch((error: unknown) => {
    console.error("Fatal error during startup:", error);
    process.exit(1);
});
