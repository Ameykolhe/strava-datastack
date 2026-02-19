import {executeQuerySingle} from "../db/query-engine.js";
import {GetActivityDetailInput} from "../validation/schemas.js";

export const GET_ACTIVITY_DETAIL_DESCRIPTION = `Get full details for a single Strava activity by ID.

Returns: activity name, sport type, date, distance (miles + km), moving/elapsed time, elevation, speed/pace, heart rate, power, calories, location, kudos, PRs, achievements, device, and more.

Excludes: map polyline data (too large) and stream availability flags (internal).

Use this tool when the user asks about a specific activity.`;

export async function getActivityDetail(
    rawInput: unknown,
): Promise<{ activity: Record<string, unknown> | null }> {
    const input = GetActivityDetailInput.parse(rawInput);

    const sql = `
    SELECT
      activity_id, activity_name, sport_type, sport_slug, workout_type,
      started_at_local, timezone, activity_date, activity_year,
      activity_month, activity_week, activity_day_of_week,
      location_city, location_state, location_country,
      distance_km, distance_miles,
      moving_time_seconds, elapsed_time_seconds,
      moving_time_display, elapsed_time_display,
      moving_time_minutes, elapsed_time_minutes,
      elevation_gain_meters, elevation_gain_feet,
      average_speed_kph, average_speed_mph,
      max_speed_kph, max_speed_mph,
      pace_min_per_km, pace_min_per_mile,
      has_heartrate, average_heartrate_bpm, max_heartrate_bpm,
      has_power_meter, average_watts, kilojoules, calories_burned,
      kudos_count, comment_count, achievement_count, pr_count,
      suffer_score, is_trainer, is_commute, is_manual,
      device_name, activity_link
    FROM reporting.rpt_activity_detail__activity
    WHERE activity_id = $1
  `;

    const row = await executeQuerySingle(sql, [input.activity_id]);
    return {activity: row};
}
