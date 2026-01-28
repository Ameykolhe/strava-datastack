---
title: Year in Sports
sidebar_link: false
---

<script>
  import ActivityCalendar from '../../../components/activity/ActivityCalendar.svelte';
  import ActivityHeatmap from '../../../components/activity/ActivityHeatmap.svelte';
  import MonthlyTrends from '../../../components/charts/MonthlyTrends.svelte';
  import SportSummaryCharts from '../../../components/charts/SportSummaryCharts.svelte';
  import StreaksSummary from '../../../components/charts/StreaksSummary.svelte';
  import { distanceUnitStore } from '../../../components/utils/distanceUnit.js';
  import { getYearState, createYearSportPieClickHandler } from '../../../components/scripts/year.js';

  let distanceUnit = 'km';
  $: distanceUnit = $distanceUnitStore;
  $: ({
    distanceTotalField,
    distanceMonthlyField,
    distanceSeriesField,
    distanceSeriesName,
    distanceTotalTitle,
    distanceMonthlyTitle,
    yearKpisWithComparisons
  } = getYearState({
    distanceUnit,
    params,
    q_year__kpis
  }));
  const handleSportPieClick = createYearSportPieClickHandler(params);
</script>

```sql q_year__kpis
select
    activity_year,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    longest_distance_miles,
    hardest_elevation_gain_feet,
    avg_speed_mph
from strava.src_strava__kpis_year
where activity_year in (${params.year}, ${params.year} - 1)
```

```sql q_year__streaks
select
    activity_year,
    current_streak,
    longest_streak,
    active_days_year
from strava.src_strava__streaks_year
where activity_year = ${params.year}
```

```sql q_year__monthly
select
    month_start,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet
from strava.src_strava__kpis_year_month
where activity_year = ${params.year}
order by month_start
```

```sql q_year__sport_summary
select
    sport_type,
    sport_slug,
    activity_count,
    total_moving_time_hours,
    total_distance_km,
    total_distance_miles
from strava.src_strava__kpis_sport_type_year
where activity_year = ${params.year}
  and activity_count > 0
order by activity_count desc
```

```sql q_year__calendar
select
    activity_date,
    activity_count
from strava.src_strava__activity_daily_trends
where activity_year = ${params.year}
order by activity_date
```

```sql q_year__routes
select
    activity_year,
    polylines_json
from strava.src_strava__year_routes
where activity_year = ${params.year}
```

# {params.year}

## Overview

<BigValue
    data={[yearKpisWithComparisons]}
    value=activity_count
    comparison=count_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Total Activities"
    fmt="#,##0"
/>

<BigValue
    data={[yearKpisWithComparisons]}
    value={distanceTotalField}
    comparison=distance_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title={distanceTotalTitle}
    fmt="#,##0.0"
/>

<BigValue
    data={[yearKpisWithComparisons]}
    value=total_moving_time_hours
    comparison=time_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Total Time (hrs)"
    fmt="#,##0"
/>

<BigValue
    data={[yearKpisWithComparisons]}
    value=total_elevation_gain_feet
    comparison=elevation_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Elevation Gain (ft)"
    fmt="#,##0"
/>

## Streaks

<StreaksSummary data={q_year__streaks} />

## Activity Calendar

<ActivityCalendar data={q_year__calendar} />

## Monthly Trends

<MonthlyTrends
  data={q_year__monthly}
  distanceMonthlyField={distanceMonthlyField}
  distanceSeriesField={distanceSeriesField}
  distanceSeriesName={distanceSeriesName}
  distanceMonthlyTitle={distanceMonthlyTitle}
  minChartPoints={2}
/>

## By Sport Type

<SportSummaryCharts
  summaryRows={q_year__sport_summary}
  onSliceClick={handleSportPieClick}
/>

## Activity Heatmap

{#if q_year__routes.length > 0 && q_year__routes[0].polylines_json}

<ActivityHeatmap
    polylines={q_year__routes[0].polylines_json}
height={500}
/>

{:else}

No routes available to display for this year.

{/if}
