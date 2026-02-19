import {executeQuery} from "../db/query-engine.js";
import {SummarizePeriodInput, type SummarizePeriodParams} from "../validation/schemas.js";

export const SUMMARIZE_PERIOD_DESCRIPTION = `Summarize activity metrics for a specific time period (week, month, or year).

Automatically compares to the previous equivalent period (e.g., this month vs last month).

Input format: period_type + period_value:
- year: "2025"
- month: "2025-01"
- week: "2025-W03" (ISO week)

Returns: activity_count, total_distance_miles, total_moving_time_hours, elevation, speed, pace, heart rate, and comparison deltas.`;

interface PeriodSummary {
    period: string;
    sport_type: string;
    summary: Record<string, unknown> | null;
    comparison_to_previous: Record<string, unknown> | null;
}

export async function summarizePeriod(rawInput: unknown): Promise<PeriodSummary> {
    const input: SummarizePeriodParams = SummarizePeriodInput.parse(rawInput);

    const sportType = input.sport_type ?? "all";

    if (input.period_type === "year") {
        return summarizeYear(input.period_value, sportType);
    } else if (input.period_type === "month") {
        return summarizeMonth(input.period_value, sportType);
    } else {
        return summarizeWeek(input.period_value, sportType);
    }
}

async function summarizeYear(
    yearStr: string,
    sportType: string,
): Promise<PeriodSummary> {
    const year = parseInt(yearStr, 10);
    const grain = sportType === "all" ? "year" : "sport_type_year";

    const conditions: string[] = ["grain = $1", "activity_year = $2"];
    const params: unknown[] = [grain, year];
    const prevParams: unknown[] = [grain, year - 1];

    if (sportType !== "all") {
        conditions.push("sport_type = $3");
        params.push(sportType);
        prevParams.push(sportType);
    }

    const sql = `
    SELECT activity_count, total_distance_miles, total_distance_km,
           total_moving_time_hours, total_elevation_gain_feet,
           avg_speed_mph, avg_pace_min_per_km, avg_heartrate_bpm,
           longest_distance_miles
    FROM reporting.rpt_kpis__all
    WHERE ${conditions.join(" AND ")}
  `;

    const current = await executeQuery(sql, params, {limit: 1});
    const previous = await executeQuery(sql, prevParams, {limit: 1});

    return buildPeriodSummary(yearStr, sportType, current.rows[0], previous.rows[0]);
}

async function summarizeMonth(
    monthStr: string,
    sportType: string,
): Promise<PeriodSummary> {
    // monthStr format: "2025-01"
    const monthStart = `${monthStr}-01`;
    const prevDate = new Date(monthStart);
    prevDate.setMonth(prevDate.getMonth() - 1);
    const prevMonthStart = prevDate.toISOString().slice(0, 10);

    const grain = sportType === "all" ? "year_month" : "sport_type_year_month";
    const conditions: string[] = ["grain = $1", "month_start = $2::DATE"];
    const params: unknown[] = [grain, monthStart];
    const prevParams: unknown[] = [grain, prevMonthStart];

    if (sportType !== "all") {
        conditions.push("sport_type = $3");
        params.push(sportType);
        prevParams.push(sportType);
    }

    const sql = `
    SELECT activity_count, total_distance_miles, total_distance_km,
           total_moving_time_hours, total_elevation_gain_feet,
           avg_speed_mph, avg_pace_min_per_km, avg_heartrate_bpm,
           longest_distance_miles
    FROM reporting.rpt_kpis__all
    WHERE ${conditions.join(" AND ")}
  `;

    const current = await executeQuery(sql, params, {limit: 1});
    const previous = await executeQuery(sql, prevParams, {limit: 1});

    return buildPeriodSummary(monthStr, sportType, current.rows[0], previous.rows[0]);
}

