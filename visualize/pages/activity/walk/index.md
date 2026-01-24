---
title: Walk
---

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

```sql monthly_stats
select
    month_label,
    activity_count,
    total_distance_km,
    total_moving_time_hours
from strava.activity_monthly_sport
where sport_type = 'Walk'
order by month_start desc
```

# Walk Activities

## Monthly Trends

<LineChart
    data={monthly_stats}
    x=month_label
    y=total_distance_km
    title="Monthly Distance (km)"
/>

<BarChart
    data={monthly_stats}
    x=month_label
    y=total_moving_time_hours
    title="Monthly Walking Time (hours)"
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
