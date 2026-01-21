{{
    config(
        materialized='table'
    )
}}

with activities as (
    select * from {{ ref('fct_activities') }}
),

yearly_kpis as (
    select
        extract(year from started_at_local) as year,
        count(*) as activity_count,
        sum(distance) as total_distance,
        sum(moving_seconds) as total_moving_time,
        sum(elevation_gain) as total_elevation_gain,
        max(distance) as longest_distance,
        max(elevation_gain) as hardest_elevation_gain,
        avg(distance) as avg_distance,
        avg(speed_avg) as avg_speed,
        avg(hr_avg) as avg_hr,
        avg(power_avg) as avg_power,
        sum(distance) / nullif(count(distinct extract(week from started_at_local)), 0) as avg_weekly_distance
    from activities
    group by extract(year from started_at_local)
)

select * from yearly_kpis
order by year desc
