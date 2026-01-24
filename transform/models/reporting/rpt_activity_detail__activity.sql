{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for activity detail pages.
    Grain: One row per activity.
    Primary key: activity_id

    Metrics:
      - distance_miles, elevation_gain_feet
      - moving_time_seconds, elapsed_time_seconds
      - average_speed_mph, max_speed_mph
      - average_heartrate_bpm, max_heartrate_bpm
      - average_watts, kilojoules, calories_burned
*/

with activities as (
    select
        activity_id,
        activity_name,
        sport_type,
        workout_type,
        started_at,
        started_at_local,
        distance_meters,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elapsed_time_seconds,
        elevation_gain_meters,
        elevation_gain_feet,
        average_speed_mph,
        max_speed_mph,
        average_heartrate_bpm,
        max_heartrate_bpm,
        average_watts,
        kilojoules,
        polyline as map_summary_polyline,
        kudos_count,
        comment_count,
        achievement_count,
        pr_count,
        suffer_score
    from {{ ref('fct_strava__activities') }}
),

final as (
    select
        activity_id,
        activity_name,
        sport_type,
        workout_type,
        started_at,
        started_at_local,
        distance_meters,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elapsed_time_seconds,
        elevation_gain_meters,
        elevation_gain_feet,
        average_speed_mph,
        max_speed_mph,
        average_heartrate_bpm,
        max_heartrate_bpm,
        average_watts,
        kilojoules,
        case
            when kilojoules is not null then round(kilojoules * 0.239006, 0)
            else null
        end as calories_burned,
        map_summary_polyline,
        kudos_count,
        comment_count,
        achievement_count,
        pr_count,
        suffer_score
    from activities
)

select
    activity_id,
    activity_name,
    sport_type,
    workout_type,
    started_at,
    started_at_local,
    distance_meters,
    distance_km,
    distance_miles,
    moving_time_seconds,
    elapsed_time_seconds,
    elevation_gain_meters,
    elevation_gain_feet,
    average_speed_mph,
    max_speed_mph,
    average_heartrate_bpm,
    max_heartrate_bpm,
    average_watts,
    kilojoules,
    calories_burned,
    map_summary_polyline,
    kudos_count,
    comment_count,
    achievement_count,
    pr_count,
    suffer_score
from final
