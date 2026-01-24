{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for home dashboard KPIs.
    Grain: Single row (all activities).
*/

with activities as (
    select
        distance_miles,
        moving_time_seconds,
        elevation_gain_feet,
        average_speed_mph
    from {{ ref('fct_strava__activities') }}
),

aggregated as (
    select
        count(*) as total_activity_count,
        sum(distance_miles) as total_distance_miles,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours,
        sum(elevation_gain_feet) as total_elevation_gain_feet,
        case
            when sum(moving_time_seconds) > 0
                then (sum(distance_miles) / (sum(moving_time_seconds) / 3600.0))
            else null
        end as avg_speed_mph
    from activities
)

select
    total_activity_count,
    round(total_distance_miles, 1) as total_distance_miles,
    round(total_moving_time_hours, 0) as total_moving_time_hours,
    round(total_elevation_gain_feet, 0) as total_elevation_gain_feet,
    round(avg_speed_mph, 1) as avg_speed_mph
from aggregated
