---
title: Workout
---

```sql activities
select
    activity_id,
    activity_name,
    started_at,
    moving_time_minutes,
    average_heartrate_bpm,
    activity_link
from strava.activity_list
where sport_type = 'Workout'
order by started_at desc
```

```sql monthly_stats
select
    month_label,
    activity_count,
    total_moving_time_hours,
    avg_heartrate_bpm
from strava.activity_monthly_sport
where sport_type = 'Workout'
order by month_start desc
```

# Workout Activities

## Monthly Trends

<BarChart
    data={monthly_stats}
    x=month_label
    y=activity_count
    title="Monthly Workout Count"
/>

<LineChart
    data={monthly_stats}
    x=month_label
    y=total_moving_time_hours
    title="Monthly Workout Time (hours)"
/>

## All Workouts

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=moving_time_minutes title="Duration (min)"/>
    <Column id=average_heartrate_bpm title="Avg HR"/>
</DataTable>

[Back to Activities](/activity)
