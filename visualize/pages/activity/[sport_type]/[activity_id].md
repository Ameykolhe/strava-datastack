---
title: Activity Details
hide_title: true
---

<script>
  import ActivityHeader from '../../../../components/activity/detail/ActivityHeader.svelte';
  import CoreMetricsGrid from '../../../../components/activity/detail/CoreMetricsGrid.svelte';
  import ActivityDetailsGrouped from '../../../../components/activity/detail/ActivityDetailsGrouped.svelte';
  import ActivityRouteMap from '../../../../components/activity/ActivityRouteMap.svelte';
  import ZoneDistributionSection from '../../../../components/activity/detail/ZoneDistributionSection.svelte';
  import { distanceUnitStore } from '../../../../components/utils/distanceUnit.js';

  let distanceUnit = 'km';
  let speedUnit = 'kph';

  $: distanceUnit = $distanceUnitStore;
  $: speedUnit = distanceUnit === 'km' ? 'kph' : 'mph';
</script>

```sql q_activity_detail__activity
select * from strava.src_activity_detail__activity
where activity_id = CAST('${params.activity_id}' AS BIGINT)
```

```sql q_activity_detail__hr_zones
select * from strava.src_strava__activity_hr_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

```sql q_activity_detail__power_zones
select * from strava.src_strava__activity_power_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

```sql q_activity_detail__pace_zones
select * from strava.src_strava__activity_pace_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

{#if q_activity_detail__activity.length > 0}

<ActivityHeader
  activityName={q_activity_detail__activity[0].activity_name}
  sportType={q_activity_detail__activity[0].sport_type}
  startedAtLocal={q_activity_detail__activity[0].started_at_local}
  timezone={q_activity_detail__activity[0].timezone}
  locationCity={q_activity_detail__activity[0].location_city}
  locationState={q_activity_detail__activity[0].location_state}
  locationCountry={q_activity_detail__activity[0].location_country}
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

{#if q_activity_detail__activity.length > 0 && (q_activity_detail__activity[0].polyline || (q_activity_detail__activity[0].start_latitude && q_activity_detail__activity[0].start_longitude))}

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

<ActivityDetailsGrouped
  activity={q_activity_detail__activity[0]}
  speedUnit={speedUnit}
/>

{/if}

## Zone Distribution

{#if q_activity_detail__hr_zones.length > 0 || q_activity_detail__power_zones.length > 0 || q_activity_detail__pace_zones.length > 0}

<ZoneDistributionSection
  zoneData={q_activity_detail__hr_zones}
  zoneType="hr"
  title="Heart Rate Zones"
/>

<ZoneDistributionSection
  zoneData={q_activity_detail__power_zones}
  zoneType="power"
  title="Power Zones"
/>

<ZoneDistributionSection
  zoneData={q_activity_detail__pace_zones}
  zoneType="pace"
  title="Pace Zones"
/>

{:else}

<p><em>No zone data available for this activity.</em></p>

{/if}