import { z } from "zod";

const ConfigSchema = z
    .object({
        ANTHROPIC_API_KEY: z.string().optional(),
        CHAT_JWT_SECRET: z
            .string()
            .min(16, "CHAT_JWT_SECRET must be at least 16 characters"),
        CHAT_PASSWORD_HASH: z.string().min(1, "CHAT_PASSWORD_HASH is required"),
        DUCKDB_REPORTING_PATH: z
            .string()
            .min(1, "DUCKDB_REPORTING_PATH is required"),
        CHAT_DB_PATH: z.string().default("/data/chat.sqlite"),
        CHAT_API_PORT: z.coerce.number().int().positive().default(3001),
        LOG_LEVEL: z
            .enum(["trace", "debug", "info", "warn", "error", "fatal"])
            .default("info"),
        CHAT_UI_ORIGIN: z.string().default("http://localhost:3002"),
        MCP_SERVER_PATH: z.string().optional(),
        NODE_ENV: z.string().default("production"),
        LLM_PROVIDER: z.enum(["anthropic", "openai-compat"]).default("anthropic"),
        OPENAI_API_BASE_URL: z.string().optional(),
        OPENAI_API_KEY: z.string().optional(),
        OPENAI_MODEL: z.string().optional(),
    })
    .superRefine((data, ctx) => {
        if (data.LLM_PROVIDER === "anthropic" && !data.ANTHROPIC_API_KEY) {
            ctx.addIssue({
                code: z.ZodIssueCode.custom,
                path: ["ANTHROPIC_API_KEY"],
                message: "ANTHROPIC_API_KEY is required when LLM_PROVIDER=anthropic",
            });
        }
        if (data.LLM_PROVIDER === "openai-compat") {
            if (!data.OPENAI_API_BASE_URL) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    path: ["OPENAI_API_BASE_URL"],
                    message:
                        "OPENAI_API_BASE_URL is required when LLM_PROVIDER=openai-compat",
                });
            }
            if (!data.OPENAI_API_KEY) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    path: ["OPENAI_API_KEY"],
                    message:
                        "OPENAI_API_KEY is required when LLM_PROVIDER=openai-compat",
                });
            }
            if (!data.OPENAI_MODEL) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    path: ["OPENAI_MODEL"],
                    message:
                        "OPENAI_MODEL is required when LLM_PROVIDER=openai-compat",
                });
            }
        }
    });

export type Config = z.infer<typeof ConfigSchema>;

export function loadConfig(): Config {
    const result = ConfigSchema.safeParse(process.env);
    if (!result.success) {
        console.error("Configuration errors:");
        for (const issue of result.error.issues) {
            console.error(`  ${issue.path.join(".")}: ${issue.message}`);
        }
        process.exit(1);
    }
    return result.data;
}
