---
title: Workout
---

```sql sport_kpis
select
    sport_type,
    activity_count,
    total_distance_km,
    total_moving_time_hours,
    avg_heartrate_bpm
from strava.sport_kpis
where sport_type = 'Workout'
```

```sql monthly_stats
select
    month_label,
    activity_count,
    total_moving_time_hours,
    avg_heartrate_bpm
from strava.sport_trends_12mo
where sport_type = 'Workout'
order by month_start
```

```sql activities
select
    activity_id,
    activity_name,
    started_at,
    moving_time_minutes,
    average_heartrate_bpm,
    distance_km,
    activity_link
from strava.activity_list
where sport_type = 'Workout'
order by started_at desc
```

# Workout Activities

## Overview

<BigValue
    data={sport_kpis}
    value=activity_count
    title="Total Sessions"
    fmt="#,##0"
/>

<BigValue
    data={sport_kpis}
    value=total_moving_time_hours
    title="Total Time (hrs)"
    fmt="#,##0.0"
/>

{#if sport_kpis.length > 0 && sport_kpis[0].total_distance_km > 0}
<BigValue
    data={sport_kpis}
    value=total_distance_km
    title="Total Distance (km)"
    fmt="#,##0.0"
/>
{/if}

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
    y=total_moving_time_hours
    title="Monthly Time (hrs)"
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
    y=activity_count
    title="Monthly Session Count"
/>

## All Workouts

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=moving_time_minutes title="Duration (min)"/>
    <Column id=average_heartrate_bpm title="Avg HR"/>
    <Column id=distance_km title="Distance (km)"/>
</DataTable>

[Back to Activities](/activity)
