---
title: Run
---

```sql activities
select
    activity_id,
    activity_name,
    started_at,
    distance_km,
    moving_time_minutes,
    pace_min_per_km,
    average_heartrate_bpm,
    activity_link
from strava.activity_list
where sport_type = 'Run'
order by started_at desc
```

```sql monthly_stats
select
    month_label,
    activity_count,
    total_distance_km,
    avg_heartrate_bpm
from strava.activity_monthly_sport
where sport_type = 'Run'
order by month_start desc
```

# Run Activities

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
    title="Monthly Run Count"
/>

## All Runs

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_km title="Distance (km)"/>
    <Column id=moving_time_minutes title="Duration (min)"/>
    <Column id=pace_min_per_km title="Pace (min/km)"/>
    <Column id=average_heartrate_bpm title="Avg HR"/>
</DataTable>

[Back to Activities](/activity)
