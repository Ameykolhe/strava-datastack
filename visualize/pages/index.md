---
title: Strava Dashboard
---

```sql q_home__kpis_alltime
select
    activity_count,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_mph
from strava.src_strava__kpis_all
```

```sql q_home__sport_mix
select
    sport_type,
    activity_count,
    total_distance_miles,
    total_moving_time_hours
from strava.src_strava__kpis_sport_type
```

```sql q_home__distinct_years
select
    activity_year,
    max_year
from strava.src_strava__distinct_years
order by activity_year desc
```

```sql q_home__recent_activities
select
    activity_id,
    activity_name,
    sport_type,
    started_at_local,
    distance_miles,
    moving_time_seconds,
    elevation_gain_feet,
    activity_link
from strava.src_strava__activity_list
limit 10
```

## Overview

<BigValue
    data={q_home__kpis_alltime}
    value=activity_count
    title="Total Activities"
/>

<BigValue
    data={q_home__kpis_alltime}
    value=total_distance_miles
    title="Total Distance (mi)"
    fmt='#,##0.0'
/>

<BigValue
    data={q_home__kpis_alltime}
    value=total_moving_time_hours
    title="Total Time (hrs)"
    fmt='#,##0'
/>

<BigValue
    data={q_home__kpis_alltime}
    value=total_elevation_gain_feet
    title="Total Elevation (ft)"
    fmt='#,##0'
/>

<BigValue
    data={q_home__kpis_alltime}
    value=avg_speed_mph
    title="Avg Speed (mph)"
    fmt='#,##0.1'
/>

### Activity Trends

<Dropdown
    name=trend_year_filter
    data={q_home__distinct_years}
    value=activity_year
    defaultValue={q_home__distinct_years[0].max_year}
    order=activity_year desc
    title="Select Year"
/>

### Activities by Sport

<BarChart
    data={q_home__sport_mix}
    x=sport_type
    y=total_distance_miles
    title="Distance by Sport"
    yAxisTitle="Distance (mi)"
    fmt='#,##0.0'
/>

## Recent Activities

<DataTable
    data={q_home__recent_activities}
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
