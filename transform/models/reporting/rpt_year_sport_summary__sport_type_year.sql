{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for activity summary by sport type and year.
    Grain: One row per sport_type per activity_year.
    Primary key: (sport_type, activity_year)
*/

with activities as (
    select
        sport_type,
        activity_year,
        distance_km,
        distance_miles,
        moving_time_seconds
    from {{ ref('fct_strava__activities') }}
),

aggregated as (
    select
        sport_type,
        activity_year,
        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(distance_miles) as total_distance_miles,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours
    from activities
    group by sport_type, activity_year
),

final as (
    select
        sport_type,
        lower(sport_type) as sport_slug,
        activity_year,
        activity_count,
        round(total_distance_km, 1) as total_distance_km,
        round(total_distance_miles, 1) as total_distance_miles,
        round(total_moving_time_hours, 1) as total_moving_time_hours
    from aggregated
)

select
    sport_type,
    sport_slug,
    activity_year,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours
from final
