---
title: Year in Sports
sidebar_link: false
---

```sql year_kpis
select
    activity_year,
    activity_count,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    longest_distance_miles,
    hardest_elevation_gain_feet
from strava.year_kpis
where activity_year = ${params.year}
```

```sql year_monthly
select
    activity_year,
    month_start,
    month_number,
    month_name,
    activity_count,
    total_distance_miles,
    total_elevation_gain_feet
from strava.year_monthly
where activity_year = ${params.year}
order by month_number
```

```sql year_calendar
select
    activity_date,
    activity_count
from strava.home_daily_trends
where activity_year = ${params.year}
order by activity_date
```

```sql distinct_years
select
    activity_year,
    max_year
from strava.distinct_years
order by activity_year desc
```

```sql year_activities
select
    activity_id,
    activity_name,
    sport_type,
    started_at,
    started_at_local,
    distance_miles,
    moving_time_seconds,
    elevation_gain_feet,
    activity_link,
    activity_year
from strava.activity_list
where activity_year = ${params.year}
order by started_at desc
```

```sql year_routes
select
    activity_year,
    polylines
from strava.year_routes
where activity_year = ${params.year}
```

# {params.year} Review

<BigValue
    data={year_kpis}
    value=activity_count
    title="Activities"
/>

<BigValue
    data={year_kpis}
    value=total_distance_miles
    title="Distance (mi)"
    fmt='#,##0.0'
/>

<BigValue
    data={year_kpis}
    value=total_moving_time_hours
    title="Time (hrs)"
    fmt='#,##0'
/>

<BigValue
    data={year_kpis}
    value=total_elevation_gain_feet
    title="Elevation (ft)"
    fmt='#,##0'
/>

<BigValue
    data={year_kpis}
    value=longest_distance_miles
    title="Longest (mi)"
    fmt='#,##0.1'
/>

<BigValue
    data={year_kpis}
    value=hardest_elevation_gain_feet
    title="Most Elev (ft)"
    fmt='#,##0'
/>

## Activity Calendar

<CalendarHeatmap
    data={year_calendar}
    date=activity_date
    value=activity_count
    min=0
    max=5
    legend=false
/>

## Monthly Trends

<hr>

<BarChart
    data={year_monthly}
    x=month_name
    xType=category
    sort=false
    y=activity_count
    title="Activities by Month"
    yAxisTitle="Activities"
/>

<hr>

<LineChart
    data={year_monthly}
    x=month_name
    xType=category
    sort=false
    y=total_distance_miles
    title="Distance by Month"
    yAxisTitle="Distance (mi)"
/>

<hr>

<BarChart
    data={year_monthly}
    x=month_name
    xType=category
    sort=false
    y=total_elevation_gain_feet
    title="Elevation by Month"
    yAxisTitle="Elevation (ft)"
/>

## Activity Heatmap

{#if year_routes.length > 0 && year_routes[0].polylines}

<ActivityHeatmap
polylines={year_routes[0].polylines}
height={500}
/>

{:else}

No routes available to display for this year.

{/if}
