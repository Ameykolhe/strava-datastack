import {executeQuery, type QueryResult} from "../db/query-engine.js";
import {GetSegmentEffortsInput} from "../validation/schemas.js";

export const GET_SEGMENT_EFFORTS_DESCRIPTION = `Get segment effort performances for a specific activity.

Returns each segment attempted during the activity: segment_name, distance, time, speed, pace, grade, climb category, PR rank, KOM rank, heart rate.

Use this when the user asks about segments, PRs on specific segments, or climb categories within an activity.`;

interface SegmentEffortsResult {
    efforts: Record<string, unknown>[];
    effort_count: number;
}

export async function getSegmentEfforts(
    rawInput: unknown,
): Promise<SegmentEffortsResult> {
    const input = GetSegmentEffortsInput.parse(rawInput);

    const sql = `
    SELECT
      effort_id, segment_id, segment_name,
      distance_km, distance_miles,
      elapsed_time_seconds, time_display, elapsed_time_display,
      average_speed_kph, average_speed_mph,
      pace_min_per_km, pace_min_per_mile,
      average_grade, climb_category, climb_category_label,
      pr_rank, is_pr, kom_rank, has_kom_rank,
      average_heartrate_bpm, max_heartrate_bpm,
      start_index
    FROM reporting.rpt_activity_segment_efforts__activity
    WHERE activity_id = $1
    ORDER BY start_index
  `;

    const result: QueryResult = await executeQuery(sql, [input.activity_id], {limit: 200});

    return {
        efforts: result.rows,
        effort_count: result.row_count,
    };
}
