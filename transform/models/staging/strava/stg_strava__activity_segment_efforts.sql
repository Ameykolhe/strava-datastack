{{
    config(
        materialized='view'
    )
}}

/*
    Staging model for Strava segment efforts
    Grain: One row per segment effort
    Primary key: effort_id
    Foreign keys: activity_id, segment_id
*/

with source as (
    select * from {{ source('strava_raw', 'activity_segment_efforts') }}
),

staged as (
    select
        -- Primary key
        id as effort_id,

        -- Foreign keys
        _activities_id as activity_id,
        (segment->>'id')::bigint as segment_id,
        (athlete->>'id')::bigint as athlete_id,

        -- Effort details
        name as effort_name,

        -- Timestamps
        start_date as started_at,
        start_date_local as started_at_local,

        -- Performance metrics
        distance as distance_meters,
        elapsed_time as elapsed_time_seconds,
        moving_time as moving_time_seconds,

        -- Stream indices
        start_index,
        end_index,

        -- Rankings
        pr_rank,
        kom_rank,

        -- Heart rate
        average_heartrate as average_heartrate_bpm,
        max_heartrate as max_heartrate_bpm,

        -- Power
        device_watts as has_power_meter,

        -- Visibility
        visibility,
        hidden as is_hidden,

        -- Segment details (extracted from JSON for denormalization)
        segment->>'name' as segment_name,
        segment->>'activity_type' as segment_activity_type,
        (segment->>'distance')::double as segment_distance_meters,
        (segment->>'average_grade')::double as segment_average_grade,
        (segment->>'maximum_grade')::double as segment_maximum_grade,
        (segment->>'elevation_high')::double as segment_elevation_high,
        (segment->>'elevation_low')::double as segment_elevation_low,
        (segment->>'climb_category')::int as segment_climb_category,
        segment->>'city' as segment_city,
        segment->>'state' as segment_state,
        segment->>'country' as segment_country,
        (segment->'start_latlng'->>0)::double as segment_start_latitude,
        (segment->'start_latlng'->>1)::double as segment_start_longitude,
        (segment->'end_latlng'->>0)::double as segment_end_latitude,
        (segment->'end_latlng'->>1)::double as segment_end_longitude,
        (segment->>'private')::boolean as segment_is_private,
        (segment->>'hazardous')::boolean as segment_is_hazardous,
        (segment->>'starred')::boolean as segment_is_starred,

        -- Achievements (keep as JSON for flexibility)
        achievements as achievements_json,

        -- Resource state
        resource_state,

        -- dlt metadata
        _dlt_load_id,
        _dlt_id

    from source
)

select * from staged
