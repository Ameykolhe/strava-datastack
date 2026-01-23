{{
    config(
        materialized='view'
    )
}}

/*
    Intermediate model that extracts unique segments from segment efforts.
    Grain: One row per segment.
    Primary key: segment_id

    Segments are deduplicated by taking the most recent effort's segment data.
*/

with segment_efforts as (
    select * from {{ ref('stg_strava__activity_segment_efforts') }}
),

-- Rank efforts by started_at to get the most recent segment data
ranked_segments as (
    select
        segment_id,
        segment_name,
        segment_activity_type,
        segment_distance_meters,
        segment_average_grade,
        segment_maximum_grade,
        segment_elevation_high,
        segment_elevation_low,
        segment_climb_category,
        segment_city,
        segment_state,
        segment_country,
        segment_start_latitude,
        segment_start_longitude,
        segment_end_latitude,
        segment_end_longitude,
        segment_is_private,
        segment_is_hazardous,
        segment_is_starred,
        row_number() over (partition by segment_id order by started_at desc) as rn
    from segment_efforts
    where segment_id is not null
),

unique_segments as (
    select
        segment_id,
        segment_name,
        segment_activity_type,
        segment_distance_meters,
        segment_average_grade,
        segment_maximum_grade,
        segment_elevation_high,
        segment_elevation_low,
        segment_climb_category,
        segment_city,
        segment_state,
        segment_country,
        segment_start_latitude,
        segment_start_longitude,
        segment_end_latitude,
        segment_end_longitude,
        segment_is_private,
        segment_is_hazardous,
        segment_is_starred
    from ranked_segments
    where rn = 1
)

select * from unique_segments
