---
title: Hike
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
where sport_type = 'Hike'
order by started_at desc
```

```sql monthly_stats
select
    month_label,
    activity_count,
    total_distance_km,
    total_elevation_meters
from strava.activity_monthly_sport
where sport_type = 'Hike'
order by month_start desc
```

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
    y=total_elevation_meters
    title="Monthly Elevation Gain (m)"
/>

## All Hikes

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_km title="Distance (km)"/>
    <Column id=moving_time_minutes title="Duration (min)"/>
    <Column id=elevation_gain_meters title="Elevation (m)"/>
</DataTable>

[Back to Activities](/activity)
