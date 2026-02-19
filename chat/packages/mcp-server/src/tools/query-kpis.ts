import {executeQuery, type QueryResult} from "../db/query-engine.js";
import {QueryKpisInput, type QueryKpisParams} from "../validation/schemas.js";

export const QUERY_KPIS_DESCRIPTION = `Query aggregated KPI metrics for Strava activities at various grains.

Grains: "all" (lifetime), "year", "day", "year_month", "sport_type", "sport_type_year", "sport_type_day", "sport_type_year_month".

Returns: activity_count, total_distance_miles/km, total_moving_time_hours, total_elevation_gain_feet, avg_speed_mph, avg_pace_min_per_km, avg_heartrate_bpm, longest_distance_miles, hardest_elevation_gain_feet.

Use grain "all" for lifetime totals. Use grain "year" or "year_month" for trends over time. Use grains with "sport_type" prefix to break down by sport.`;

export async function queryKpis(rawInput: unknown): Promise<QueryResult> {
    const input: QueryKpisParams = QueryKpisInput.parse(rawInput);

    const conditions: string[] = ["grain = $1"];
    const params: unknown[] = [input.grain];
    let paramIndex = 2;

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

    if (input.month_start !== undefined) {
        conditions.push(`month_start = $${paramIndex}::DATE`);
        params.push(input.month_start);
        paramIndex++;
    }

    const sql = `
    SELECT
      grain, sport_type, sport_slug, activity_year, activity_date,
      month_start, month_number, month_label, month_name,
      activity_count, total_distance_km, total_distance_miles,
      total_moving_time_hours, time_display, total_elevation_gain_feet,
      avg_speed_mph, avg_speed_kmh, avg_pace_min_per_km,
      avg_heartrate_bpm, longest_distance_miles, hardest_elevation_gain_feet
    FROM reporting.rpt_kpis__all
    WHERE ${conditions.join(" AND ")}
    ORDER BY activity_year, activity_date, month_start
  `;

    return executeQuery(sql, params, {
        limit: input.limit,
        offset: input.offset,
    });
}
