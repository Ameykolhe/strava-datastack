{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for activity lists.
    Grain: One row per activity.
    Primary key: activity_id

    Metrics:
      - distance_km, distance_miles
      - moving_time_seconds, moving_time_minutes
      - elevation_gain_meters, elevation_gain_feet
      - average_speed_kph, average_speed_mph
      - pace_min_per_km, pace_min_per_mile
      - kudos_count, comment_count, achievement_count, pr_count, suffer_score
      - kilojoules, calories_burned
*/

with activities as (
    select
        activity_id,
        activity_name,
        sport_type,
        lower(sport_type) as sport_slug,
        workout_type,
        started_at,
        started_at_local,
        activity_date,
        activity_year,
        activity_month,
        activity_week,
        activity_day_of_week,
        distance_meters,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elapsed_time_seconds,
        moving_time_minutes,
        elapsed_time_minutes,
        elevation_gain_meters,
        elevation_gain_feet,
        average_speed_mps,
        average_speed_kph,
        average_speed_mph,
        max_speed_mps,
        max_speed_kph,
        max_speed_mph,
        pace_min_per_km,
        pace_min_per_mile,
        average_heartrate_bpm,
        max_heartrate_bpm,
        average_watts,
        kilojoules,
        kudos_count,
        comment_count,
        achievement_count,
        pr_count,
        suffer_score,
        has_heartrate,
        has_power_meter,
        polyline
    from {{ ref('fct_strava__activities') }}
),

final as (
    select
        activity_id,
        activity_name,
        sport_type,
        sport_slug,
        workout_type,
        started_at,
        started_at_local,
        activity_date,
        activity_year,
        activity_month,
        activity_week,
        activity_day_of_week,
        distance_meters,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elapsed_time_seconds,
        moving_time_minutes,
        elapsed_time_minutes,
        elevation_gain_meters,
        elevation_gain_feet,
        average_speed_mps,
        average_speed_kph,
        average_speed_mph,
        max_speed_mps,
        max_speed_kph,
        max_speed_mph,
        pace_min_per_km,
        pace_min_per_mile,
        average_heartrate_bpm,
        max_heartrate_bpm,
        average_watts,
        kilojoules,
        case
            when kilojoules is not null then round(kilojoules * 0.239006, 0)
            else null
        end as calories_burned,
        kudos_count,
        comment_count,
        achievement_count,
        pr_count,
        suffer_score,
        has_heartrate,
        has_power_meter,
        polyline as map_summary_polyline,
        '/activity/' || sport_slug || '/' || activity_id as activity_link
    from activities
)

select
    activity_id,
    activity_name,
    sport_type,
    sport_slug,
    workout_type,
    started_at,
    started_at_local,
    activity_date,
    activity_year,
    activity_month,
    activity_week,
    activity_day_of_week,
    distance_meters,
    distance_km,
    distance_miles,
    moving_time_seconds,
    elapsed_time_seconds,
    moving_time_minutes,
    elapsed_time_minutes,
    elevation_gain_meters,
    elevation_gain_feet,
    average_speed_mps,
    average_speed_kph,
    average_speed_mph,
    max_speed_mps,
    max_speed_kph,
    max_speed_mph,
    pace_min_per_km,
    pace_min_per_mile,
    average_heartrate_bpm,
    max_heartrate_bpm,
    average_watts,
    kilojoules,
    calories_burned,
    kudos_count,
    comment_count,
    achievement_count,
    pr_count,
    suffer_score,
    has_heartrate,
    has_power_meter,
    map_summary_polyline,
    activity_link
from final
