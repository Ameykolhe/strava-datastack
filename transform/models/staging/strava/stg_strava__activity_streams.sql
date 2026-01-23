{{
    config(
        materialized='view'
    )
}}

/*
    Staging model for Strava activity streams
    Grain: One row per activity per stream type
    Primary key: (activity_id, stream_type)
    Foreign key: activity_id
*/

with source as (
    select * from {{ source('strava_raw', 'activity_streams') }}
),

staged as (
    select
        -- Composite primary key
        _activities_id as activity_id,
        type as stream_type,

        -- Stream metadata
        series_type,
        original_size as data_point_count,
        resolution,

        -- Stream data (JSON array of values)
        data as stream_data,

        -- dlt metadata
        _dlt_load_id,
        _dlt_id

    from source
)

select * from staged
