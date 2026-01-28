# RAG + MCP plan for strava-datastack

## Repo discovery (verified)
- Subprojects: `extract/`, `transform/`, `visualize/`, `airflow/`, `infra/`.
- Evidence pages: `visualize/pages/index.md`, `visualize/pages/activity/*`, `visualize/pages/year/*`.
- Evidence sources: `visualize/sources/strava/*.sql` mapped to reporting models.
- DuckDB paths: `DUCKDB_PATH` for raw/analytics, `DUCKDB_REPORTING_PATH` for reporting; Evidence uses `visualize/.env` pointing to `airflow/data/strava_reporting.duckdb`.
- Airflow DAG: `airflow/dags/strava_pipeline.py` (extract → dbt transform), with `StravaExtractOperator` in `airflow/plugins/operators/`.
- Lineage/observability stacks exist in `infra/lineage/` (Marquez) and `infra/observability/` (OTel + Grafana + Jaeger).

## Data discovery (verified)
- dbt reporting models in `transform/models/reporting/` with docs in `_reporting__models.yml`.
- Stable semantic layer candidates:
  - `rpt_kpis__all`
  - `rpt_activity_list__activity`
  - `rpt_activity_hr_zones__activity_zone`
  - `rpt_activity_power_zones__activity_zone`
  - `rpt_activity_pace_zones__activity_zone`
  - `rpt_streaks__all`
  - `rpt_home_daily_trends__day`
  - `rpt_activity_daily_trends__sport_type_day`
  - `rpt_distinct_years__year`
  - `rpt_year_routes__year`

## Prioritized RAG + MCP use cases (grounded in repo)
1) Explain charts/metrics on Activity and Year dashboards
   - User intent: explain metric meaning and “what changed”.
   - Data: KPI models from `rpt_kpis__all` via Evidence sources.
   - Retrieval: Evidence page markdown + dbt model docs.
   - Why RAG: assemble metric definitions + grain context.
   - MCP tools: `GetKpis`, `ComparePeriods`, `GetMetricDefinition`, `GetPageContext`.

2) Explain individual activity and zone distributions
   - User intent: summarize workout and zone splits.
   - Data: `rpt_activity_list__activity`, zone models.
   - Retrieval: activity detail page + dbt docs.
   - MCP tools: `GetActivityDetail`, `GetActivityZones`, `ExplainZoneDistribution`.

3) Streaks and consistency explanations
   - User intent: how streaks computed, why streaks change.
   - Data: `rpt_streaks__all`, daily trends models.
   - Retrieval: activity/year pages + dbt docs.
   - MCP tools: `GetStreaks`, `GetDailyTrends`, `GetMetricDefinition`.

4) Sport‑specific performance narratives
   - User intent: compare a sport year‑over‑year.
   - Data: sport KPI models + activity list.
   - Retrieval: sport drilldown pages + dbt docs.
   - MCP tools: `GetSportSummary`, `CompareSportPeriods`, `ListSportCapabilities`.

5) Pipeline freshness/debug (only if Airflow API enabled)
   - User intent: why new activity is missing.
   - Data: `max_activity_date` + Airflow runs.
   - Retrieval: DAG docs + run logs/lineage.
   - MCP tools: `GetLatestActivityDate`, `GetDagRuns`, `GetDagRunLogs`, `GetLineage`.

## Architecture (detailed)

### Components
- Evidence (frontend): chat widget/page only; no heavy aggregation.
- FastAPI assistant backend (new): chat orchestration + RAG + MCP tool calls.
- MCP server (new): exclusive access to data/tools; read‑only, parameterized.
- RAG indexer (new): builds vector index of docs and model metadata.

### Boundaries
- LLM never queries DuckDB directly.
- MCP only queries whitelisted reporting models or Evidence source views.
- No secrets printed; all credentials via env vars.

### RAG indexing scope
- Evidence pages: `visualize/pages/**`
- Evidence sources: `visualize/sources/strava/*.sql`
- dbt models/docs: `transform/models/**/*.sql`, `transform/models/**/*.yml`
- DAG docs: `airflow/dags/strava_pipeline.py`
- Readmes: `extract/README.md`, `transform/README.md`, `infra/README.md`, `visualize/README.md`

### Chunking + metadata
- Chunk 500–800 tokens, 100 overlap.
- Metadata: `doc_type`, `file_path`, `model_name`, `grain`, `page_route`.

### Embedding store
- Local‑first store (FAISS/Chroma) under `assistant/data/`.

### MCP tool interface (examples)
- `ListMetrics()`
- `GetMetricDefinition(metric_id)`
- `GetKpis(grain, year?, month?, sport_slug?)`
- `ComparePeriods(metric_id, period_a, period_b, sport_slug?)`
- `GetActivitySummary(activity_id)`
- `GetActivityZones(activity_id, zone_type)`
- `GetStreaks(grain, year?, sport_slug?)`
- `GetDailyTrends(year?, sport_slug?)`
- `GetPageContext(page_path)`
- `GetDagRuns(dag_id, limit)` (optional)
- `GetDagRunLogs(dag_id, run_id, task_id)` (optional)
- `GetLineage(entity_id)` (optional, if Marquez enabled)

### Sequence diagrams (text)
1) Chat question → Evidence → FastAPI → RAG → MCP → DuckDB → LLM → Evidence
2) Explain chart → Evidence → FastAPI → RAG + MCP → LLM → Evidence
3) Debug pipeline → Evidence → FastAPI → MCP (Airflow API) → LLM → Evidence

### Deployment topology
- Local dev: Evidence + assistant, no Airflow. MCP reads `strava_reporting.duckdb`.
- Dev (no Airflow): same as local.
- Prod (Airflow via compose): assistant reads reporting DB; optional Airflow API + Marquez.

### Data contracts (examples)
- `POST /api/chat`
  - Request: `{ message, page_path, filters, session_id }`
  - Response: `{ answer, citations[], data_points[] }`
- Tool outputs: structured JSON with explicit schema for each tool.

### Observability
- Structured logs in assistant + MCP; include correlation IDs.
- OpenTelemetry hooks (if enabled in infra stack).
- Redaction of secrets.

## Implementation plan (phased)

Phase 0 — discovery notes + ADR
- Add ADR summarizing architecture decisions and repo constraints.

Phase 1 — MCP server scaffold + 1–2 tools
- Implement read‑only MCP with `ListMetrics` + `GetKpis`.
- Enforce allowlisted models and parameter validation.

Phase 2 — RAG indexer
- Build indexer job for docs/models/pages.
- Store index locally under `assistant/data/`.

Phase 3 — FastAPI endpoints + Evidence integration
- Add `/api/chat` and `/api/explain_chart` endpoints.
- Add Evidence component for chat (lightweight UI).

Phase 4 — Hardening
- Auth (API key/JWT), rate limits, caching.
- Prompt‑injection defenses + tool allowlist.
- Redaction and logging policy.

Phase 5 — Optional enhancements (only if infra enabled)
- Airflow run status and logs tools.
- Lineage retrieval via Marquez.

## Security & safety
- No direct DuckDB access by LLM.
- Parameterized, whitelisted tools only.
- Env vars for credentials and secrets.
- RAG content treated as untrusted; never executed.
- Clear auth boundaries between UI, API, MCP, and data sources.

## Assumptions
- Evidence sources in `visualize/sources/strava/*.sql` remain stable.
- dbt artifacts (manifest/catalog) can be generated during indexing.
- No existing backend service; new `assistant/` service is acceptable.
