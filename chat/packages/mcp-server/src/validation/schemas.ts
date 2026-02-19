import {z} from "zod";

// --- Shared field schemas ---

const dateString = z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, "Date must be in YYYY-MM-DD format");

const positiveInt = z.number().int().positive();

const paginationLimit = z.number().int().min(1).max(500).default(50);
const paginationOffset = z.number().int().min(0).default(0);

// --- Tool input schemas ---

export const QueryKpisInput = z.object({
    grain: z.enum([
        "all",
        "year",
        "day",
        "year_month",
        "sport_type",
        "sport_type_year",
        "sport_type_day",
        "sport_type_year_month",
    ]),
    sport_type: z.string().optional(),
    year: z.number().int().min(2000).max(2100).optional(),
    month_start: dateString.optional(),
    limit: paginationLimit,
    offset: paginationOffset,
});

export const GetActivityDetailInput = z.object({
    activity_id: positiveInt,
});

export const SummarizePeriodInput = z.object({
    period_type: z.enum(["week", "month", "year"]),
    period_value: z.string().min(4).max(8),
    sport_type: z.string().optional(),
});

export const GetStreaksInput = z.object({
    grain: z.enum(["all", "year", "sport_type", "sport_type_year"]),
    sport_type: z.string().optional(),
    year: z.number().int().min(2000).max(2100).optional(),
});

export const GetActivityZonesInput = z.object({
    activity_id: positiveInt,
    zone_type: z.enum(["pace", "power", "heartrate"]).optional(),
});

export const ListActivitiesInput = z.object({
    sport_type: z.string().optional(),
    year: z.number().int().min(2000).max(2100).optional(),
    date_from: dateString.optional(),
    date_to: dateString.optional(),
    sort_by: z.enum(["date", "distance", "time", "elevation"]).default("date"),
    sort_order: z.enum(["asc", "desc"]).default("desc"),
    limit: z.number().int().min(1).max(100).default(20),
    offset: paginationOffset,
});

export const GetSegmentEffortsInput = z.object({
    activity_id: positiveInt,
});

// Export inferred types
export type QueryKpisParams = z.infer<typeof QueryKpisInput>;
export type GetActivityDetailParams = z.infer<typeof GetActivityDetailInput>;
export type SummarizePeriodParams = z.infer<typeof SummarizePeriodInput>;
export type GetStreaksParams = z.infer<typeof GetStreaksInput>;
export type GetActivityZonesParams = z.infer<typeof GetActivityZonesInput>;
export type ListActivitiesParams = z.infer<typeof ListActivitiesInput>;
export type GetSegmentEffortsParams = z.infer<typeof GetSegmentEffortsInput>;
