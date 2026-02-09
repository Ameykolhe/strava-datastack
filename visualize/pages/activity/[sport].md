---
title: Sport
sidebar_link: false
---

<script>
  import MonthlyTrends from '../../../components/charts/MonthlyTrends.svelte';
  import ActivitiesList from '../../../components/activity/ActivitiesList.svelte';
  import { distanceUnitStore } from '../../../components/utils/distanceUnit.js';

  let distanceUnit = 'km';
  $: distanceUnit = $distanceUnitStore;
  $: isKm = distanceUnit === 'km';
  $: distanceTotalField = isKm ? 'total_distance_km' : 'total_distance_miles';
  $: distanceTotalTitle = isKm ? 'Total Distance (km)' : 'Total Distance (mi)';

  $: sportTitle = q_activity_sport__kpis?.[0]?.sport_type ?? params.sport;
  $: distanceSupported = q_activity_sport__kpis?.length > 0 && q_activity_sport__kpis[0].total_distance_km > 0;
  $: elevationSupported = q_activity_sport__kpis?.length > 0 && q_activity_sport__kpis[0].total_elevation_gain_feet > 0;
</script>

```sql q_activity_sport__kpis
select sport_type,
       sport_slug,
       activity_count,
       total_distance_km,
       total_distance_miles,
       total_moving_time_hours,
       total_elevation_gain_feet,
       avg_speed_kmh,
       avg_heartrate_bpm,
       avg_pace_min_per_km
from strava.src_strava__kpis
where grain = 'sport_type'
  and lower(coalesce(sport_slug, sport_type)) = lower('${params.sport}')
```

```sql q_activity_sport__kpis_month
select month_start,
       month_label,
       activity_count,
       total_distance_km,
       total_distance_miles,
       total_moving_time_hours,
       total_elevation_gain_feet,
       avg_heartrate_bpm
from strava.src_strava__kpis
where grain = 'sport_type_year_month'
  and lower(coalesce(sport_slug, sport_type)) = lower('${params.sport}')
order by month_start
```

```sql src_strava__streaks__sport_type
select current_streak,
       longest_streak,
       active_days_last_30
from strava.src_strava__streaks
where grain = 'sport_type'
  and lower(coalesce(sport_slug, sport_type)) = lower('${params.sport}')
```

```sql q_activity_sport__activities
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
where lower(coalesce(sport_slug, sport_type)) = lower('${params.sport}')
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

## Streaks

<BigValue
data={src_strava__streaks__sport_type}
value=current_streak
title="Current Streak (days)"
fmt="#,##0"
/>

<BigValue
data={src_strava__streaks__sport_type}
value=longest_streak
title="Longest Streak (days)"
fmt="#,##0"
/>

<BigValue
data={src_strava__streaks__sport_type}
value=active_days_last_30
title="Active Days (last 30)"
fmt="#,##0"
/>

## Monthly Trends

<MonthlyTrends
data={q_activity_sport__kpis_month}
/>

## All Activities

<ActivitiesList data={q_activity_sport__activities} />
