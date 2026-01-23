{{
    config(
        materialized='table'
    )
}}

/*
    Dimension table for Strava segments.
    Grain: One row per segment.
    Primary key: segment_id
*/

with segments as (
    select * from {{ ref('int_strava__segments') }}
),

final as (
    select
        -- Primary key
        segment_id,

        -- Segment attributes
        segment_name,
        segment_activity_type,

        -- Distance and elevation
        segment_distance_meters,
        round(segment_distance_meters / 1000, 2) as segment_distance_km,
        round(segment_distance_meters * 0.000621371, 2) as segment_distance_miles,

        -- Grade metrics
        segment_average_grade,
        segment_maximum_grade,
        segment_elevation_high,
        segment_elevation_low,
        segment_elevation_high - segment_elevation_low as segment_elevation_gain,

        -- Climb categorization
        segment_climb_category,

        -- Location
        segment_city,
        segment_state,
        segment_country,

        -- Coordinates
        segment_start_latitude,
        segment_start_longitude,
        segment_end_latitude,
        segment_end_longitude,

        -- Flags
        segment_is_private,
        segment_is_hazardous,
        segment_is_starred

    from segments
)

select * from final
