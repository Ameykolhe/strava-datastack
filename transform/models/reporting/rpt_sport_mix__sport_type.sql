{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for sport mix tiles on the home dashboard.
    Grain: One row per sport_type.
    Primary key: sport_type
*/

with sport_summary as (
    select
        sport_type,
        activity_count,
        total_distance_miles,
        total_moving_time_hours
    from {{ ref('rpt_activities_by_sport__sport_type') }}
)

select
    sport_type,
    activity_count,
    total_distance_miles,
    total_moving_time_hours
from sport_summary
