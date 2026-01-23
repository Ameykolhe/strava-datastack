{{
    config(
        materialized='table'
    )
}}

/*
    Fact table for activity data points (time-series stream data).
    Grain: One row per activity per data point.
    Primary key: (activity_id, point_index)
    Foreign key: activity_id

    This table contains the unnested stream data for detailed
    time-series analysis and visualization.
*/

with stream_points as (
    select * from {{ ref('int_strava__activity_stream_points') }}
),

activities as (
    select
        activity_id,
        activity_name,
        sport_type,
        started_at,
        started_at_local
    from {{ ref('stg_strava__activities') }}
),

final as (
    select
        -- Primary key (composite)
        sp.activity_id,
        sp.point_index,

        -- Activity context
        a.activity_name,
        a.sport_type,
        a.started_at as activity_started_at,
        a.started_at_local as activity_started_at_local,

        -- Time metrics
        sp.time_seconds,
        round(sp.time_seconds / 60.0, 2) as time_minutes,

        -- Calculated timestamp for this point
        a.started_at + (sp.time_seconds * interval '1 second') as point_timestamp,

        -- Distance metrics
        sp.distance_meters,
        round(sp.distance_meters / 1000, 3) as distance_km,

        -- Elevation
        sp.altitude_meters,
        round(sp.altitude_meters * 3.28084, 1) as altitude_feet,

        -- Velocity
        sp.velocity_mps,
        round(sp.velocity_mps * 3.6, 2) as velocity_kph,
        round(sp.velocity_mps * 2.23694, 2) as velocity_mph,

        -- Heart rate
        sp.heartrate_bpm,

        -- Grade
        sp.grade_percent,

        -- Location
        sp.latitude,
        sp.longitude,

        -- Movement flag
        sp.is_moving

    from stream_points sp
    inner join activities a
        on sp.activity_id = a.activity_id
)

select * from final
