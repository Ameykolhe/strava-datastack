---
title: Performance Metrics
---

# Performance Analysis

## Personal Records & Achievements

```sql pr_stats
select
    COUNT(*) as total_activities,
    SUM(pr_count) as total_prs,
    SUM(achievement_count) as total_achievements,
    AVG(suffer_score) as avg_suffer_score,
    MAX(suffer_score) as max_suffer_score
from strava.activities_overview
where pr_count > 0 or achievement_count > 0
```

<Grid cols=3>
    <BigValue
        data={pr_stats}
        value=total_prs
        title="Total Personal Records"
    />
    <BigValue
        data={pr_stats}
        value=total_achievements
        title="Total Achievements"
    />
    <BigValue
        data={pr_stats}
        value=avg_suffer_score
        fmt='#,##0.0'
        title="Avg Suffer Score"
    />
</Grid>

## Activities with PRs

```sql pr_activities
select
    name,
    sport_type,
    start_date_local,
    distance_km,
    pr_count,
    achievement_count,
    suffer_score,
    kudos_count
from strava.activities_overview
where pr_count > 0
order by pr_count desc, start_date_local desc
limit 50
```

<DataTable data={pr_activities} search=true>
    <Column id=name/>
    <Column id=sport_type/>
    <Column id=start_date_local fmt='yyyy-MM-dd'/>
    <Column id=distance_km fmt='#,##0.00'/>
    <Column id=pr_count/>
    <Column id=achievement_count/>
    <Column id=suffer_score fmt='#,##0'/>
    <Column id=kudos_count/>
</DataTable>

## Power & Energy Metrics

```sql power_stats
select
    sport_type,
    COUNT(*) as activity_count,
    AVG(average_watts) as avg_watts,
    MAX(average_watts) as max_avg_watts,
    SUM(kilojoules) as total_kilojoules
from strava.activities_overview
where average_watts is not null
group by sport_type
order by avg_watts desc
```

<BarChart
    data={power_stats}
    title="Average Power by Sport Type"
    x=sport_type
    y=avg_watts
/>

<DataTable data={power_stats}>
    <Column id=sport_type/>
    <Column id=activity_count/>
    <Column id=avg_watts fmt='#,##0.0'/>
    <Column id=max_avg_watts fmt='#,##0.0'/>
    <Column id=total_kilojoules fmt='#,##0'/>
</DataTable>

## Heart Rate Zones

```sql hr_distribution
select
    CASE
        WHEN average_heartrate < 100 THEN 'Zone 1 (< 100 bpm)'
        WHEN average_heartrate < 120 THEN 'Zone 2 (100-120 bpm)'
        WHEN average_heartrate < 140 THEN 'Zone 3 (120-140 bpm)'
        WHEN average_heartrate < 160 THEN 'Zone 4 (140-160 bpm)'
        ELSE 'Zone 5 (160+ bpm)'
    END as hr_zone,
    COUNT(*) as activity_count,
    AVG(distance_km) as avg_distance_km,
    AVG(moving_time_minutes) as avg_duration_min
from strava.activities_overview
where average_heartrate is not null
group by hr_zone
order by hr_zone
```

<BarChart
    data={hr_distribution}
    title="Activities by Heart Rate Zone"
    x=hr_zone
    y=activity_count
/>