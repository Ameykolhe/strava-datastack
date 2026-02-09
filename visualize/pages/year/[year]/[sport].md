---
title: Year in Sport
sidebar_link: false
---

<script>
  import ActivityCalendar from '../../../../components/activity/ActivityCalendar.svelte';
  import ActivitiesList from '../../../../components/activity/ActivitiesList.svelte';
  import MonthlyTrends from '../../../../components/charts/MonthlyTrends.svelte';
  import StreaksSummary from '../../../../components/charts/StreaksSummary.svelte';
  import { distanceUnitStore } from '../../../../components/utils/distanceUnit.js';
  import { pctChange } from '../../../../components/lib/math.js';

  let distanceUnit = 'km';
  $: distanceUnit = $distanceUnitStore;
  $: isKm = distanceUnit === 'km';
  $: distanceTotalField = isKm ? 'total_distance_km' : 'total_distance_miles';
  $: distanceTotalTitle = isKm ? 'Total Distance (km)' : 'Total Distance (mi)';

  $: distanceSupported = q_year_sport__kpis?.length > 0 && q_year_sport__kpis[0].total_distance_km > 0;
  $: elevationSupported = q_year_sport__kpis?.length > 0 && q_year_sport__kpis[0].total_elevation_gain_feet > 0;
  $: currentYear = Number(params.year);
  $: currentKpi = q_year_sport__kpis?.find((row) => row.activity_year === currentYear) ?? null;
  $: prevKpi = q_year_sport__kpis?.find((row) => row.activity_year === currentYear - 1) ?? null;
  $: sportKpisWithComparisons = currentKpi ? {
    ...currentKpi,
    distance_change: distanceSupported ? pctChange(currentKpi?.[distanceTotalField], prevKpi?.[distanceTotalField]) : null,
    time_change: pctChange(currentKpi?.total_moving_time_hours, prevKpi?.total_moving_time_hours),
    elevation_change: elevationSupported ? pctChange(currentKpi?.total_elevation_gain_feet, prevKpi?.total_elevation_gain_feet) : null,
    count_change: pctChange(currentKpi?.activity_count, prevKpi?.activity_count),
    speed_change: pctChange(currentKpi?.avg_speed_kmh, prevKpi?.avg_speed_kmh),
    pace_change: pctChange(currentKpi?.avg_pace_min_per_km, prevKpi?.avg_pace_min_per_km),
    hr_change: pctChange(currentKpi?.avg_heartrate_bpm, prevKpi?.avg_heartrate_bpm)
  } : null;
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
from strava.src_strava__kpis
where grain = 'sport_type_year'
  and activity_year in (${params.year}, ${params.year} - 1)
  and lower(coalesce(sport_slug, sport_type)) = lower('${params.sport}')
```

```sql q_year_sport__streaks
select
    sport_type,
    sport_slug,
    activity_year,
    current_streak,
    longest_streak,
    active_days_year
from strava.src_strava__streaks
where grain = 'sport_type_year'
  and activity_year = ${params.year}
  and lower(coalesce(sport_slug, sport_type)) = lower('${params.sport}')
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
from strava.src_strava__kpis
where grain = 'sport_type_year_month'
  and activity_year = ${params.year}
  and lower(coalesce(sport_slug, sport_type)) = lower('${params.sport}')
order by month_start
```

```sql q_year_sport__calendar
select
    activity_date,
    activity_count
from strava.src_strava__kpis
where grain = 'sport_type_day'
  and activity_year = ${params.year}
  and lower(coalesce(sport_slug, sport_type)) = lower('${params.sport}')
order by activity_date
```

```sql q_year_sport__activities
select activity_id,
       activity_name,
       started_at,
       distance_km,
       distance_miles,
       moving_time_display,
       elevation_gain_feet,
       average_speed_kph,
       pace_min_per_km,
       average_heartrate_bpm,
       average_watts,
       activity_link
from strava.src_strava__activity_detail
where activity_year = ${params.year}
  and lower(coalesce(sport_slug, sport_type)) = lower('${params.sport}')
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
minChartPoints={2}
/>

## All Activities

<ActivitiesList data={q_year_sport__activities} />
