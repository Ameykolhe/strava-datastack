---
title: Activities
---

<script>
  import MonthlyTrends from '../../components/charts/MonthlyTrends.svelte';
  import SportSummaryCharts from '../../components/charts/SportSummaryCharts.svelte';
  import ActivitiesList from '../../components/activity/ActivitiesList.svelte';
  import { distanceUnitStore } from '../../components/utils/distanceUnit.js';
  import { goto } from '$app/navigation';

  const isBrowser = typeof window !== 'undefined';

  let distanceUnit = 'km';
  $: distanceUnit = $distanceUnitStore;
  $: isKm = distanceUnit === 'km';
  $: distanceTotalField = isKm ? 'total_distance_km' : 'total_distance_miles';
  $: distanceTotalTitle = isKm ? 'Total Distance (km)' : 'Total Distance (mi)';

  const handleSportPieClick = (event) => {
    const payload = event?.detail ?? event;
    const slug = payload?.data?.sport_slug;
    if (slug && isBrowser) goto(`/activity/${slug}`);
  };
</script>

```sql q_activity__kpis_alltime
select activity_count,
       total_distance_km,
       total_distance_miles,
       total_moving_time_hours,
       total_elevation_gain_feet,
       avg_speed_mph
from strava.src_strava__kpis
where grain = 'all'
```

```sql q_activity__trends_monthly
select month_start,
       month_label,
       activity_count,
       total_distance_km,
       total_distance_miles,
       total_moving_time_hours,
       total_elevation_gain_feet
from strava.src_strava__kpis
where grain = 'year_month'
order by month_start
```

```sql q_activity__streaks_alltime
select current_streak,
       longest_streak,
       active_days_last_30
from strava.src_strava__streaks
where grain = 'all'
```

```sql q_activity__sport_summary
select sport_type,
       activity_count,
       total_moving_time_hours,
       total_distance_km,
       sport_slug
from strava.src_strava__kpis
where grain = 'sport_type'
  and activity_count > 0
order by activity_count desc
```

```sql q_activity__recent_activities
select activity_id,
       activity_name,
       sport_type,
       started_at,
       distance_km,
       distance_miles,
       moving_time_minutes,
       average_speed_mph,
       pace_min_per_km,
       activity_link
from strava.src_strava__activity_detail
order by started_at desc limit 20
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
value=active_days_last_30
title="Active Days (last 30)"
fmt="#,##0"
/>

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

## Monthly Trends

<MonthlyTrends
data={q_activity__trends_monthly}
/>

## By Sport Type

<SportSummaryCharts
summaryRows={q_activity__sport_summary}
onSliceClick={handleSportPieClick}
/>

## Recent Activities

<ActivitiesList data={q_activity__recent_activities} />
