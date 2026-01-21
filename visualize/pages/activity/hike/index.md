---
title: Hike
---

```sql activities
select
    activity_id,
    activity_name,
    '/activity/hike/' || activity_id as activity_link,
    started_at,
    round(distance / 1000.0, 2) as distance_km,
    round(moving_seconds / 60.0, 0) as duration_min,
    round(elevation_gain, 0) as elevation_m
from strava.activity_list
where sport_type = 'Hike'
order by started_at desc
```

```sql monthly_stats
select
    strftime(started_at, '%Y-%m') as month,
    count(*) as hikes,
    round(sum(distance) / 1000.0, 1) as total_km,
    round(sum(elevation_gain), 0) as total_elevation
from strava.activity_list
where sport_type = 'Hike'
group by strftime(started_at, '%Y-%m')
order by month desc
```

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
    y=total_elevation
    title="Monthly Elevation Gain (m)"
/>

## All Hikes

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_km title="Distance (km)"/>
    <Column id=duration_min title="Duration (min)"/>
    <Column id=elevation_m title="Elevation (m)"/>
</DataTable>

[Back to Activities](/activity)