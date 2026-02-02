{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for activity detail pages.
    Grain: One row per activity.
    Primary key: activity_id

    Purpose: Provides all fields needed for the activity detail page view.
    Includes both metric and imperial units, flags, location, and social stats.
*/

with activities as (
    select
        -- Identifiers
        activity_id,
        activity_name,
        sport_type,
        workout_type,

        -- Timestamps & location
        started_at,
        started_at_local,
        timezone,
        utc_offset,
        activity_date,
        activity_year,
        activity_month,
        activity_week,
        activity_day_of_week,
        location_city,
        location_state,
        location_country,

        -- Core metrics (both units)
        distance_meters,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elapsed_time_seconds,
        moving_time_minutes,
        elapsed_time_minutes,
        elevation_gain_meters,
        elevation_gain_feet,

        -- Speed/pace
        average_speed_mps,
        average_speed_kph,
        average_speed_mph,
        max_speed_mps,
        max_speed_kph,
        max_speed_mph,
        pace_min_per_km,
        pace_min_per_mile,

        -- HR/Power
        has_heartrate,
        average_heartrate_bpm,
        max_heartrate_bpm,
        has_power_meter,
        average_watts,
        kilojoules,

        -- Map data
        polyline,
        start_latitude,
        start_longitude,
        end_latitude,
        end_longitude,

        -- Social/engagement
        kudos_count,
        comment_count,
        achievement_count,
        pr_count,
        suffer_score,

        -- Flags & metadata
        is_trainer,
        is_commute,
        is_manual,
        is_private,
        visibility,
        device_name,

        -- Stream availability (for future use)
        has_time_stream,
        has_distance_stream,
        has_altitude_stream,
        has_velocity_stream,
        has_heartrate_stream,
        has_latlng_stream,
        stream_data_point_count

    from {{ ref('fct_strava__activities') }}
),

final as (
    select
        activity_id,
        activity_name,
        sport_type,
        lower(sport_type) as sport_slug,
        workout_type,
        started_at,
        started_at_local,
        timezone,
        utc_offset,
        activity_date,
        activity_year,
        activity_month,
        activity_week,
        activity_day_of_week,
        location_city,
        location_state,
        location_country,
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
        has_heartrate,
        average_heartrate_bpm,
        max_heartrate_bpm,
        has_power_meter,
        average_watts,
        kilojoules,
        -- Derived: calories from kilojoules
        case
            when kilojoules is not null then round(kilojoules * 0.239006, 0)
            else null
        end as calories_burned,
        polyline,
        polyline as map_summary_polyline,
        start_latitude,
        start_longitude,
        end_latitude,
        end_longitude,
        kudos_count,
        comment_count,
        achievement_count,
        pr_count,
        suffer_score,
        is_trainer,
        is_commute,
        is_manual,
        is_private,
        visibility,
        device_name,
        has_time_stream,
        has_distance_stream,
        has_altitude_stream,
        has_velocity_stream,
        has_heartrate_stream,
        has_latlng_stream,
        stream_data_point_count,
        -- Computed link
        '/activity/' || lower(sport_type) || '/' || activity_id as activity_link
    from activities
)

select * from final