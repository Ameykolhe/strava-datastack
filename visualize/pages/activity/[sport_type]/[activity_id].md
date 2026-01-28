---
title: Activity Details
---

<script>
  import ActivityRouteMap from '../../../../components/activity/ActivityRouteMap.svelte';
  import ActivityDetailsTable from '../../../../components/activity/detail/ActivityDetailsTable.svelte';
  import ActivityHeartRateTable from '../../../../components/activity/detail/ActivityHeartRateTable.svelte';
  import ActivityPowerTable from '../../../../components/activity/detail/ActivityPowerTable.svelte';
  import ActivityStravaStatsTable from '../../../../components/activity/detail/ActivityStravaStatsTable.svelte';
</script>

```sql q_activity_detail__activity
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
from strava.src_strava__activity_list
where activity_id = CAST('${params.activity_id}' AS BIGINT)
```

```sql q_activity_detail__hr_zones
select
    activity_id,
    zone_id,
    zone_name,
    zone_min_bpm,
    zone_max_bpm,
    time_seconds,
    time_minutes,
    pct_in_zone
from strava.src_strava__activity_hr_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

```sql q_activity_detail__power_zones
select
    activity_id,
    zone_id,
    zone_name,
    zone_min_watts,
    zone_max_watts,
    time_seconds,
    time_minutes,
    pct_in_zone
from strava.src_strava__activity_power_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

```sql q_activity_detail__pace_zones
select
    activity_id,
    zone_id,
    zone_name,
    zone_min_pace,
    zone_max_pace,
    zone_min_pace_sec,
    zone_max_pace_sec,
    time_seconds,
    time_minutes,
    pct_in_zone
from strava.src_strava__activity_pace_zones
where activity_id = CAST('${params.activity_id}' AS BIGINT)
order by zone_id
```

{#if q_activity_detail__activity.length > 0}

# {q_activity_detail__activity[0].activity_name}

**{q_activity_detail__activity[0].sport_type}** on {q_activity_detail__activity[0].started_at_local}

## Summary

<BigValue
    data={q_activity_detail__activity}
    value=distance_miles
    title="Distance (mi)"
    fmt='#,##0.00'
/>

<BigValue
    data={q_activity_detail__activity}
    value=moving_time_seconds
    title="Moving Time"
/>

<BigValue
    data={q_activity_detail__activity}
    value=elevation_gain_feet
    title="Elevation (ft)"
    fmt='#,##0'
/>

<BigValue
    data={q_activity_detail__activity}
    value=average_speed_mph
    title="Avg Speed (mph)"
    fmt='#,##0.0'
/>

{#if q_activity_detail__activity[0].average_heartrate_bpm != null}
<BigValue
    data={q_activity_detail__activity}
    value=average_heartrate_bpm
    title="Avg HR (bpm)"
    fmt='#,##0'
/>
{/if}

{#if q_activity_detail__activity[0].average_watts != null}
<BigValue
    data={q_activity_detail__activity}
    value=average_watts
    title="Avg Power (W)"
    fmt='#,##0'
/>
{/if}

{#if q_activity_detail__activity[0].map_summary_polyline}

## Route Map

<ActivityRouteMap
    polyline={q_activity_detail__activity[0].map_summary_polyline}
    height={400}
/>

{/if}

## Details

<ActivityDetailsTable activityData={q_activity_detail__activity} />

{#if q_activity_detail__activity[0].average_heartrate_bpm != null}

### Heart Rate

<ActivityHeartRateTable activityData={q_activity_detail__activity} />

{/if}

{#if q_activity_detail__activity[0].average_watts != null}

### Power

<ActivityPowerTable activityData={q_activity_detail__activity} />

{/if}

{#if q_activity_detail__hr_zones.length > 0 || q_activity_detail__power_zones.length > 0 || q_activity_detail__pace_zones.length > 0}
## Zone Distribution

{#if q_activity_detail__hr_zones.length > 0}
### Heart Rate Zones

<div class="zone-split">
    <BarChart
        data={q_activity_detail__hr_zones}
        x=zone_name
        y=pct_in_zone
        sort={false}
        yMin={0}
        yMax={1}
        yFmt="0%"
        chartAreaHeight={220}
        yAxisLabels={false}
        xGridlines={false}
        yGridlines={false}
        echartsOptions={{
            grid: {
                bottom: 70
            },
            xAxis: {
                axisLabel: {
                    rotate: 90,
                    margin: 12
                }
            }
        }}
    />
    <div>
        <DataTable data={q_activity_detail__hr_zones} rows={5}>
            <Column id=zone_name title="Zone"/>
            <Column id=zone_min_bpm title="Min (bpm)" fmt="#,##0"/>
            <Column id=zone_max_bpm title="Max (bpm)" fmt="#,##0"/>
        </DataTable>
    </div>
</div>
{/if}

{#if q_activity_detail__power_zones.length > 0}
### Power Zones

<div class="zone-split">
    <BarChart
        data={q_activity_detail__power_zones}
        x=zone_name
        y=pct_in_zone
        sort={false}
        yMin={0}
        yMax={1}
        yFmt="0%"
        chartAreaHeight={220}
        yAxisLabels={false}
        xGridlines={false}
        yGridlines={false}
        echartsOptions={{
            grid: {
                bottom: 70
            },
            xAxis: {
                axisLabel: {
                    rotate: 90,
                    margin: 12
                }
            }
        }}
    />
    <div>
        <DataTable data={q_activity_detail__power_zones} rows={5}>
            <Column id=zone_name title="Zone"/>
            <Column id=zone_min_watts title="Min (W)" fmt="#,##0"/>
            <Column id=zone_max_watts title="Max (W)" fmt="#,##0"/>
        </DataTable>
    </div>
</div>
{/if}

{#if q_activity_detail__pace_zones.length > 0}
### Pace Zones

<div class="zone-split">
    <BarChart
        data={q_activity_detail__pace_zones}
        x=zone_name
        y=pct_in_zone
        sort={false}
        yMin={0}
        yMax={1}
        yFmt="0%"
        chartAreaHeight={220}
        yAxisLabels={false}
        xGridlines={false}
        yGridlines={false}
        echartsOptions={{
            grid: {
                bottom: 70
            },
            xAxis: {
                axisLabel: {
                    rotate: 90,
                    margin: 12
                }
            }
        }}
    />
    <div>
        <DataTable data={q_activity_detail__pace_zones} rows={5}>
            <Column id=zone_name title="Zone"/>
            <Column id=zone_min_pace title="Min (/km)"/>
            <Column id=zone_max_pace title="Max (/km)"/>
        </DataTable>
    </div>
</div>
{/if}

<style>
  .zone-split {
    display: grid;
    grid-template-columns: minmax(0, 7fr) minmax(0, 3fr);
    gap: 16px;
    align-items: start;
  }

  @media (max-width: 900px) {
    .zone-split {
      grid-template-columns: minmax(0, 1fr);
    }
  }
</style>

{/if}

### Strava Stats

<ActivityStravaStatsTable activityData={q_activity_detail__activity} />

{:else}

# Activity Not Found

The activity with ID **{params.activity_id}** was not found.

{/if}
