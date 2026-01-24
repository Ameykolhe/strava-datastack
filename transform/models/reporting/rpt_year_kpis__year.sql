{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for year-level KPIs.
    Grain: One row per activity_year.
    Primary key: activity_year
*/

with activities as (
    select
        activity_year,
        distance_miles,
        moving_time_seconds,
        elevation_gain_feet
    from {{ ref('fct_strava__activities') }}
),

aggregated as (
    select
        activity_year,
        count(*) as activity_count,
        sum(distance_miles) as total_distance_miles,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours,
        sum(elevation_gain_feet) as total_elevation_gain_feet,
        max(distance_miles) as longest_distance_miles,
        max(elevation_gain_feet) as hardest_elevation_gain_feet
    from activities
    group by activity_year
),

final as (
    select
        activity_year,
        activity_count,
        round(total_distance_miles, 1) as total_distance_miles,
        round(total_moving_time_hours, 1) as total_moving_time_hours,
        round(total_elevation_gain_feet, 0) as total_elevation_gain_feet,
        round(longest_distance_miles, 1) as longest_distance_miles,
        round(hardest_elevation_gain_feet, 0) as hardest_elevation_gain_feet
    from aggregated
)

select
    activity_year,
    activity_count,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    longest_distance_miles,
    hardest_elevation_gain_feet
from final
