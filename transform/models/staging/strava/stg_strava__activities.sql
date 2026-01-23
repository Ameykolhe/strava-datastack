{{
    config(
        materialized='view'
    )
}}

/*
    Staging model for Strava activities
    Grain: One row per activity
    Primary key: activity_id
*/

with source as (
    select * from {{ source('strava_raw', 'activities') }}
),

staged as (
    select
        -- Primary key
        id as activity_id,

        -- Athlete (extracted from JSON)
        (athlete->>'id')::bigint as athlete_id,

        -- Activity identifiers
        name as activity_name,
        type as activity_type,
        sport_type,
        workout_type,

        -- Timestamps
        start_date as started_at,
        start_date_local as started_at_local,
        timezone,
        utc_offset,

        -- Location
        location_city,
        location_state,
        location_country,

        -- Coordinates (extracted from JSON arrays)
        (start_latlng->>0)::double as start_latitude,
        (start_latlng->>1)::double as start_longitude,
        (end_latlng->>0)::double as end_latitude,
        (end_latlng->>1)::double as end_longitude,

        -- Map data (extracted from JSON)
        (map->>'id') as map_id,
        (map->>'summary_polyline') as polyline,

        -- Distance and elevation
        distance as distance_meters,
        total_elevation_gain as elevation_gain_meters,
        elev_high as elevation_high_meters,
        elev_low as elevation_low_meters,

        -- Time metrics (in seconds)
        moving_time as moving_time_seconds,
        elapsed_time as elapsed_time_seconds,

        -- Speed metrics
        average_speed as average_speed_mps,
        max_speed as max_speed_mps,

        -- Heart rate metrics
        has_heartrate,
        average_heartrate as average_heartrate_bpm,
        max_heartrate as max_heartrate_bpm,
        heartrate_opt_out,
        display_hide_heartrate_option,

        -- Power metrics
        average_watts,
        device_watts as has_power_meter,
        kilojoules,

        -- Social metrics
        achievement_count,
        kudos_count,
        comment_count,
        athlete_count,
        photo_count,
        total_photo_count,
        pr_count,
        has_kudoed,

        -- Activity flags
        trainer as is_trainer,
        commute as is_commute,
        manual as is_manual,
        private as is_private,
        flagged as is_flagged,
        visibility,
        from_accepted_tag,

        -- Gear
        gear_id,

        -- Device
        device_name,

        -- Scores
        suffer_score,

        -- Upload info
        upload_id,
        upload_id_str,
        external_id,

        -- Resource state
        resource_state,

        -- dlt metadata
        _dlt_load_id,
        _dlt_id

    from source
)

select * from staged
