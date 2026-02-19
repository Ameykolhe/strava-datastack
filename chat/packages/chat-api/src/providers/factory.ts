import { createAnthropicProvider } from "./anthropic.js";
import { createOpenAICompatProvider } from "./openai-compat.js";
import type { LLMProvider } from "./base.js";
import type { Config } from "../config.js";

export function createProvider(config: Config): LLMProvider {
    switch (config.LLM_PROVIDER) {
        case "openai-compat":
            return createOpenAICompatProvider(config);
        case "anthropic":
        default:
            return createAnthropicProvider(config);
    }
}
