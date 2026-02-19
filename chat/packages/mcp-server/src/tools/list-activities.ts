import {executeCount, executeQuery} from "../db/query-engine.js";
import {ListActivitiesInput, type ListActivitiesParams} from "../validation/schemas.js";

export const LIST_ACTIVITIES_DESCRIPTION = `List Strava activities with filters, sorting, and pagination.

Filters: sport_type, year, date_from, date_to.
Sort by: date, distance, time, elevation (asc or desc).
Pagination: limit (default 20, max 100), offset.

Returns summary fields: activity_id, name, sport_type, date, distance, time, elevation, heart rate, PR count.
Also returns total_count and has_more for pagination.

Use this when the user asks to see recent activities, find activities by sport, or browse their activity history.`;

interface ListResult {
    activities: Record<string, unknown>[];
    total_count: number;
    has_more: boolean;
}

const SORT_COLUMN_MAP: Record<string, string> = {
    date: "activity_date",
    distance: "distance_miles",
    time: "moving_time_seconds",
    elevation: "elevation_gain_feet",
};

export async function listActivities(rawInput: unknown): Promise<ListResult> {
    const input: ListActivitiesParams = ListActivitiesInput.parse(rawInput);

    const conditions: string[] = [];
    const params: unknown[] = [];
    let paramIndex = 1;

    if (input.sport_type !== undefined) {
        conditions.push(`sport_type = $${paramIndex}`);
        params.push(input.sport_type);
        paramIndex++;
    }

    if (input.year !== undefined) {
        conditions.push(`activity_year = $${paramIndex}`);
        params.push(input.year);
        paramIndex++;
    }

    if (input.date_from !== undefined) {
        conditions.push(`activity_date >= $${paramIndex}::DATE`);
        params.push(input.date_from);
        paramIndex++;
    }

    if (input.date_to !== undefined) {
        conditions.push(`activity_date <= $${paramIndex}::DATE`);
        params.push(input.date_to);
        paramIndex++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";
    const sortColumn = SORT_COLUMN_MAP[input.sort_by] ?? "activity_date";
    const sortOrder = input.sort_order === "asc" ? "ASC" : "DESC";

    const baseSql = `
    SELECT
      activity_id, activity_name, sport_type, sport_slug,
      STRFTIME(activity_date, '%Y-%m-%d') AS activity_date,
      distance_miles, distance_km,
      moving_time_display, moving_time_seconds,
      elevation_gain_feet,
      average_heartrate_bpm, pr_count, activity_link
    FROM reporting.rpt_activity_detail__activity
    ${whereClause}
  `;

    const orderedSql = `${baseSql} ORDER BY ${sortColumn} ${sortOrder}`;

    const [result, totalCount] = await Promise.all([
        executeQuery(orderedSql, params, {
            limit: input.limit,
            offset: input.offset,
        }),
        executeCount(baseSql, params),
    ]);

    return {
        activities: result.rows,
        total_count: totalCount,
        has_more: input.offset + result.row_count < totalCount,
    };
}
