import { createAnthropicProvider } from "./anthropic.js";
import type { LLMProvider } from "./base.js";
import type { Config } from "../config.js";

export function createProvider(config: Config): LLMProvider {
    // Single provider for now; extend here for OpenAI/Ollama support
    return createAnthropicProvider(config);
}
