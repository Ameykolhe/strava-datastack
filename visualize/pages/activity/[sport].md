---
title: Sport
sidebar_link: false
---

<script>
  import MonthlyTrends from '../../../components/charts/MonthlyTrends.svelte';
  import ActivitiesDataTable from '../../../components/activity/ActivitiesDataTable.svelte';
  import { distanceUnitStore } from '../../../components/utils/distanceUnit.js';
  import { getActivitySportState } from '../../../components/scripts/activitySport.js';

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
    sportTitle,
    distanceSupported,
    elevationSupported,
    hasPace,
    hasHeartRate,
    hasWatts,
    hasSpeed,
    activitiesDisplay
  } = getActivitySportState({
    distanceUnit,
    params,
    q_activity_sport__kpis,
    q_activity_sport__activities
  }));
</script>

```sql q_activity_sport__kpis
select
    sport_type,
    sport_slug,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_kmh,
    avg_heartrate_bpm,
    avg_pace_min_per_km
from strava.src_strava__kpis_sport_type
where sport_slug = '${params.sport}'
```

```sql q_activity_sport__kpis_month
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
where sport_slug = '${params.sport}'
order by month_start
```

```sql q_activity_sport__activities
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
where sport_slug = '${params.sport}'
order by started_at desc
```

# {sportTitle}

## Overview

<BigValue
    data={q_activity_sport__kpis}
    value=activity_count
    title="Total Activities"
    fmt="#,##0"
/>

<BigValue
    data={q_activity_sport__kpis}
    value=total_moving_time_hours
    title="Total Time (hrs)"
    fmt="#,##0.0"
/>

{#if distanceSupported}
<BigValue
    data={q_activity_sport__kpis}
    value={distanceTotalField}
    title={distanceTotalTitle}
    fmt="#,##0.0"
/>
{/if}

{#if elevationSupported}
<BigValue
    data={q_activity_sport__kpis}
    value=total_elevation_gain_feet
    title="Elevation Gain (ft)"
    fmt="#,##0"
/>
{/if}

{#if q_activity_sport__kpis.length > 0 && q_activity_sport__kpis[0].avg_speed_kmh != null}
<BigValue
    data={q_activity_sport__kpis}
    value=avg_speed_kmh
    title="Avg Speed (km/h)"
    fmt="#,##0.0"
/>
{/if}

{#if q_activity_sport__kpis.length > 0 && q_activity_sport__kpis[0].avg_pace_min_per_km != null}
<BigValue
    data={q_activity_sport__kpis}
    value=avg_pace_min_per_km
    title="Avg Pace (min/km)"
    fmt="#,##0.00"
/>
{/if}

{#if q_activity_sport__kpis.length > 0 && q_activity_sport__kpis[0].avg_heartrate_bpm != null}
<BigValue
    data={q_activity_sport__kpis}
    value=avg_heartrate_bpm
    title="Avg HR (bpm)"
    fmt="#,##0"
/>
{/if}

## Monthly Trends

<MonthlyTrends
  data={q_activity_sport__kpis_month}
  distanceSupported={distanceSupported}
  elevationSupported={elevationSupported}
  distanceMonthlyField={distanceMonthlyField}
  distanceSeriesField={distanceSeriesField}
  distanceSeriesName={distanceSeriesName}
  distanceMonthlyTitle={distanceMonthlyTitle}
/>

## All Activities

<ActivitiesDataTable
  activitiesDisplay={activitiesDisplay}
  distanceSupported={distanceSupported}
  elevationSupported={elevationSupported}
  hasSpeed={hasSpeed}
  hasPace={hasPace}
  hasHeartRate={hasHeartRate}
  hasWatts={hasWatts}
  distanceUnitLabel={distanceUnitLabel}
/>
