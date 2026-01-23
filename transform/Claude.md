You are Claude Code acting as a senior analytics engineer.

Mission
- Rebuild the dbt modeling stack for Strava analytics from scratch — but ONLY AFTER you’ve read and understood the raw data schema.
- Raw source path: airflow/data/strava_datastack.duckdb
- Raw source schema: strava_raw
- Raw tables (expected): activities, activity_segment_efforts, activity_streams, activity_zones

Critical rule
✅ Do NOT create or write any staging/intermediate/mart models until you have inspected the raw tables and confirmed:
- Exact table names
- Column names + types
- Nested/JSON structures (if any)
- Primary keys / natural keys availability
- Presence of ingestion timestamp / updated_at fields

Phase 1 — Raw data inspection (no model creation yet)
1) Inspect the warehouse and adapter (DuckDB likely). Confirm how to introspect schema.
2) For each raw table in strava_raw:
  - Print `describe` output (columns, types)
  - Identify candidate primary keys / unique identifiers
  - Identify nested columns (JSON/struct/list) and what needs flattening
  - Identify timestamps: start_date, start_date_local, updated_at, created_at, ingestion_ts, etc.
  - Identify duplicates (if possible): count(*) vs count(distinct PK)
3) Summarize the raw data contract:
  - Proposed grains:
    - activities: one row per activity_id
    - segment efforts: one row per segment_effort_id (or effort_id)
    - streams: determine if it’s one row per activity_id per stream_type, and whether values are stored as arrays/lists
    - zones: determine if it’s one row per activity_id per zone_type (with nested distribution)
  - Identify relationships:
    - segment_efforts.activity_id → activities.activity_id
    - streams.activity_id → activities.activity_id
    - zones.activity_id → activities.activity_id
4) Output a “Modeling Plan” that is based ONLY on what you found in the raw schema:
  - What fields will land in staging (renames/typecasts)
  - What needs intermediate reshaping (unnesting lists, flattening JSON)
  - Which dims/facts are feasible given available columns

Stop gate
- After Phase 1, output the plan + proposed model list (file paths + names), but still do NOT write the models yet unless you can confirm all required keys and fields exist.

Phase 2 — Delete existing Strava implementation
- After Phase 1 is complete:
  - Delete current Strava dbt models (staging/intermediate/marts/reporting) from the repo.
  - Keep unrelated models/macros.
  - Preserve repo-wide conventions in dbt_project.yml (schemas/tags/materializations), but you may update them if they’re Strava-only.

Phase 3 — Create models from scratch (dbt best practices)
Use repo conventions if they exist; otherwise default to:
- models/staging/strava_raw/stg_strava__*.sql
- models/intermediate/strava/int_strava__*.sql
- models/marts/strava/dim_strava__*.sql and fct_strava__*.sql
  Optional: models/reporting/strava/rpt_strava__*.sql only if Evidence needs it.

Best practices (mandatory)
- No SELECT * in final select statements.
- Every model declares:
  - grain
  - primary key
  - join keys
- Add schema.yml docs/tests:
  - unique + not_null on PKs
  - relationships facts → dims
  - accepted_values for categorical fields (sport_type, stream_type, zone_type)
- Prefer incremental only for very large tables (likely stream points). Only implement incremental if:
  - a reliable updated_at/ingestion_ts exists OR
  - you can implement a deterministic replace-by-partition strategy.
    Otherwise use table materialization.

Deliverables
1) Phase 1 output: raw schema descriptions + recommended grains/keys + modeling plan.
2) Phase 2 output: list of deleted files.
3) Phase 3 output: created files (SQL + YAML) and a summary of model grains + joins.

Now begin with Phase 1: inspect the raw tables in strava_raw and report findings.
Only proceed to deletion + model creation after the raw schema is confirmed.
