# Strava Visualize

Interactive analytics dashboards built with [Evidence.dev](https://evidence.dev/) and SvelteKit.

## Features

- **KPI Dashboard**: Year-over-year metrics, totals, averages
- **Streak Analysis**: Activity streaks and consistency tracking
- **Trend Visualization**: Time-series charts for performance trends
- **Activity Details**: Deep-dive into individual activities
- **Zone Analysis**: Heart rate and power zone distributions
- **Calendar Heatmaps**: Activity frequency visualization
- **Dynamic Routing**: Year and activity-specific pages

## Installation

```bash
make install  # npm install
```

## Configuration

### Data Source

The dashboard connects to the reporting DuckDB database:

**`sources/strava/connection.yaml`:**

```yaml
name: strava
type: duckdb
options:
  filename: ../../../strava_reporting.duckdb
```

### Environment Variables

| Variable                            | Description              | Default                            |
|-------------------------------------|--------------------------|------------------------------------|
| `EVIDENCE_SOURCE__strava__filename` | Path to reporting DuckDB | `../../../strava_reporting.duckdb` |

## Makefile Targets

| Target                | Description                |
|-----------------------|----------------------------|
| `make help`           | Show all available targets |
| `make install`        | Install npm dependencies   |
| `make dev`            | Start development server   |
| `make build`          | Production build           |
| `make build-strict`   | Build with strict mode     |
| `make preview`        | Preview production build   |
| `make sources`        | Validate data sources      |
| `make sources-strict` | Strict source validation   |
| `make test`           | Run tests                  |
| `make clean`          | Clean build artifacts      |

## Usage

### Development

```bash
make dev
# Opens http://localhost:3000
```

### Production Build

```bash
make build
make preview
```

## Page Structure

```
pages/
├── index.md                           # Main dashboard with KPIs and streaks
├── year/
│   ├── index.md                       # Year selection page
│   ├── [year].md                      # Year-specific dashboard
│   └── [year]/[sport].md              # Year + sport type breakdown
└── activity/
    ├── index.md                       # Activity list
    ├── [sport].md                     # Activities by sport type
    └── [sport_type]/[activity_id].md  # Individual activity detail
```

### Dynamic Routes

- `/year/2024` - Dashboard for 2024
- `/year/2024/Run` - Running activities in 2024
- `/activity/Run/12345678` - Specific activity detail page

## Data Sources

SQL queries in `sources/strava/` power the dashboards:

| Source                            | Description                  |
|-----------------------------------|------------------------------|
| `src_strava__kpis.sql`            | KPI calculations and metrics |
| `src_strava__streaks.sql`         | Activity streak analysis     |
| `src_strava__activity_detail.sql` | Individual activity data     |
| `src_strava__activity_zones.sql`  | Zone distribution data       |

## Theme Configuration

Custom theme in `evidence.config.yaml`:

```yaml
appearance:
  default: system
  switcher: true

theme:
  colors:
    primary:
      light: "#2563eb"
      dark: "#3b82f6"
    accent:
      light: "#c2410c"
      dark: "#fdba74"
```

## Development Notes

### Adding New Pages

1. Create a new `.md` file in `pages/`
2. Add frontmatter with title
3. Write SQL queries inline or reference sources
4. Use Evidence components for visualization

### Adding New Data Sources

1. Add SQL file to `sources/strava/`
2. Reference in pages with `{#each source_name as row}`
3. Run `make sources` to validate

### Custom Components

Evidence supports custom Svelte components in `components/`. Import and use in markdown pages:

```markdown
<script>
  import CustomChart from '../components/CustomChart.svelte';
</script>

<CustomChart data={my_query} />
```
