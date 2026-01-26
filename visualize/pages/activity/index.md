---
title: Activities
---

<script>
  import MonthlyTrends from '../../components/MonthlyTrends.svelte';
  import SportSummaryCharts from '../../components/SportSummaryCharts.svelte';
  import { distanceUnitStore } from '../../components/utils/distanceUnit.js';
  import { getActivityIndexState, handleSportPieClick } from '../../components/scripts/activityIndex.js';

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
    recentActivitiesDisplay
  } = getActivityIndexState({
    distanceUnit,
    q_activity__recent_activities
  }));
</script>

```sql q_activity__kpis_alltime
select
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_mph
from strava.src_strava__kpis_all
```

```sql q_activity__trends_monthly
select
    month_start,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet
from strava.src_strava__kpis_year_month
order by month_start
```

```sql q_activity__streaks_alltime
select
    current_streak,
    longest_streak,
    active_days_last_30
from strava.src_strava__streaks_all
```

```sql q_activity__sport_summary
select
    sport_type,
    activity_count,
    total_moving_time_hours,
    total_distance_km,
    sport_slug
from strava.src_strava__kpis_sport_type
where activity_count > 0
order by activity_count desc
```

```sql q_activity__recent_activities
select
    activity_id,
    activity_name,
    sport_type,
    started_at,
    distance_km,
    distance_miles,
    moving_time_minutes,
    average_speed_mph,
    pace_min_per_km,
    activity_link
from strava.src_strava__activity_list
order by started_at desc
limit 20
```

## Overview

<BigValue
    data={q_activity__kpis_alltime}
    value=activity_count
    title="Total Activities"
    fmt="#,##0"
/>

<BigValue
    data={q_activity__kpis_alltime}
    value={distanceTotalField}
    title={distanceTotalTitle}
    fmt="#,##0.0"
/>

<BigValue
    data={q_activity__kpis_alltime}
    value=total_moving_time_hours
    title="Total Time (hrs)"
    fmt="#,##0"
/>

<BigValue
    data={q_activity__kpis_alltime}
    value=total_elevation_gain_feet
    title="Elevation Gain (ft)"
    fmt="#,##0"
/>

<BigValue
    data={q_activity__kpis_alltime}
    value=avg_speed_mph
    title="Avg Speed (mph)"
    fmt="#,##0.0"
/>

## Streaks

<BigValue
    data={q_activity__streaks_alltime}
    value=current_streak
    title="Current Streak (days)"
    fmt="#,##0"
/>

<BigValue
    data={q_activity__streaks_alltime}
    value=longest_streak
    title="Longest Streak (days)"
    fmt="#,##0"
/>

<BigValue
    data={q_activity__streaks_alltime}
    value=active_days_last_30
    title="Active Days (last 30)"
    fmt="#,##0"
/>

## Monthly Trends

<MonthlyTrends
  data={q_activity__trends_monthly}
  distanceMonthlyField={distanceMonthlyField}
  distanceSeriesField={distanceSeriesField}
  distanceSeriesName={distanceSeriesName}
  distanceMonthlyTitle={distanceMonthlyTitle}
/>

## By Sport Type

<SportSummaryCharts
  summaryRows={q_activity__sport_summary}
  onSliceClick={handleSportPieClick}
/>

## Recent Activities

<DataTable data={recentActivitiesDisplay} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=sport_type title="Sport"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_display title={`Distance (${distanceUnitLabel})`}/>
    <Column id=moving_time_minutes title="Duration (min)"/>
    <Column id=average_speed_mph title="Avg Speed (mph)"/>
</DataTable>
