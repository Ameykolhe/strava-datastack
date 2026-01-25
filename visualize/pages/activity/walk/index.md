---
title: Walk
---

```sql sport_kpis
select
    sport_type,
    activity_count,
    total_distance_km,
    total_moving_time_hours,
    total_elevation_meters,
    avg_speed_kmh,
    avg_heartrate_bpm
from strava.sport_kpis
where sport_type = 'Walk'
```

```sql monthly_stats
select
    month_label,
    activity_count,
    total_distance_km,
    total_moving_time_hours
from strava.sport_trends_12mo
where sport_type = 'Walk'
order by month_start
```

```sql activities
select
    activity_id,
    activity_name,
    started_at,
    distance_km,
    moving_time_minutes,
    elevation_gain_meters,
    activity_link
from strava.activity_list
where sport_type = 'Walk'
order by started_at desc
```

# Walk Activities

## Overview

<BigValue
    data={sport_kpis}
    value=activity_count
    title="Total Walks"
    fmt="#,##0"
/>

<BigValue
    data={sport_kpis}
    value=total_distance_km
    title="Total Distance (km)"
    fmt="#,##0.0"
/>

<BigValue
    data={sport_kpis}
    value=total_moving_time_hours
    title="Total Time (hrs)"
    fmt="#,##0.0"
/>

<BigValue
    data={sport_kpis}
    value=total_elevation_meters
    title="Elevation Gain (m)"
    fmt="#,##0"
/>

<BigValue
    data={sport_kpis}
    value=avg_speed_kmh
    title="Avg Speed (km/h)"
    fmt="#,##0.0"
/>

{#if sport_kpis.length > 0 && sport_kpis[0].avg_heartrate_bpm != null}
<BigValue
    data={sport_kpis}
    value=avg_heartrate_bpm
    title="Avg HR (bpm)"
    fmt="#,##0"
/>
{/if}

## Monthly Trends

<LineChart
    sort={false}
    xGridlines={false}
    yGridlines={false}
    connectGroup="monthly-trends"
    echartsOptions={{
        dataZoom: [
            {
                type: 'inside',
                xAxisIndex: 0,
                zoomLock: true,
                zoomOnMouseWheel: false,
                zoomOnMouseMove: false,
                moveOnMouseWheel: true,
                moveOnMouseMove: true,
                startValue: monthly_stats.length > 12 ? monthly_stats[monthly_stats.length - 12]?.month_label : monthly_stats[0]?.month_label,
                endValue: monthly_stats[monthly_stats.length - 1]?.month_label
            },
            {
                type: 'slider',
                xAxisIndex: 0,
                zoomLock: true,
                height: 16,
                bottom: 0,
                showDetail: false,
                startValue: monthly_stats.length > 12 ? monthly_stats[monthly_stats.length - 12]?.month_label : monthly_stats[0]?.month_label,
                endValue: monthly_stats[monthly_stats.length - 1]?.month_label
            }
        ]
    }}
    data={monthly_stats}
    x=month_label
    y=total_distance_km
    title="Monthly Distance (km)"
/>

<BarChart
    sort={false}
    xGridlines={false}
    yGridlines={false}
    connectGroup="monthly-trends"
    echartsOptions={{
        dataZoom: [
            {
                type: 'inside',
                xAxisIndex: 0,
                zoomLock: true,
                zoomOnMouseWheel: false,
                zoomOnMouseMove: false,
                moveOnMouseWheel: true,
                moveOnMouseMove: true,
                startValue: monthly_stats.length > 12 ? monthly_stats[monthly_stats.length - 12]?.month_label : monthly_stats[0]?.month_label,
                endValue: monthly_stats[monthly_stats.length - 1]?.month_label
            },
            {
                type: 'slider',
                xAxisIndex: 0,
                zoomLock: true,
                height: 16,
                bottom: 0,
                showDetail: false,
                startValue: monthly_stats.length > 12 ? monthly_stats[monthly_stats.length - 12]?.month_label : monthly_stats[0]?.month_label,
                endValue: monthly_stats[monthly_stats.length - 1]?.month_label
            }
        ]
    }}
    data={monthly_stats}
    x=month_label
    y=total_moving_time_hours
    title="Monthly Time (hrs)"
/>

## All Walks

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_km title="Distance (km)"/>
    <Column id=moving_time_minutes title="Duration (min)"/>
    <Column id=elevation_gain_meters title="Elevation (m)"/>
</DataTable>

[Back to Activities](/activity)
