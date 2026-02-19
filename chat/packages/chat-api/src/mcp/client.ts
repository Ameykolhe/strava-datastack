import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { fileURLToPath } from "url";
import path from "path";
import type { ToolDefinition } from "@strava-chat/shared/types";
import type { Config } from "../config.js";

let mcpClient: Client | null = null;
let discoveredTools: ToolDefinition[] = [];
let isConnected = false;

export async function initMcpClient(config: Config): Promise<void> {
    const serverPath = resolveMcpServerPath(config);

    const transport = new StdioClientTransport({
        command: "node",
        args: [serverPath],
        env: {
            ...Object.fromEntries(
                Object.entries(process.env).filter(
                    ([, v]) => v !== undefined,
                ) as [string, string][],
            ),
            DUCKDB_REPORTING_PATH: config.DUCKDB_REPORTING_PATH,
        },
    });

    mcpClient = new Client(
        { name: "strava-chat-api", version: "0.1.0" },
        { capabilities: {} },
    );

    await mcpClient.connect(transport);
    isConnected = true;

    // Discover available tools
    const { tools } = await mcpClient.listTools();
    discoveredTools = tools.map((t) => ({
        name: t.name,
        description: t.description ?? "",
        input_schema: t.inputSchema as Record<string, unknown>,
    }));
}

function resolveMcpServerPath(config: Config): string {
    if (config.MCP_SERVER_PATH) return config.MCP_SERVER_PATH;

    // In Docker: /app/packages/mcp-server/dist/index.js
    // In dev: relative to this file's location at packages/chat-api/dist/mcp/client.js
    const __dirname = path.dirname(fileURLToPath(import.meta.url));

    // Try Docker path first
    const dockerPath = "/app/packages/mcp-server/dist/index.js";

    // Dev path: go up from dist/mcp/ to packages/, then sibling mcp-server
    const devPath = path.resolve(__dirname, "../../../mcp-server/dist/index.js");

    // Prefer the explicit config path; otherwise use detected path
    return process.env["NODE_ENV"] === "production" ? dockerPath : devPath;
}

export function getTools(): ToolDefinition[] {
    return discoveredTools;
}

export function isMcpConnected(): boolean {
    return isConnected;
}

export async function callMcpTool(
    name: string,
    args: Record<string, unknown>,
): Promise<{ content: Record<string, unknown>; isError: boolean }> {
    if (!mcpClient || !isConnected) {
        throw new Error("MCP client is not connected");
    }

    const result = await mcpClient.callTool({ name, arguments: args });

    const rawContent = result.content as Array<{ type: string; text?: string }>;
    const textBlock = rawContent.find((c) => c.type === "text");

    let content: Record<string, unknown> = {};
    if (textBlock?.text) {
        try {
            content = JSON.parse(textBlock.text) as Record<string, unknown>;
        } catch {
            content = { raw: textBlock.text };
        }
    }

    return { content, isError: result.isError === true };
}

export async function closeMcpClient(): Promise<void> {
    if (mcpClient) {
        await mcpClient.close();
        mcpClient = null;
        isConnected = false;
        discoveredTools = [];
    }
}
