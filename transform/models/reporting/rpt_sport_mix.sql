{{
    config(
        materialized='table'
    )
}}

with activities as (
    select * from {{ ref('fct_activities') }}
),

sport_mix as (
    select
        sport_type,
        count(*) as activity_count,
        sum(distance) as total_distance,
        sum(moving_seconds) as total_moving_time,
        sum(elevation_gain) as total_elevation_gain
    from activities
    group by sport_type
)

select * from sport_mix
order by activity_count desc
