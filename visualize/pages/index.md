---
title: Strava Dashboard
---

```sql home_kpis
select
    total_activity_count,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_mph
from strava.home_kpis
```

```sql sport_mix
select
    sport_type,
    activity_count,
    total_distance_miles,
    total_moving_time_hours
from strava.sport_mix
```

```sql distinct_years
select
    activity_year,
    max_year
from strava.distinct_years
order by activity_year desc
```

```sql activity_list
select
    activity_id,
    activity_name,
    sport_type,
    started_at_local,
    distance_miles,
    moving_time_seconds,
    elevation_gain_feet,
    activity_link
from strava.activity_list
limit 10
```

## Overview

<BigValue
    data={home_kpis}
    value=total_activity_count
    title="Total Activities"
/>

<BigValue
    data={home_kpis}
    value=total_distance_miles
    title="Total Distance (mi)"
    fmt='#,##0.0'
/>

<BigValue
    data={home_kpis}
    value=total_moving_time_hours
    title="Total Time (hrs)"
    fmt='#,##0'
/>

<BigValue
    data={home_kpis}
    value=total_elevation_gain_feet
    title="Total Elevation (ft)"
    fmt='#,##0'
/>

<BigValue
    data={home_kpis}
    value=avg_speed_mph
    title="Avg Speed (mph)"
    fmt='#,##0.1'
/>

### Activity Trends

<Dropdown
    name=trend_year_filter
    data={distinct_years}
    value=activity_year
    defaultValue={distinct_years[0].max_year}
    order=activity_year desc
    title="Select Year"
/>

```sql filtered_daily_trends
select
    activity_date,
    activity_year,
    activity_count,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_mph
from strava.home_daily_trends
where activity_year = ${inputs.trend_year_filter.value}
```

### Activities by Sport

<BarChart
    data={sport_mix}
    x=sport_type
    y=total_distance_miles
    title="Distance by Sport"
    yAxisTitle="Distance (mi)"
    fmt='#,##0.0'
/>

## Recent Activities

<DataTable
    data={activity_list}
    link=activity_link
>
    <Column id=activity_name title="Activity"/>
    <Column id=sport_type title="Sport"/>
    <Column id=started_at_local title="Date" fmt="mmm d, yyyy"/>
    <Column id=distance_miles title="Distance (mi)" fmt="#,##0.1"/>
    <Column id=moving_time_seconds title="Time"/>
    <Column id=elevation_gain_feet title="Elev (ft)" fmt="#,##0"/>
</DataTable>

<StravaBadge />
