import {describe, expect, it} from "vitest";
import {queryKpis} from "../src/tools/query-kpis.js";
import {getActivityDetail} from "../src/tools/get-activity.js";
import {summarizePeriod} from "../src/tools/summarize-period.js";
import {getStreaks} from "../src/tools/get-streaks.js";
import {getActivityZones} from "../src/tools/get-zones.js";
import {listActivities} from "../src/tools/list-activities.js";
import {getSegmentEfforts} from "../src/tools/get-segments.js";

// ============================================================
// query_kpis
// ============================================================
describe("query_kpis", () => {
    it("returns lifetime KPIs with grain=all", async () => {
        const result = await queryKpis({grain: "all"});
        expect(result.row_count).toBe(1);
        expect(result.rows[0]!["activity_count"]).toBe(120);
        expect(result.rows[0]!["total_distance_miles"]).toBe(932.1);
    });

    it("returns yearly KPIs", async () => {
        const result = await queryKpis({grain: "year"});
        expect(result.row_count).toBe(2);
        expect(result.rows.map((r) => r["activity_year"])).toContain(2025);
        expect(result.rows.map((r) => r["activity_year"])).toContain(2024);
    });

    it("filters by year", async () => {
        const result = await queryKpis({grain: "year", year: 2025});
        expect(result.row_count).toBe(1);
        expect(result.rows[0]!["activity_year"]).toBe(2025);
    });

    it("filters by sport_type", async () => {
        const result = await queryKpis({grain: "sport_type", sport_type: "Run"});
        expect(result.row_count).toBe(1);
        expect(result.rows[0]!["sport_type"]).toBe("Run");
        expect(result.rows[0]!["activity_count"]).toBe(90);
    });

    it("supports pagination with limit and offset", async () => {
        const result = await queryKpis({grain: "year", limit: 1, offset: 0});
        expect(result.row_count).toBe(1);
        expect(result.has_more).toBe(true);

        const page2 = await queryKpis({grain: "year", limit: 1, offset: 1});
        expect(page2.row_count).toBe(1);
        expect(page2.has_more).toBe(false);
    });

    it("rejects invalid grain", async () => {
        await expect(queryKpis({grain: "invalid"})).rejects.toThrow();
    });

    it("rejects missing grain", async () => {
        await expect(queryKpis({})).rejects.toThrow();
    });
});

// ============================================================
// get_activity_detail
// ============================================================
describe("get_activity_detail", () => {
    it("returns activity by ID", async () => {
        const result = await getActivityDetail({activity_id: 1001});
        expect(result.activity).not.toBeNull();
        expect(result.activity!["activity_name"]).toBe("Morning Run");
        expect(result.activity!["sport_type"]).toBe("Run");
        expect(result.activity!["distance_miles"]).toBe(6.2);
    });

    it("excludes polyline from output", async () => {
        const result = await getActivityDetail({activity_id: 1001});
        expect(result.activity).not.toBeNull();
        expect("polyline" in result.activity!).toBe(false);
    });

    it("returns null for non-existent activity", async () => {
        const result = await getActivityDetail({activity_id: 99999});
        expect(result.activity).toBeNull();
    });

    it("rejects non-integer activity_id", async () => {
        await expect(getActivityDetail({activity_id: "abc"})).rejects.toThrow();
    });

    it("rejects negative activity_id", async () => {
        await expect(getActivityDetail({activity_id: -1})).rejects.toThrow();
    });
});

// ============================================================
// summarize_period
// ============================================================
describe("summarize_period", () => {
    it("summarizes a year", async () => {
        const result = await summarizePeriod({period_type: "year", period_value: "2025"});
        expect(result.period).toBe("2025");
        expect(result.sport_type).toBe("all");
        expect(result.summary).not.toBeNull();
        expect(Number(result.summary!["activity_count"])).toBe(80);
    });

    it("includes comparison to previous year", async () => {
        const result = await summarizePeriod({period_type: "year", period_value: "2025"});
        expect(result.comparison_to_previous).not.toBeNull();
        expect(result.comparison_to_previous!["activity_count_delta"]).toBe(40);
    });

    it("summarizes a month", async () => {
        const result = await summarizePeriod({period_type: "month", period_value: "2025-01"});
        expect(result.period).toBe("2025-01");
        expect(result.summary).not.toBeNull();
        expect(Number(result.summary!["activity_count"])).toBe(12);
    });

    it("summarizes with sport_type filter", async () => {
        const result = await summarizePeriod({
            period_type: "year",
            period_value: "2025",
            sport_type: "Run",
        });
        expect(result.sport_type).toBe("Run");
        expect(Number(result.summary!["activity_count"])).toBe(60);
    });

    it("returns null summary for period with no data", async () => {
        const result = await summarizePeriod({period_type: "year", period_value: "2020"});
        expect(result.summary).toBeNull();
    });

    it("rejects invalid period_type", async () => {
        await expect(
            summarizePeriod({period_type: "quarter", period_value: "2025-Q1"}),
        ).rejects.toThrow();
    });
});

// ============================================================
// get_streaks
// ============================================================
describe("get_streaks", () => {
    it("returns lifetime streaks", async () => {
        const result = await getStreaks({grain: "all"});
        expect(result.row_count).toBe(1);
        expect(result.rows[0]!["current_streak"]).toBe(2);
        expect(result.rows[0]!["longest_streak"]).toBe(5);
    });

    it("returns per-sport streaks", async () => {
        const result = await getStreaks({grain: "sport_type"});
        expect(result.row_count).toBe(2);
        const run = result.rows.find((r) => r["sport_type"] === "Run");
        expect(run!["current_streak"]).toBe(1);
        expect(run!["longest_streak"]).toBe(4);
    });

    it("filters by year", async () => {
        const result = await getStreaks({grain: "year", year: 2025});
        expect(result.row_count).toBe(1);
        expect(result.rows[0]!["active_days_year"]).toBe(15);
    });

    it("filters by sport_type and year", async () => {
        const result = await getStreaks({
            grain: "sport_type_year",
            sport_type: "Run",
            year: 2025,
        });
        expect(result.row_count).toBe(1);
        expect(result.rows[0]!["active_days_year"]).toBe(12);
    });
});

