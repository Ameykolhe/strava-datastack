---
title: Walk
---

```sql activities
select
    activity_id,
    activity_name,
    '/activity/walk/' || activity_id as activity_link,
    started_at,
    round(distance / 1000.0, 2) as distance_km,
    round(moving_seconds / 60.0, 0) as duration_min,
    round(elevation_gain, 0) as elevation_m
from strava.activity_list
where sport_type = 'Walk'
order by started_at desc
```

```sql monthly_stats
select
    strftime(started_at, '%Y-%m') as month,
    count(*) as walks,
    round(sum(distance) / 1000.0, 1) as total_km,
    round(sum(moving_seconds) / 3600.0, 1) as total_hours
from strava.activity_list
where sport_type = 'Walk'
group by strftime(started_at, '%Y-%m')
order by month desc
```

# Walk Activities

## Monthly Trends

<LineChart
    data={monthly_stats}
    x=month
    y=total_km
    title="Monthly Distance (km)"
/>

<BarChart
    data={monthly_stats}
    x=month
    y=total_hours
    title="Monthly Walking Time (hours)"
/>

## All Walks

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_km title="Distance (km)"/>
    <Column id=duration_min title="Duration (min)"/>
    <Column id=elevation_m title="Elevation (m)"/>
</DataTable>

[Back to Activities](/activity)