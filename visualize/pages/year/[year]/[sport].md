---
title: Year in Sport
sidebar_link: false
---

<script>
  import ActivityCalendar from '../../../../components/ActivityCalendar.svelte';
  import MonthlyTrends from '../../../../components/MonthlyTrends.svelte';
  import StreaksSummary from '../../../../components/StreaksSummary.svelte';
  import { distanceUnitStore } from '../../../../components/utils/distanceUnit.js';
  import { getYearSportState } from '../../../../components/scripts/yearSport.js';

  let distanceUnit = 'km';
  $: distanceUnit = $distanceUnitStore;
  $: ({
    distanceUnitLabel,
    distanceTotalField,
    distanceMonthlyField,
    distanceSeriesField,
    distanceSeriesName,
    distanceTotalTitle,
    distanceMonthlyTitle,
    distanceSupported,
    elevationSupported,
    sportKpisWithComparisons,
    hasPace,
    hasHeartRate,
    hasWatts,
    hasSpeed,
    activitiesDisplay
  } = getYearSportState({
    distanceUnit,
    params,
    q_year_sport__kpis,
    q_year_sport__activities
  }));
</script>

```sql q_year_sport__kpis
select
    sport_type,
    sport_slug,
    activity_year,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_kmh,
    avg_heartrate_bpm,
    avg_pace_min_per_km
from strava.src_strava__kpis_sport_type_year
where activity_year in (${params.year}, ${params.year} - 1)
  and sport_slug = '${params.sport}'
```

```sql q_year_sport__streaks
select
    sport_type,
    sport_slug,
    activity_year,
    current_streak,
    longest_streak,
    active_days_year
from strava.src_strava__streaks_sport_type_year
where activity_year = ${params.year}
  and sport_slug = '${params.sport}'
```

```sql q_year_sport__kpis_year_month
select
    month_start,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_heartrate_bpm
from strava.src_strava__kpis_sport_type_year_month
where activity_year = ${params.year}
  and sport_slug = '${params.sport}'
order by month_start
```

```sql q_year_sport__calendar
select
    activity_date,
    activity_count
from strava.src_strava__activity_daily_trends_sport_type
where activity_year = ${params.year}
  and sport_slug = '${params.sport}'
order by activity_date
```

```sql q_year_sport__activities
select
    activity_id,
    activity_name,
    started_at,
    distance_km,
    distance_miles,
    moving_time_minutes,
    elevation_gain_feet,
    average_speed_kph,
    pace_min_per_km,
    average_heartrate_bpm,
    average_watts,
    activity_link
from strava.src_strava__activity_list
where activity_year = ${params.year}
  and sport_slug = '${params.sport}'
order by started_at desc
```

# {params.year} {q_year_sport__kpis[0]?.sport_type}

## Overview

<BigValue
    data={[sportKpisWithComparisons]}
    value=activity_count
    comparison=count_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Total Activities"
    fmt="#,##0"
/>

<BigValue
    data={[sportKpisWithComparisons]}
    value=total_moving_time_hours
    comparison=time_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Total Time (hrs)"
    fmt="#,##0.0"
/>

{#if distanceSupported}
<BigValue
    data={[sportKpisWithComparisons]}
    value={distanceTotalField}
    comparison=distance_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title={distanceTotalTitle}
    fmt="#,##0.0"
/>
{/if}

{#if elevationSupported}
<BigValue
    data={[sportKpisWithComparisons]}
    value=total_elevation_gain_feet
    comparison=elevation_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Elevation Gain (ft)"
    fmt="#,##0"
/>
{/if}

{#if q_year_sport__kpis.length > 0 && q_year_sport__kpis[0].avg_speed_kmh != null}
<BigValue
    data={[sportKpisWithComparisons]}
    value=avg_speed_kmh
    comparison=speed_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Avg Speed (km/h)"
    fmt="#,##0.0"
/>
{/if}

{#if q_year_sport__kpis.length > 0 && q_year_sport__kpis[0].avg_pace_min_per_km != null}
<BigValue
    data={[sportKpisWithComparisons]}
    value=avg_pace_min_per_km
    comparison=pace_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Avg Pace (min/km)"
    fmt="#,##0.00"
/>
{/if}

{#if q_year_sport__kpis.length > 0 && q_year_sport__kpis[0].avg_heartrate_bpm != null}
<BigValue
    data={[sportKpisWithComparisons]}
    value=avg_heartrate_bpm
    comparison=hr_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Avg HR (bpm)"
    fmt="#,##0"
/>
{/if}

## Streaks

<StreaksSummary data={q_year_sport__streaks} />

## Activity Calendar

<ActivityCalendar data={q_year_sport__calendar} />

## Monthly Trends

<MonthlyTrends
  data={q_year_sport__kpis_year_month}
  distanceSupported={distanceSupported}
  elevationSupported={elevationSupported}
  distanceMonthlyField={distanceMonthlyField}
  distanceSeriesField={distanceSeriesField}
  distanceSeriesName={distanceSeriesName}
  distanceMonthlyTitle={distanceMonthlyTitle}
  minChartPoints={2}
/>

## All Activities

<DataTable data={activitiesDisplay} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    {#if distanceSupported}
    <Column id=distance_display title={`Distance (${distanceUnitLabel})`}/>
    {/if}
    <Column id=moving_time_minutes title="Duration (min)"/>
    {#if elevationSupported}
    <Column id=elevation_gain_feet title="Elevation (ft)"/>
    {/if}
    {#if hasSpeed}
    <Column id=average_speed_kph title="Avg Speed (km/h)"/>
    {/if}
    {#if hasPace}
    <Column id=pace_min_per_km title="Pace (min/km)"/>
    {/if}
    {#if hasHeartRate}
    <Column id=average_heartrate_bpm title="Avg HR"/>
    {/if}
    {#if hasWatts}
    <Column id=average_watts title="Avg Watts"/>
    {/if}
</DataTable>
