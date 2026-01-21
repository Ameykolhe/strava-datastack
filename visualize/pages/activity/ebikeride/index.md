---
title: E-Bike Ride
---

```sql activities
select
    activity_id,
    activity_name,
    '/activity/ebikeride/' || activity_id as activity_link,
    started_at,
    round(distance / 1000.0, 1) as distance_km,
    round(moving_seconds / 60.0, 0) as duration_min,
    round(elevation_gain, 0) as elevation_m,
    round((distance / moving_seconds) * 3.6, 1) as speed_kmh
from strava.activity_list
where sport_type = 'EBikeRide' and moving_seconds > 0
order by started_at desc
```

```sql monthly_stats
select
    strftime(started_at, '%Y-%m') as month,
    count(*) as rides,
    round(sum(distance) / 1000.0, 0) as total_km,
    round(sum(elevation_gain), 0) as total_elevation
from strava.activity_list
where sport_type = 'EBikeRide'
group by strftime(started_at, '%Y-%m')
order by month desc
```

# E-Bike Ride Activities

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
    y=rides
    title="Monthly Ride Count"
/>

## All E-Bike Rides

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_km title="Distance (km)"/>
    <Column id=duration_min title="Duration (min)"/>
    <Column id=elevation_m title="Elevation (m)"/>
    <Column id=speed_kmh title="Avg Speed (km/h)"/>
</DataTable>

[Back to Activities](/activity)