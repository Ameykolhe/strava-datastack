---
title: Activity Details
---

```sql activity_detail
select * from strava.activity_detail
where activity_id = CAST('${params.activity_id}' AS BIGINT)
```

```sql hr_zones
select * from strava.activity_hr_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

```sql power_zones
select * from strava.activity_power_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

{#if activity_detail.length > 0}

# {activity_detail[0].activity_name}

**{activity_detail[0].sport_type}** on {activity_detail[0].started_at_local}

## Ride Summary

<BigValue
    data={activity_detail}
    value=distance
    title="Distance (mi)"
    fmt='#,##0.2'
/>

<BigValue
    data={activity_detail}
    value=moving_seconds
    title="Moving Time"
/>

<BigValue
    data={activity_detail}
    value=elevation_gain
    title="Elevation (ft)"
    fmt='#,##0'
/>

<BigValue
    data={activity_detail}
    value=speed_avg
    title="Avg Speed (mph)"
    fmt='#,##0.1'
/>

{#if activity_detail[0].hr_avg != null}
<BigValue
    data={activity_detail}
    value=hr_avg
    title="Avg HR (bpm)"
    fmt='#,##0'
/>
{/if}

{#if activity_detail[0].power_avg != null}
<BigValue
    data={activity_detail}
    value=power_avg
    title="Avg Power (W)"
    fmt='#,##0'
/>
{/if}

## Details

| Metric | Value |
|--------|-------|
| Sport Type | {activity_detail[0].sport_type} |
| Workout Type | {activity_detail[0].workout_type ?? 'N/A'} |
| Elapsed Time | {activity_detail[0].elapsed_seconds} seconds |
| Moving Time | {activity_detail[0].moving_seconds} seconds |
| Distance | {activity_detail[0].distance?.toFixed(2) ?? 'N/A'} mi |
| Elevation Gain | {activity_detail[0].elevation_gain?.toFixed(0) ?? 'N/A'} ft |
| Avg Speed | {activity_detail[0].speed_avg?.toFixed(1) ?? 'N/A'} mph |
| Max Speed | {activity_detail[0].speed_max?.toFixed(1) ?? 'N/A'} mph |

{#if activity_detail[0].hr_avg != null}

### Heart Rate

| Metric | Value |
|--------|-------|
| Avg HR | {activity_detail[0].hr_avg?.toFixed(0) ?? 'N/A'} bpm |
| Max HR | {activity_detail[0].hr_max?.toFixed(0) ?? 'N/A'} bpm |

{/if}

{#if activity_detail[0].power_avg != null}

### Power

| Metric | Value |
|--------|-------|
| Avg Power | {activity_detail[0].power_avg?.toFixed(0) ?? 'N/A'} W |
| Energy | {activity_detail[0].kilojoules?.toFixed(0) ?? 'N/A'} kJ |
| Calories | {activity_detail[0].calories_burned?.toFixed(0) ?? 'N/A'} kcal |

{/if}

{#if hr_zones.length > 0}

## Heart Rate Zones

<BarChart
    data={hr_zones}
    x=zone_name
    y=pct_in_zone
    title="Time in HR Zones"
    yAxisTitle="% of Time"
/>

<DataTable data={hr_zones}>
    <Column id=zone_name title="Zone"/>
    <Column id=zone_min_bpm title="Min BPM"/>
    <Column id=zone_max_bpm title="Max BPM"/>
    <Column id=seconds_in_zone title="Seconds"/>
    <Column id=pct_in_zone title="% Time" fmt="#,##0.1"/>
</DataTable>

{:else}

## Heart Rate Zones

*No heart rate zone data available for this activity.*

{/if}

{#if power_zones.length > 0}

## Power Zones

<BarChart
    data={power_zones}
    x=zone_name
    y=pct_in_zone
    title="Time in Power Zones"
    yAxisTitle="% of Time"
/>

<DataTable data={power_zones}>
    <Column id=zone_name title="Zone"/>
    <Column id=zone_min_watts title="Min Watts"/>
    <Column id=zone_max_watts title="Max Watts"/>
    <Column id=seconds_in_zone title="Seconds"/>
    <Column id=pct_in_zone title="% Time" fmt="#,##0.1"/>
</DataTable>

{:else}

## Power Zones

*No power zone data available for this activity.*

{/if}

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
