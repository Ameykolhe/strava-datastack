import {StdioServerTransport} from "@modelcontextprotocol/sdk/server/stdio.js";
import {createServer} from "./server.js";
import {closeDatabase} from "./db/connection.js";

async function main(): Promise<void> {
    const server = createServer();
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("Strava MCP Server running on stdio");

    // Graceful shutdown
    const shutdown = async () => {
        console.error("Shutting down MCP server...");
        await closeDatabase();
        process.exit(0);
    };

    process.on("SIGINT", shutdown);
    process.on("SIGTERM", shutdown);
}

main().catch((error: unknown) => {
    console.error("Fatal error:", error);
    process.exit(1);
});
