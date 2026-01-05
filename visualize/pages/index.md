---
title: Strava Activity Dashboard
---

# Strava Activity Dashboard

## Overall Statistics

```sql stats
select * from strava.activity_stats
```

<Grid cols=4>
    <BigValue
        data={stats}
        value=total_activities
        title="Total Activities"
    />
    <BigValue
        data={stats}
        value=total_distance_km
        fmt='#,##0.0'
        title="Total Distance (km)"
    />
    <BigValue
        data={stats}
        value=total_moving_hours
        fmt='#,##0.0'
        title="Total Moving Hours"
    />
    <BigValue
        data={stats}
        value=total_kudos
        fmt='#,##0'
        title="Total Kudos"
    />
</Grid>

## Activity Breakdown by Type

```sql by_type
select * from strava.activity_by_type
```

<Grid cols=2>
    <BarChart
        data={by_type}
        title="Activities by Sport Type"
        x=sport_type
        y=activity_count
    />
    <BarChart
        data={by_type}
        title="Total Distance by Sport Type (km)"
        x=sport_type
        y=total_distance_km
    />
</Grid>

## Monthly Activity Trends

```sql monthly
select * from strava.monthly_trends
```

<LineChart
    data={monthly}
    title="Monthly Activity Count by Sport"
    x=month
    y=activity_count
    series=sport_type
/>

<LineChart
    data={monthly}
    title="Monthly Distance (km) by Sport"
    x=month
    y=total_distance_km
    series=sport_type
/>

## Recent Activities

```sql recent
select
    name,
    sport_type,
    start_date_local,
    distance_km,
    moving_time_minutes,
    elevation_gain_meters,
    avg_speed_kmh,
    average_heartrate,
    kudos_count
from strava.activities_overview
limit 20
```

<DataTable data={recent}>
    <Column id=name/>
    <Column id=sport_type/>
    <Column id=start_date_local fmt='yyyy-MM-dd HH:mm'/>
    <Column id=distance_km fmt='#,##0.00'/>
    <Column id=moving_time_minutes fmt='#,##0.0'/>
    <Column id=elevation_gain_meters fmt='#,##0'/>
    <Column id=avg_speed_kmh fmt='#,##0.0'/>
    <Column id=average_heartrate fmt='#,##0'/>
    <Column id=kudos_count/>
</DataTable>