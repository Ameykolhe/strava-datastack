{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for daily activity trends.
    Grain: One row per activity_date.
    Primary key: activity_date
*/

with activities as (
    select
        activity_date,
        activity_year,
        distance_miles,
        moving_time_seconds,
        elevation_gain_feet
    from {{ ref('fct_strava__activities') }}
),

daily as (
    select
        activity_date,
        activity_year,
        count(*) as activity_count,
        sum(distance_miles) as total_distance_miles,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours,
        sum(elevation_gain_feet) as total_elevation_gain_feet
    from activities
    group by activity_date, activity_year
),

final as (
    select
        activity_date,
        activity_year,
        activity_count,
        round(total_distance_miles, 1) as total_distance_miles,
        round(total_moving_time_hours, 2) as total_moving_time_hours,
        round(total_elevation_gain_feet, 0) as total_elevation_gain_feet,
        case
            when total_moving_time_hours > 0
                then round(total_distance_miles / total_moving_time_hours, 2)
            else null
        end as avg_speed_mph
    from daily
)

select
    activity_date,
    activity_year,
    activity_count,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_mph
from final
