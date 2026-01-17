---
title: Strava Dashboard
---

```sql activities_by_sport
select * from strava.activities_by_sport
```

```sql total_activities
select sum(activity_count) as total_count from strava.activities_by_sport
```

```sql daily_activity_counts
select
    *,
    year(activity_date) as activity_year
from strava.daily_activity_counts
```

```sql distinct_years
select distinct year(activity_date) as activity_year
from strava.daily_activity_counts
order by activity_year desc
```

## Overview

<BigValue
    data={total_activities}
    value=total_count
    title="Total Activities"
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

<ButtonGroup
    name=year_filter
    data={distinct_years}
    value=activity_year
    title="Select Year"
/>

<CalendarHeatmap
    data={daily_activity_counts}
    date=activity_date
    value=activity_count
    title="Activity Heatmap"
    filters={['year_filter']}
/>