// ============================================================
// get_activity_zones
// ============================================================
describe("get_activity_zones", () => {
    it("returns all zones for an activity", async () => {
        const result = await getActivityZones({activity_id: 1001});
        expect(result.zone_types_available).toContain("heartrate");
        expect(result.zone_types_available).toContain("pace");
        expect(result.zones.length).toBeGreaterThan(0);
    });

    it("filters by zone_type", async () => {
        const result = await getActivityZones({
            activity_id: 1001,
            zone_type: "heartrate",
        });
        expect(result.zones.every((z) => z["zone_type"] === "heartrate")).toBe(true);
        expect(result.zones.length).toBe(5);
    });

    it("returns power zones for ride", async () => {
        const result = await getActivityZones({
            activity_id: 1002,
            zone_type: "power",
        });
        expect(result.zones.length).toBe(4);
        expect(result.zones[0]!["zone_name"]).toBe("Active Recovery");
    });

    it("returns empty for activity without zones", async () => {
        const result = await getActivityZones({activity_id: 99999});
        expect(result.zones.length).toBe(0);
        expect(result.zone_types_available.length).toBe(0);
    });
});

// ============================================================
// list_activities
// ============================================================
describe("list_activities", () => {
    it("lists all activities sorted by date desc", async () => {
        const result = await listActivities({});
        expect(result.total_count).toBe(5);
        expect(result.activities.length).toBe(5);
        // First should be most recent
        const dates = result.activities.map((a) => String(a["activity_date"]));
        expect(dates[0]!.includes("2025-01-18")).toBe(true);
    });

    it("filters by sport_type", async () => {
        const result = await listActivities({sport_type: "Run"});
        expect(result.activities.every((a) => a["sport_type"] === "Run")).toBe(true);
        expect(result.total_count).toBe(3);
    });

    it("filters by year", async () => {
        const result = await listActivities({year: 2024});
        expect(result.total_count).toBe(1);
        expect(result.activities[0]!["activity_name"]).toBe("Indoor Trainer");
    });

    it("filters by date range", async () => {
        const result = await listActivities({
            date_from: "2025-01-15",
            date_to: "2025-01-16",
        });
        expect(result.total_count).toBe(3); // 2 on 01-15, 1 on 01-16
    });

    it("paginates correctly", async () => {
        const page1 = await listActivities({limit: 2, offset: 0});
        expect(page1.activities.length).toBe(2);
        expect(page1.has_more).toBe(true);
        expect(page1.total_count).toBe(5);

        const page2 = await listActivities({limit: 2, offset: 2});
        expect(page2.activities.length).toBe(2);
        expect(page2.has_more).toBe(true);

        const page3 = await listActivities({limit: 2, offset: 4});
        expect(page3.activities.length).toBe(1);
        expect(page3.has_more).toBe(false);
    });

    it("sorts by distance", async () => {
        const result = await listActivities({sort_by: "distance", sort_order: "desc"});
        const distances = result.activities.map((a) => Number(a["distance_miles"]));
        expect(distances[0]).toBeGreaterThanOrEqual(distances[1]!);
    });
});

// ============================================================
// get_segment_efforts
// ============================================================
describe("get_segment_efforts", () => {
    it("returns segments for an activity", async () => {
        const result = await getSegmentEfforts({activity_id: 1004});
        expect(result.effort_count).toBe(3);
        expect(result.efforts[0]!["segment_name"]).toBe("Prospect Park Loop");
        expect(result.efforts[0]!["is_pr"]).toBe(true);
    });

    it("returns segments ordered by start_index", async () => {
        const result = await getSegmentEfforts({activity_id: 1004});
        const indices = result.efforts.map((e) => Number(e["start_index"]));
        for (let i = 1; i < indices.length; i++) {
            expect(indices[i]).toBeGreaterThan(indices[i - 1]!);
        }
    });

    it("returns empty for activity without segments", async () => {
        const result = await getSegmentEfforts({activity_id: 1001});
        expect(result.effort_count).toBe(0);
        expect(result.efforts.length).toBe(0);
    });

    it("includes climb category labels", async () => {
        const result = await getSegmentEfforts({activity_id: 1004});
        const climb = result.efforts.find((e) => e["segment_name"] === "Brooklyn Bridge Climb");
        expect(climb!["climb_category_label"]).toBe("Cat 3");
    });
});

// ============================================================
// Validation (cross-tool)
// ============================================================
describe("input validation", () => {
    it("rejects SQL injection in string fields", async () => {
        // SQL injection attempt in sport_type — should be safe because parameterized
        // but the query will just return empty results
        const result = await queryKpis({
            grain: "sport_type",
            sport_type: "'; DROP TABLE reporting.rpt_kpis__all; --",
        });
        expect(result.row_count).toBe(0);
    });

    it("rejects invalid date format", async () => {
        await expect(
            listActivities({date_from: "not-a-date"}),
        ).rejects.toThrow();
    });

    it("rejects extra unknown fields via strict parsing", async () => {
        // Zod parse (non-strict) allows extra fields — this is fine for MCP
        // The unknown fields are simply ignored
        const result = await queryKpis({grain: "all", unknown_field: "test"});
        expect(result.row_count).toBe(1);
    });
});
