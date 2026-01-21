---
title: Run
---

```sql activities
select
    activity_id,
    activity_name,
    '/activity/run/' || activity_id as activity_link,
    started_at,
    round(distance / 1000.0, 2) as distance_km,
    round(moving_seconds / 60.0, 0) as duration_min,
    round((moving_seconds / 60.0) / (distance / 1000.0), 2) as pace_min_km,
    hr_avg
from strava.activity_list
where sport_type = 'Run'
order by started_at desc
```

```sql monthly_stats
select
    strftime(started_at, '%Y-%m') as month,
    count(*) as runs,
    round(sum(distance) / 1000.0, 1) as total_km,
    round(avg(hr_avg), 0) as avg_hr
from strava.activity_list
where sport_type = 'Run'
group by strftime(started_at, '%Y-%m')
order by month desc
```

# Run Activities

## Monthly Trends

<LineChart
    data={monthly_stats}
    x=month
    y=total_km
    title="Monthly Distance (km)"
/>

<BarChart
    data={monthly_stats}
    x=month
    y=runs
    title="Monthly Run Count"
/>

## All Runs

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_km title="Distance (km)"/>
    <Column id=duration_min title="Duration (min)"/>
    <Column id=pace_min_km title="Pace (min/km)"/>
    <Column id=hr_avg title="Avg HR"/>
</DataTable>

[Back to Activities](/activity)