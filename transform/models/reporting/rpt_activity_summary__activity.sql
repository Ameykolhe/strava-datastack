{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for lightweight activity summaries.
    Grain: One row per activity.
    Primary key: activity_id
*/

with activities as (
    select
        activity_id,
        activity_name,
        sport_type,
        activity_date,
        distance_miles,
        moving_time_seconds,
        elevation_gain_feet
    from {{ ref('fct_strava__activities') }}
),

final as (
    select
        activity_id,
        activity_name,
        sport_type,
        activity_date,
        round(distance_miles, 2) as distance_miles,
        round(moving_time_seconds / 3600.0, 2) as moving_time_hours,
        round(elevation_gain_feet, 0) as elevation_gain_feet
    from activities
)

select
    activity_id,
    activity_name,
    sport_type,
    activity_date,
    distance_miles,
    moving_time_hours,
    elevation_gain_feet
from final
