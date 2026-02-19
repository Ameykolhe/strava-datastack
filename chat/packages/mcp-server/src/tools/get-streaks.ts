import {executeQuery, type QueryResult} from "../db/query-engine.js";
import {GetStreaksInput, type GetStreaksParams} from "../validation/schemas.js";

export const GET_STREAKS_DESCRIPTION = `Get activity streak information — current streak, longest streak, active days.

Grains: "all" (lifetime), "year", "sport_type" (per sport lifetime), "sport_type_year".

Returns: current_streak (consecutive days), longest_streak, active_days_last_30, active_days_year, streak start/end dates.

Use this when the user asks about consistency, streaks, or active days.`;

export async function getStreaks(rawInput: unknown): Promise<QueryResult> {
    const input: GetStreaksParams = GetStreaksInput.parse(rawInput);

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

    const sql = `
    SELECT
      grain, sport_type, sport_slug, activity_year,
      max_activity_date, current_streak,
      current_streak_start_date, current_streak_end_date,
      longest_streak, active_days_last_30, active_days_year
    FROM reporting.rpt_streaks__all
    WHERE ${conditions.join(" AND ")}
    ORDER BY sport_type, activity_year
  `;

    return executeQuery(sql, params, {limit: 100});
}
