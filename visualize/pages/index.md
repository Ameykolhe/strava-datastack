---
title: Strava Dashboard
---

```sql activities_by_sport
select * from strava.activities_by_sport
```

```sql activity_summary
select * from strava.activity_summary
```

```sql daily_activity_counts
select
    *,
    year(activity_date) as activity_year
from strava.daily_activity_counts
```

```sql distinct_years
select * from strava.distinct_years
```

## Overview

<BigValue
    data={activity_summary}
    value=total_activities
    title="Total Activities"
/>

<BigValue
    data={activity_summary}
    value=total_active_days
    title="Active Days"
/>

<BigValue
    data={activity_summary}
    value=total_hours
    title="Total Time (hrs)"
    fmt='#,##0'
/>

<BigValue
    data={activity_summary}
    value=total_distance_miles
    title="Total Distance (mi)"
    fmt='#,##0.0'
/>

<BigValue
    data={activity_summary}
    value=total_elevation_gain_feet
    title="Total Elevation Gain (ft)"
    fmt='#,##0'
/>

### Activities by Sport

<EChartsPie
    data={activities_by_sport}
    x=sport_type
    y=activity_count
    labels=true
    title="Activity Count by Sport"
/>

## Activity Calendar

<Dropdown
    name=year_filter
    data={distinct_years}
    value=activity_year
    defaultValue={distinct_years[0].max_year}
    order=activity_year desc
    title="Select Year"
/>

```sql filtered_daily_activity_counts
select *
from ${daily_activity_counts}
where activity_year = ${inputs.year_filter.value}
```

<CalendarHeatmap
    data={filtered_daily_activity_counts}
    date=activity_date
    value=activity_count
    title="Activity Heatmap"
/>
