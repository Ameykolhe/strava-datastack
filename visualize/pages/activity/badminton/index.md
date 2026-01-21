---
title: Badminton
---

```sql activities
select
    activity_id,
    activity_name,
    '/activity/badminton/' || activity_id as activity_link,
    started_at,
    round(moving_seconds / 60.0, 0) as duration_min,
    hr_avg
from strava.activity_list
where sport_type = 'Badminton'
order by started_at desc
```

```sql monthly_stats
select
    strftime(started_at, '%Y-%m') as month,
    count(*) as sessions,
    round(sum(moving_seconds) / 3600.0, 1) as total_hours,
    round(avg(hr_avg), 0) as avg_hr
from strava.activity_list
where sport_type = 'Badminton'
group by strftime(started_at, '%Y-%m')
order by month desc
```

# Badminton Activities

## Monthly Trends

<BarChart
    data={monthly_stats}
    x=month
    y=sessions
    title="Monthly Session Count"
/>

<LineChart
    data={monthly_stats}
    x=month
    y=total_hours
    title="Monthly Playing Time (hours)"
/>

## All Sessions

<DataTable data={activities} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    <Column id=duration_min title="Duration (min)"/>
    <Column id=hr_avg title="Avg HR"/>
</DataTable>

[Back to Activities](/activity)