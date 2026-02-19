import {executeQuery} from "../db/query-engine.js";

export const SPORTS_RESOURCE_DESCRIPTION =
    "List of distinct sport types available in the Strava data (e.g., Run, Ride, Swim).";

export async function getSportsResource(): Promise<string> {
    const result = await executeQuery(
        `SELECT DISTINCT sport_type FROM reporting.rpt_activity_detail__activity ORDER BY sport_type`,
        [],
        {limit: 100},
    );

    const sports = result.rows.map((r) => String(r["sport_type"]));
    return JSON.stringify(sports);
}
