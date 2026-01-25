---
title: Activities
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

```sql home_trends_12mo
select
    month_label,
    activity_count,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet
from strava.home_trends_12mo
order by month_start
```

```sql home_streaks
select
    current_streak,
    longest_streak,
    active_days_last_30
from strava.home_streaks
```

```sql sport_summary
select
    sport_type,
    activity_count,
    total_moving_time_hours,
    total_distance_km,
    sport_slug
from strava.activities_by_sport
order by activity_count desc
```

```sql recent_activities
select
    activity_id,
    activity_name,
    sport_type,
    started_at,
    distance_miles,
    moving_time_minutes,
    average_speed_mph,
    pace_min_per_km,
    activity_link
from strava.activity_list
order by started_at desc
limit 20
```

# All Activities

## Overview

<BigValue
    data={home_kpis}
    value=total_activity_count
    title="Total Activities"
    fmt="#,##0"
/>

<BigValue
    data={home_kpis}
    value=total_distance_miles
    title="Total Distance (mi)"
    fmt="#,##0.0"
/>

<BigValue
    data={home_kpis}
    value=total_moving_time_hours
    title="Total Time (hrs)"
    fmt="#,##0"
/>

<BigValue
    data={home_kpis}
    value=total_elevation_gain_feet
    title="Elevation Gain (ft)"
    fmt="#,##0"
/>

<BigValue
    data={home_kpis}
    value=avg_speed_mph
    title="Avg Speed (mph)"
    fmt="#,##0.0"
/>

## Momentum

<BigValue
    data={home_streaks}
    value=current_streak
    title="Current Streak (days)"
    fmt="#,##0"
/>

<BigValue
    data={home_streaks}
    value=longest_streak
    title="Longest Streak (days)"
    fmt="#,##0"
/>

<BigValue
    data={home_streaks}
    value=active_days_last_30
    title="Active Days (last 30)"
    fmt="#,##0"
/>

## Monthly Trends

<LineChart
    sort={false}
    xGridlines={false}
    yGridlines={false}
    data={home_trends_12mo}
    x=month_label
    y=total_distance_miles
    title="Monthly Distance (mi)"
/>

<LineChart
    data={home_trends_12mo}
    sort={false}
    xGridlines={false}
    yGridlines={false}
    x=month_label
    y=total_moving_time_hours
    title="Monthly Time (hrs)"
/>

<BarChart
    sort={false}
    xGridlines={false}
    yGridlines={false}
    data={home_trends_12mo}
    x=month_label
    y=activity_count
    title="Monthly Activity Count"
/>

## By Sport Type

{#each sport_summary as sport}

### [{sport.sport_type}](/activity/{sport.sport_slug})

**{sport.activity_count}** activities | **{sport.total_moving_time_hours}** hours | **{sport.total_distance_km}** km

{/each}

## Recent Activities

<DataTable data={recent_activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=sport_type title="Sport"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_miles title="Distance (mi)"/>
    <Column id=moving_time_minutes title="Duration (min)"/>
    <Column id=average_speed_mph title="Avg Speed (mph)"/>
</DataTable>
