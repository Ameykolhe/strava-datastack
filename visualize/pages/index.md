---
title: Strava Dashboard
---

```sql home_kpis
select * from strava.home_kpis
```

```sql home_daily_trends
select
    *,
    year(activity_date) as activity_year
from strava.home_daily_trends
```

```sql sport_mix
select * from strava.sport_mix
```

```sql distinct_years
select * from strava.distinct_years
```

```sql activity_list
select * from strava.activity_list
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
    value=total_distance
    title="Total Distance (mi)"
    fmt='#,##0.0'
/>

<BigValue
    data={home_kpis}
    value=total_moving_time
    title="Total Time (hrs)"
    fmt='#,##0'
/>

<BigValue
    data={home_kpis}
    value=total_elevation_gain
    title="Total Elevation (ft)"
    fmt='#,##0'
/>

<BigValue
    data={home_kpis}
    value=avg_speed
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
select *
from ${home_daily_trends}
where activity_year = ${inputs.trend_year_filter.value}
```

### Activities by Sport

<EChartsPie
    data={sport_mix}
    x=sport_type
    y=activity_count
    labels=true
    title="Activity Count by Sport"
/>

<BarChart
    data={sport_mix}
    x=sport_type
    y=total_distance
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
    <Column id=distance title="Distance (mi)" fmt="#,##0.1"/>
    <Column id=moving_seconds title="Time"/>
    <Column id=elevation_gain title="Elev (ft)" fmt="#,##0"/>
</DataTable>
