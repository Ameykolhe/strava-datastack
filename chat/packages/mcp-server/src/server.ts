import {Server} from "@modelcontextprotocol/sdk/server/index.js";
import {
    CallToolRequestSchema,
    ListResourcesRequestSchema,
    ListToolsRequestSchema,
    ReadResourceRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import {zodToJsonSchema} from "./validation/zod-to-json.js";
import {
    GetActivityDetailInput,
    GetActivityZonesInput,
    GetSegmentEffortsInput,
    GetStreaksInput,
    ListActivitiesInput,
    QueryKpisInput,
    SummarizePeriodInput,
} from "./validation/schemas.js";
import {
    GET_ACTIVITY_DETAIL_DESCRIPTION,
    GET_ACTIVITY_ZONES_DESCRIPTION,
    GET_SEGMENT_EFFORTS_DESCRIPTION,
    GET_STREAKS_DESCRIPTION,
    getActivityDetail,
    getActivityZones,
    getSegmentEfforts,
    getStreaks,
    LIST_ACTIVITIES_DESCRIPTION,
    listActivities,
    QUERY_KPIS_DESCRIPTION,
    queryKpis,
    SUMMARIZE_PERIOD_DESCRIPTION,
    summarizePeriod,
} from "./tools/index.js";
import {getSchemaResource, SCHEMA_RESOURCE_DESCRIPTION} from "./resources/schema.js";
import {getSportsResource, SPORTS_RESOURCE_DESCRIPTION} from "./resources/sports.js";

// Tool handler registry
const toolHandlers: Record<string, (input: unknown) => Promise<unknown>> = {
    query_kpis: queryKpis,
    get_activity_detail: getActivityDetail,
    summarize_period: summarizePeriod,
    get_streaks: getStreaks,
    get_activity_zones: getActivityZones,
    list_activities: listActivities,
    get_segment_efforts: getSegmentEfforts,
};

export function createServer(): Server {
    const server = new Server(
        {name: "strava-mcp-server", version: "0.1.0"},
        {capabilities: {tools: {}, resources: {}}},
    );

    // --- List Tools ---
    server.setRequestHandler(ListToolsRequestSchema, async () => {
        return {
            tools: [
                {
                    name: "query_kpis",
                    description: QUERY_KPIS_DESCRIPTION,
                    inputSchema: zodToJsonSchema(QueryKpisInput),
                },
                {
                    name: "get_activity_detail",
                    description: GET_ACTIVITY_DETAIL_DESCRIPTION,
                    inputSchema: zodToJsonSchema(GetActivityDetailInput),
                },
                {
                    name: "summarize_period",
                    description: SUMMARIZE_PERIOD_DESCRIPTION,
                    inputSchema: zodToJsonSchema(SummarizePeriodInput),
                },
                {
                    name: "get_streaks",
                    description: GET_STREAKS_DESCRIPTION,
                    inputSchema: zodToJsonSchema(GetStreaksInput),
                },
                {
                    name: "get_activity_zones",
                    description: GET_ACTIVITY_ZONES_DESCRIPTION,
                    inputSchema: zodToJsonSchema(GetActivityZonesInput),
                },
                {
                    name: "list_activities",
                    description: LIST_ACTIVITIES_DESCRIPTION,
                    inputSchema: zodToJsonSchema(ListActivitiesInput),
                },
                {
                    name: "get_segment_efforts",
                    description: GET_SEGMENT_EFFORTS_DESCRIPTION,
                    inputSchema: zodToJsonSchema(GetSegmentEffortsInput),
                },
            ],
        };
    });

    // --- Call Tool ---
    server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const {name, arguments: args} = request.params;
        const handler = toolHandlers[name];

        if (!handler) {
            return {
                content: [{type: "text", text: JSON.stringify({error: `Unknown tool: ${name}`})}],
                isError: true,
            };
        }

        try {
            const result = await handler(args);
            return {
                content: [{type: "text", text: JSON.stringify(result)}],
            };
        } catch (error: unknown) {
            const message =
                error instanceof Error ? error.message : "Unknown error";
            // Zod validation errors have a .issues property
            const issues =
                error !== null &&
                typeof error === "object" &&
                "issues" in error
                    ? (error as { issues: unknown }).issues
                    : undefined;

            return {
                content: [
                    {
                        type: "text",
                        text: JSON.stringify({
                            error: "tool_execution_error",
                            message,
                            ...(issues ? {validation_errors: issues} : {}),
                        }),
                    },
                ],
                isError: true,
            };
        }
    });

    // --- List Resources ---
    server.setRequestHandler(ListResourcesRequestSchema, async () => {
        return {
            resources: [
                {
                    uri: "strava://schema/reporting",
                    name: "Reporting Database Schema",
                    description: SCHEMA_RESOURCE_DESCRIPTION,
                    mimeType: "application/json",
                },
                {
                    uri: "strava://sports",
                    name: "Available Sport Types",
                    description: SPORTS_RESOURCE_DESCRIPTION,
                    mimeType: "application/json",
                },
            ],
        };
    });

    // --- Read Resource ---
    server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
        const {uri} = request.params;

        if (uri === "strava://schema/reporting") {
            const content = await getSchemaResource();
            return {contents: [{uri, mimeType: "application/json", text: content}]};
        }

        if (uri === "strava://sports") {
            const content = await getSportsResource();
            return {contents: [{uri, mimeType: "application/json", text: content}]};
        }

        throw new Error(`Unknown resource: ${uri}`);
    });

    return server;
}
