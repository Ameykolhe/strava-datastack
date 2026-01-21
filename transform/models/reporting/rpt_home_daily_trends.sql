{{
    config(
        materialized='table'
    )
}}

with activities as (
    select * from {{ ref('fct_activities') }}
),

daily_trends as (
    select
        started_at_local::date as activity_date,
        count(*) as activity_count,
        sum(distance) as total_distance,
        sum(moving_seconds) as total_moving_time,
        sum(elevation_gain) as total_elevation_gain,
        avg(hr_avg) as avg_hr,
        avg(power_avg) as avg_power
    from activities
    group by started_at_local::date
)

select * from daily_trends
order by activity_date