async function summarizeWeek(
    weekStr: string,
    sportType: string,
): Promise<PeriodSummary> {
    // weekStr format: "2025-W03" — compute date range from ISO week
    const match = weekStr.match(/^(\d{4})-W(\d{2})$/);
    if (!match) {
        throw new Error("Invalid week format. Use YYYY-Wnn (e.g., 2025-W03)");
    }
    const [, yearStr, weekStr2] = match;
    const year = parseInt(yearStr!, 10);
    const week = parseInt(weekStr2!, 10);

    // ISO week to date: Jan 4 is always in week 1
    const jan4 = new Date(year, 0, 4);
    const dayOfWeek = jan4.getDay() || 7; // Monday = 1
    const weekStart = new Date(jan4);
    weekStart.setDate(jan4.getDate() - dayOfWeek + 1 + (week - 1) * 7);
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 6);

    const prevWeekStart = new Date(weekStart);
    prevWeekStart.setDate(weekStart.getDate() - 7);
    const prevWeekEnd = new Date(weekEnd);
    prevWeekEnd.setDate(weekEnd.getDate() - 7);

    const grain = sportType === "all" ? "day" : "sport_type_day";
    const conditions: string[] = [
        "grain = $1",
        "activity_date >= $2::DATE",
        "activity_date <= $3::DATE",
    ];
    const params: unknown[] = [
        grain,
        weekStart.toISOString().slice(0, 10),
        weekEnd.toISOString().slice(0, 10),
    ];
    const prevParams: unknown[] = [
        grain,
        prevWeekStart.toISOString().slice(0, 10),
        prevWeekEnd.toISOString().slice(0, 10),
    ];

    if (sportType !== "all") {
        conditions.push("sport_type = $4");
        params.push(sportType);
        prevParams.push(sportType);
    }

    const sql = `
    SELECT
      SUM(activity_count) AS activity_count,
      ROUND(SUM(total_distance_miles), 1) AS total_distance_miles,
      ROUND(SUM(total_distance_km), 1) AS total_distance_km,
      ROUND(SUM(total_moving_time_hours), 1) AS total_moving_time_hours,
      ROUND(SUM(total_elevation_gain_feet), 0) AS total_elevation_gain_feet,
      ROUND(AVG(avg_speed_mph), 1) AS avg_speed_mph,
      ROUND(AVG(avg_pace_min_per_km), 2) AS avg_pace_min_per_km,
      ROUND(AVG(avg_heartrate_bpm), 0) AS avg_heartrate_bpm,
      MAX(longest_distance_miles) AS longest_distance_miles
    FROM reporting.rpt_kpis__all
    WHERE ${conditions.join(" AND ")}
  `;

    const current = await executeQuery(sql, params, {limit: 1});
    const previous = await executeQuery(sql, prevParams, {limit: 1});

    return buildPeriodSummary(weekStr, sportType, current.rows[0], previous.rows[0]);
}

function buildPeriodSummary(
    period: string,
    sportType: string,
    current: Record<string, unknown> | undefined,
    previous: Record<string, unknown> | undefined,
): PeriodSummary {
    if (!current || Number(current["activity_count"]) === 0) {
        return {period, sport_type: sportType, summary: null, comparison_to_previous: null};
    }

    let comparison: Record<string, unknown> | null = null;
    if (previous && Number(previous["activity_count"]) > 0) {
        const currCount = Number(current["activity_count"]);
        const prevCount = Number(previous["activity_count"]);
        const currDist = Number(current["total_distance_miles"]);
        const prevDist = Number(previous["total_distance_miles"]);
        const currTime = Number(current["total_moving_time_hours"]);
        const prevTime = Number(previous["total_moving_time_hours"]);

        comparison = {
            activity_count_delta: currCount - prevCount,
            distance_delta_pct: prevDist > 0 ? Math.round(((currDist - prevDist) / prevDist) * 100) : null,
            time_delta_pct: prevTime > 0 ? Math.round(((currTime - prevTime) / prevTime) * 100) : null,
        };
    }

    return {
        period,
        sport_type: sportType,
        summary: current,
        comparison_to_previous: comparison,
    };
}
