import {executeQuery} from "../db/query-engine.js";
import {GetActivityZonesInput, type GetActivityZonesParams} from "../validation/schemas.js";

export const GET_ACTIVITY_ZONES_DESCRIPTION = `Get heart rate, pace, or power zone distribution for a specific activity.

Zone types: "pace" (min/km zones), "power" (watt zones), "heartrate" (bpm zones).

Returns per zone: zone_name, min/max values, time_seconds, time_display, pct_in_zone.
Also returns which zone types are available for the activity.

Use this when the user asks about effort distribution, zone training, or time in zones.`;

interface ZonesResult {
    zones: Record<string, unknown>[];
    zone_types_available: string[];
}

export async function getActivityZones(rawInput: unknown): Promise<ZonesResult> {
    const input: GetActivityZonesParams = GetActivityZonesInput.parse(rawInput);

    // First, get available zone types for this activity
    const typesSql = `
    SELECT DISTINCT zone_type
    FROM reporting.rpt_activity_zones__activity_zone
    WHERE activity_id = $1
    ORDER BY zone_type
  `;
    const typesResult = await executeQuery(typesSql, [input.activity_id], {limit: 10});
    const zoneTypesAvailable = typesResult.rows.map((r) => String(r["zone_type"]));

    // Build zone data query
    const conditions: string[] = ["activity_id = $1"];
    const params: unknown[] = [input.activity_id];

    if (input.zone_type !== undefined) {
        conditions.push("zone_type = $2");
        params.push(input.zone_type);
    }

    const sql = `
    SELECT
      zone_type, zone_id, zone_name,
      zone_min_value, zone_max_value,
      time_seconds, time_display, time_minutes, pct_in_zone
    FROM reporting.rpt_activity_zones__activity_zone
    WHERE ${conditions.join(" AND ")}
    ORDER BY zone_type, zone_id
  `;

    const result = await executeQuery(sql, params, {limit: 100});

    return {
        zones: result.rows,
        zone_types_available: zoneTypesAvailable,
    };
}
