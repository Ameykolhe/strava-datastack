{{
    config(
        materialized='incremental',
        unique_key=['activity_id', 'point_index'],
        on_schema_change='append_new_columns'
    )
}}

/*
    Intermediate model that unnests activity streams into individual data points.
    Grain: One row per activity per point index.
    Primary key: (activity_id, point_index)

    This model aligns all stream types by their index position, creating
    a time-series view of the activity data.

    Optimized using DuckDB's parallel UNNEST which automatically aligns
    multiple arrays by position in a single pass.
*/

with activity_streams as (
    select
        activity_id,
        -- Cast streams to typed arrays once
        cast(time_stream as bigint[]) as time_arr,
        cast(distance_stream as double[]) as distance_arr,
        cast(altitude_stream as double[]) as altitude_arr,
        cast(velocity_stream as double[]) as velocity_arr,
        cast(heartrate_stream as int[]) as heartrate_arr,
        cast(grade_stream as double[]) as grade_arr,
        cast(latlng_stream as double[][]) as latlng_arr,
        cast(moving_stream as boolean[]) as moving_arr
    from {{ ref('int_strava__activity_streams') }}
    where time_stream is not null
    {% if is_incremental() %}
    and activity_id not in (select distinct activity_id from {{ this }})
    {% endif %}
),

-- DuckDB parallel UNNEST: multiple arrays are aligned by position automatically
-- This is the most efficient approach - single pass through the data
unnested as (
    select
        activity_id,
        unnest(time_arr) as time_seconds,
        unnest(distance_arr) as distance_meters,
        unnest(altitude_arr) as altitude_meters,
        unnest(velocity_arr) as velocity_mps,
        unnest(heartrate_arr) as heartrate_bpm,
        unnest(grade_arr) as grade_percent,
        unnest(latlng_arr) as latlng_point,
        unnest(moving_arr) as is_moving
    from activity_streams
),

final as (
    select
        activity_id,
        row_number() over (partition by activity_id order by time_seconds) - 1 as point_index,
        time_seconds,
        distance_meters,
        altitude_meters,
        velocity_mps,
        heartrate_bpm,
        grade_percent,
        latlng_point[1] as latitude,
        latlng_point[2] as longitude,
        is_moving
    from unnested
)

select
    activity_id,
    point_index,
    time_seconds,
    distance_meters,
    altitude_meters,
    velocity_mps,
    heartrate_bpm,
    grade_percent,
    latitude,
    longitude,
    is_moving
from final