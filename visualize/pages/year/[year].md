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
  import { pctChange } from '../../../components/lib/math.js';
  import { goto } from '$app/navigation';

  const isBrowser = typeof window !== 'undefined';

  let distanceUnit = 'km';
  $: distanceUnit = $distanceUnitStore;
  $: isKm = distanceUnit === 'km';
  $: distanceTotalField = isKm ? 'total_distance_km' : 'total_distance_miles';
  $: distanceTotalTitle = isKm ? 'Total Distance (km)' : 'Total Distance (mi)';

  $: currentYear = Number(params.year);
  $: currentKpi = src_strava__kpis__year?.find((row) => row.activity_year === currentYear) ?? null;
  $: prevKpi = src_strava__kpis__year?.find((row) => row.activity_year === currentYear - 1) ?? null;
  $: yearKpisWithComparisons = currentKpi ? {
    ...currentKpi,
    distance_change: pctChange(currentKpi?.[distanceTotalField], prevKpi?.[distanceTotalField]),
    time_change: pctChange(currentKpi?.total_moving_time_hours, prevKpi?.total_moving_time_hours),
    elevation_change: pctChange(currentKpi?.total_elevation_gain_feet, prevKpi?.total_elevation_gain_feet),
    count_change: pctChange(currentKpi?.activity_count, prevKpi?.activity_count)
  } : null;

  const handleSportPieClick = (event) => {
    const payload = event?.detail ?? event;
    const slug = payload?.data?.sport_slug;
    if (slug && isBrowser) goto(`/year/${params.year}/${slug}`);
  };
</script>

```sql src_strava__kpis__year
select activity_year,
       activity_count,
       total_distance_km,
       total_distance_miles,
       total_moving_time_hours,
       total_elevation_gain_feet,
       longest_distance_miles,
       hardest_elevation_gain_feet,
       avg_speed_mph
from strava.src_strava__kpis
where grain = 'year'
  and activity_year in (${params.year}, ${params.year} - 1)
```

```sql src_strava__streaks__year
select activity_year,
       current_streak,
       longest_streak,
       active_days_year
from strava.src_strava__streaks
where grain = 'year'
  and activity_year = ${params.year}
```

```sql src_strava__kpis__year_month
select month_start,
       month_label,
       activity_count,
       total_distance_km,
       total_distance_miles,
       total_moving_time_hours,
       total_elevation_gain_feet
from strava.src_strava__kpis
where grain = 'year_month'
  and activity_year = ${params.year}
order by month_start
```

```sql src_strava__kpis__sport_type_year
select sport_type,
       sport_slug,
       activity_count,
       total_moving_time_hours,
       total_distance_km,
       total_distance_miles
from strava.src_strava__kpis
where grain = 'sport_type_year'
  and activity_year = ${params.year}
  and activity_count > 0
order by activity_count desc
```

```sql src_strava__kpis__day
select activity_date,
       activity_count
from strava.src_strava__kpis
where grain = 'day'
  and activity_year = ${params.year}
order by activity_date
```

```sql src_strava__activity_detail__year_routes
select activity_year,
       to_json(list(polyline)) as polylines_json
from strava.src_strava__activity_detail
where activity_year = ${params.year}
  and polyline is not null
  and trim(polyline) != ''
group by activity_year
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

<StreaksSummary data={src_strava__streaks__year} />

## Activity Calendar

<ActivityCalendar data={src_strava__kpis__day} />

## Monthly Trends

<MonthlyTrends
data={src_strava__kpis__year_month}
minChartPoints={2}
/>

## By Sport Type

<SportSummaryCharts
summaryRows={src_strava__kpis__sport_type_year}
onSliceClick={handleSportPieClick}
/>

## Activity Heatmap

{#if src_strava__activity_detail__year_routes.length > 0 && src_strava__activity_detail__year_routes[0].polylines_json}

<ActivityHeatmap
polylines={src_strava__activity_detail__year_routes[0].polylines_json}
height={500}
/>

{:else}

No routes available to display for this year.

{/if}
