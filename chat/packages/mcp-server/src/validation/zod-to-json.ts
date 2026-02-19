import {type ZodObject, type ZodRawShape, type ZodTypeAny} from "zod";

/**
 * Convert a Zod object schema to a JSON Schema object suitable for MCP tool inputSchema.
 * Handles the subset of Zod types used in our tool input schemas.
 */
export function zodToJsonSchema(schema: ZodObject<ZodRawShape>): Record<string, unknown> {
    const shape = schema.shape;
    const properties: Record<string, unknown> = {};
    const required: string[] = [];

    for (const [key, value] of Object.entries(shape)) {
        const zodType = value as ZodTypeAny;
        const {jsonSchema, isOptional} = zodTypeToJsonSchema(zodType);
        properties[key] = jsonSchema;
        if (!isOptional) {
            required.push(key);
        }
    }

    return {
        type: "object",
        properties,
        ...(required.length > 0 ? {required} : {}),
    };
}

interface JsonSchemaResult {
    jsonSchema: Record<string, unknown>;
    isOptional: boolean;
}

function zodTypeToJsonSchema(zodType: ZodTypeAny): JsonSchemaResult {
    const def = zodType._def;
    const typeName = def.typeName as string;

    // Unwrap ZodOptional
    if (typeName === "ZodOptional") {
        const inner = zodTypeToJsonSchema(def.innerType);
        return {jsonSchema: inner.jsonSchema, isOptional: true};
    }

    // Unwrap ZodDefault
    if (typeName === "ZodDefault") {
        const inner = zodTypeToJsonSchema(def.innerType);
        return {
            jsonSchema: {...inner.jsonSchema, default: def.defaultValue()},
            isOptional: true,
        };
    }

    // ZodString
    if (typeName === "ZodString") {
        const schema: Record<string, unknown> = {type: "string"};
        for (const check of def.checks ?? []) {
            if (check.kind === "regex") {
                schema["pattern"] = check.regex.source;
            }
            if (check.kind === "min") {
                schema["minLength"] = check.value;
            }
            if (check.kind === "max") {
                schema["maxLength"] = check.value;
            }
        }
        return {jsonSchema: schema, isOptional: false};
    }

    // ZodNumber
    if (typeName === "ZodNumber") {
        const schema: Record<string, unknown> = {type: "number"};
        for (const check of def.checks ?? []) {
            if (check.kind === "int") {
                schema["type"] = "integer";
            }
            if (check.kind === "min") {
                schema["minimum"] = check.value;
            }
            if (check.kind === "max") {
                schema["maximum"] = check.value;
            }
        }
        return {jsonSchema: schema, isOptional: false};
    }

    // ZodEnum
    if (typeName === "ZodEnum") {
        return {
            jsonSchema: {type: "string", enum: def.values},
            isOptional: false,
        };
    }

    // ZodBoolean
    if (typeName === "ZodBoolean") {
        return {jsonSchema: {type: "boolean"}, isOptional: false};
    }

    // Fallback
    return {jsonSchema: {}, isOptional: false};
}
