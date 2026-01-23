{{
    config(
        materialized='view'
    )
}}

/*
    Intermediate model that pivots activity streams from long to wide format.
    Grain: One row per activity.
    Primary key: activity_id

    Each stream type becomes a column containing its JSON array of values.
*/

with streams as (
    select * from {{ ref('stg_strava__activity_streams') }}
),

pivoted as (
    select
        activity_id,

        -- Pivot each stream type to its own column
        max(case when stream_type = 'time' then stream_data end) as time_stream,
        max(case when stream_type = 'distance' then stream_data end) as distance_stream,
        max(case when stream_type = 'altitude' then stream_data end) as altitude_stream,
        max(case when stream_type = 'velocity_smooth' then stream_data end) as velocity_stream,
        max(case when stream_type = 'heartrate' then stream_data end) as heartrate_stream,
        max(case when stream_type = 'grade_smooth' then stream_data end) as grade_stream,
        max(case when stream_type = 'latlng' then stream_data end) as latlng_stream,
        max(case when stream_type = 'moving' then stream_data end) as moving_stream,

        -- Stream availability flags
        max(case when stream_type = 'time' then 1 else 0 end)::boolean as has_time_stream,
        max(case when stream_type = 'distance' then 1 else 0 end)::boolean as has_distance_stream,
        max(case when stream_type = 'altitude' then 1 else 0 end)::boolean as has_altitude_stream,
        max(case when stream_type = 'velocity_smooth' then 1 else 0 end)::boolean as has_velocity_stream,
        max(case when stream_type = 'heartrate' then 1 else 0 end)::boolean as has_heartrate_stream,
        max(case when stream_type = 'grade_smooth' then 1 else 0 end)::boolean as has_grade_stream,
        max(case when stream_type = 'latlng' then 1 else 0 end)::boolean as has_latlng_stream,
        max(case when stream_type = 'moving' then 1 else 0 end)::boolean as has_moving_stream,

        -- Data point count (from time stream as reference)
        max(case when stream_type = 'time' then data_point_count end) as data_point_count

    from streams
    group by activity_id
)

select * from pivoted
