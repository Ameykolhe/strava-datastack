---
title: E-Bike Ride
---

```sql activities
select
    activity_id,
    activity_name,
    started_at,
    distance_km,
    moving_time_minutes,
    elevation_gain_meters,
    average_speed_kph,
    activity_link
from strava.activity_list
where sport_type = 'EBikeRide' and moving_time_seconds > 0
order by started_at desc
```

```sql monthly_stats
select
    month_label,
    activity_count,
    total_distance_km,
    total_elevation_meters
from strava.activity_monthly_sport
where sport_type = 'EBikeRide'
order by month_start desc
```

# E-Bike Ride Activities

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
    y=activity_count
    title="Monthly Ride Count"
/>

## All E-Bike Rides

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_km title="Distance (km)"/>
    <Column id=moving_time_minutes title="Duration (min)"/>
    <Column id=elevation_gain_meters title="Elevation (m)"/>
    <Column id=average_speed_kph title="Avg Speed (km/h)"/>
</DataTable>

[Back to Activities](/activity)
