{{
    config(
        materialized='table'
    )
}}

with activities as (
    select * from {{ ref('fct_activities') }}
),

kpis as (
    select
        count(*) as total_activity_count,
        sum(distance) as total_distance,
        sum(moving_seconds) as total_moving_time,
        sum(elapsed_seconds) as total_elapsed_time,
        sum(elevation_gain) as total_elevation_gain,
        avg(distance) as avg_distance,
        avg(speed_avg) as avg_speed,
        avg(hr_avg) as avg_hr,
        avg(power_avg) as avg_power,
        max(started_at) as last_activity_date
    from activities
)

select * from kpis
