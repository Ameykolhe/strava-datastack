---
title: Activity Details
hide_title: true
---

<script>
  import ActivityHeader from '../../../../components/activity/detail/ActivityHeader.svelte';
  import CoreMetricsGrid from '../../../../components/activity/detail/CoreMetricsGrid.svelte';
  import EngagementStats from '../../../../components/activity/detail/EngagementStats.svelte';
  import ActivityRouteMap from '../../../../components/activity/ActivityRouteMap.svelte';
  import ZoneDistribution from '../../../../components/activity/detail/ZoneDistribution.svelte';
  import { distanceUnitStore } from '../../../../components/utils/distanceUnit.js';

  let distanceUnit = 'km';
  let speedUnit = 'kph';

  $: distanceUnit = $distanceUnitStore;
  $: speedUnit = distanceUnit === 'km' ? 'kph' : 'mph';
</script>

```sql q_activity_detail__activity
select * from strava.src_strava__activity_detail
where activity_id = CAST('${params.activity_id}' AS BIGINT)
```

```sql q_activity_detail__hr_zones
select
    activity_id,
    zone_id,
    zone_name,
    zone_min_value as zone_min_bpm,
    zone_max_value as zone_max_bpm,
    time_seconds,
    time_minutes,
    pct_in_zone
from strava.src_strava__activity_zones
where zone_type = 'heartrate'
  and activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

```sql q_activity_detail__power_zones
select
    activity_id,
    zone_id,
    zone_name,
    zone_min_value as zone_min_watts,
    zone_max_value as zone_max_watts,
    time_seconds,
    time_minutes,
    pct_in_zone
from strava.src_strava__activity_zones
where zone_type = 'power'
  and activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

```sql q_activity_detail__pace_zones
select
    activity_id,
    zone_id,
    zone_name,
    zone_min_value as zone_min_pace,
    zone_max_value as zone_max_pace,
    time_seconds,
    time_minutes,
    pct_in_zone
from strava.src_strava__activity_zones
where zone_type = 'pace'
  and activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

{#if q_activity_detail__activity.length > 0}

<ActivityHeader
activityName={q_activity_detail__activity[0].activity_name}
startedAt={q_activity_detail__activity[0].started_at}
timezone={q_activity_detail__activity[0].timezone}
deviceName={q_activity_detail__activity[0].device_name}
/>

{/if}

## Overview

{#if q_activity_detail__activity.length > 0}

<CoreMetricsGrid
activity={q_activity_detail__activity[0]}
distanceUnit={distanceUnit}
speedUnit={speedUnit}
/>

{:else}

The activity with ID **{params.activity_id}** was not found.

{/if}

## Route Map

{#if q_activity_detail__activity.length > 0 && (q_activity_detail__activity[0].polyline || (
q_activity_detail__activity[0].start_latitude && q_activity_detail__activity[0].start_longitude))}

{#if q_activity_detail__activity[0].polyline}
<ActivityRouteMap
polyline={q_activity_detail__activity[0].polyline}
height={400}
/>
{:else}
<p>Map data available but no polyline. Start: {q_activity_detail__activity[0].start_latitude}, {q_activity_detail__activity[0].start_longitude}</p>
{/if}

{:else}

<p><em>No route data available for this activity.</em></p>

{/if}

## Details

{#if q_activity_detail__activity.length > 0}

<EngagementStats
activity={q_activity_detail__activity[0]}
/>

{/if}

## Zone Distribution

{#if q_activity_detail__hr_zones.length > 0 || q_activity_detail__power_zones.length > 0 ||
q_activity_detail__pace_zones.length > 0}

<ZoneDistribution
zoneData={q_activity_detail__hr_zones}
zoneType="hr"
title="Heart Rate Zones"
/>

<ZoneDistribution
zoneData={q_activity_detail__power_zones}
zoneType="power"
title="Power Zones"
/>

<ZoneDistribution
zoneData={q_activity_detail__pace_zones}
zoneType="pace"
title="Pace Zones"
/>

{:else}

<p><em>No zone data available for this activity.</em></p>

{/if}