---
title: Activity Details
---

<script>
  import ZoneDistribution from "$lib/ZoneDistribution.svelte";
</script>

```sql activity_detail
select
    activity_id,
    activity_name,
    sport_type,
    workout_type,
    started_at,
    started_at_local,
    distance_miles,
    moving_time_seconds,
    elapsed_time_seconds,
    elevation_gain_feet,
    average_speed_mph,
    max_speed_mph,
    average_heartrate_bpm,
    max_heartrate_bpm,
    average_watts,
    kilojoules,
    calories_burned,
    map_summary_polyline,
    kudos_count,
    comment_count,
    achievement_count,
    pr_count,
    suffer_score
from strava.activity_detail
where activity_id = CAST('${params.activity_id}' AS BIGINT)
```

```sql hr_zones
select
    activity_id,
    zone_id,
    zone_name,
    zone_min_bpm,
    zone_max_bpm,
    time_seconds,
    time_minutes,
    pct_in_zone
from strava.activity_hr_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

```sql power_zones
select
    activity_id,
    zone_id,
    zone_name,
    zone_min_watts,
    zone_max_watts,
    time_seconds,
    time_minutes,
    pct_in_zone
from strava.activity_power_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

{#if activity_detail.length > 0}

# {activity_detail[0].activity_name}

**{activity_detail[0].sport_type}** on {activity_detail[0].started_at_local}

## Ride Summary

<BigValue
    data={activity_detail}
    value=distance_miles
    title="Distance (mi)"
    fmt='#,##0.2'
/>

<BigValue
    data={activity_detail}
    value=moving_time_seconds
    title="Moving Time"
/>

<BigValue
    data={activity_detail}
    value=elevation_gain_feet
    title="Elevation (ft)"
    fmt='#,##0'
/>

<BigValue
    data={activity_detail}
    value=average_speed_mph
    title="Avg Speed (mph)"
    fmt='#,##0.1'
/>

{#if activity_detail[0].average_heartrate_bpm != null}
<BigValue
    data={activity_detail}
    value=average_heartrate_bpm
    title="Avg HR (bpm)"
    fmt='#,##0'
/>
{/if}

{#if activity_detail[0].average_watts != null}
<BigValue
    data={activity_detail}
    value=average_watts
    title="Avg Power (W)"
    fmt='#,##0'
/>
{/if}

## Details

| Metric | Value |
|--------|-------|
| Sport Type | {activity_detail[0].sport_type} |
| Workout Type | {activity_detail[0].workout_type ?? 'N/A'} |
| Elapsed Time | {activity_detail[0].elapsed_time_seconds} seconds |
| Moving Time | {activity_detail[0].moving_time_seconds} seconds |
| Distance | {activity_detail[0].distance_miles?.toFixed(2) ?? 'N/A'} mi |
| Elevation Gain | {activity_detail[0].elevation_gain_feet?.toFixed(0) ?? 'N/A'} ft |
| Avg Speed | {activity_detail[0].average_speed_mph?.toFixed(1) ?? 'N/A'} mph |
| Max Speed | {activity_detail[0].max_speed_mph?.toFixed(1) ?? 'N/A'} mph |

{#if activity_detail[0].average_heartrate_bpm != null}

### Heart Rate

| Metric | Value |
|--------|-------|
| Avg HR | {activity_detail[0].average_heartrate_bpm?.toFixed(0) ?? 'N/A'} bpm |
| Max HR | {activity_detail[0].max_heartrate_bpm?.toFixed(0) ?? 'N/A'} bpm |

{/if}

{#if activity_detail[0].average_watts != null}

### Power

| Metric | Value |
|--------|-------|
| Avg Power | {activity_detail[0].average_watts?.toFixed(0) ?? 'N/A'} W |
| Energy | {activity_detail[0].kilojoules?.toFixed(0) ?? 'N/A'} kJ |
| Calories | {activity_detail[0].calories_burned?.toFixed(0) ?? 'N/A'} kcal |

{/if}

## Heart Rate Zones

<ZoneDistribution
    data={hr_zones}
    minField="zone_min_bpm"
    maxField="zone_max_bpm"
    unit="bpm"
/>

## Power Zones

<ZoneDistribution
    data={power_zones}
    minField="zone_min_watts"
    maxField="zone_max_watts"
    unit="W"
/>

### Strava Stats

| Metric | Value |
|--------|-------|
| Kudos | {activity_detail[0].kudos_count} |
| Comments | {activity_detail[0].comment_count} |
| Achievements | {activity_detail[0].achievement_count} |
| PRs | {activity_detail[0].pr_count} |
| Suffer Score | {activity_detail[0].suffer_score ?? 'N/A'} |

{:else}

# Activity Not Found

The activity with ID **{params.activity_id}** was not found.

{/if}
