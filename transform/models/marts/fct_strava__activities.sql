{{
    config(
        materialized='table'
    )
}}

/*
    Fact table for Strava activities with enriched metrics.
    Grain: One row per activity.
    Primary key: activity_id
*/

with activities as (
    select * from {{ ref('stg_strava__activities') }}
),

activity_streams as (
    select * from {{ ref('int_strava__activity_streams') }}
),

final as (
    select
        -- Primary key
        a.activity_id,

        -- Foreign keys
        a.athlete_id,
        a.gear_id,

        -- Activity identifiers
        a.activity_name,
        a.activity_type,
        a.sport_type,
        a.workout_type,

        -- Timestamps
        a.started_at,
        a.started_at_local,
        a.timezone,
        a.utc_offset,

        -- Date dimensions (for easy filtering)
        date_trunc('day', a.started_at_local)::date as activity_date,
        extract(year from a.started_at_local)::int as activity_year,
        extract(month from a.started_at_local)::int as activity_month,
        extract(week from a.started_at_local)::int as activity_week,
        extract(dow from a.started_at_local)::int as activity_day_of_week,

        -- Location
        a.location_city,
        a.location_state,
        a.location_country,

        -- Start/end coordinates
        a.start_latitude,
        a.start_longitude,
        a.end_latitude,
        a.end_longitude,

        -- Map data
        a.map_id,
        a.polyline,

        -- Distance metrics (multiple units)
        a.distance_meters,
        round(a.distance_meters / 1000, 2) as distance_km,
        round(a.distance_meters * 0.000621371, 2) as distance_miles,

        -- Elevation metrics
        a.elevation_gain_meters,
        round(a.elevation_gain_meters * 3.28084, 0) as elevation_gain_feet,
        a.elevation_high_meters,
        a.elevation_low_meters,

        -- Time metrics
        a.moving_time_seconds,
        a.elapsed_time_seconds,
        round(a.moving_time_seconds / 60.0, 1) as moving_time_minutes,
        round(a.elapsed_time_seconds / 60.0, 1) as elapsed_time_minutes,

        -- Speed metrics
        a.average_speed_mps,
        a.max_speed_mps,
        round(a.average_speed_mps * 3.6, 2) as average_speed_kph,
        round(a.max_speed_mps * 3.6, 2) as max_speed_kph,
        round(a.average_speed_mps * 2.23694, 2) as average_speed_mph,
        round(a.max_speed_mps * 2.23694, 2) as max_speed_mph,

        -- Pace (minutes per km/mile) - only for activities with distance
        case
            when a.distance_meters > 0 then round((a.moving_time_seconds / 60.0) / (a.distance_meters / 1000), 2)
            else null
        end as pace_min_per_km,
        case
            when a.distance_meters > 0 then round((a.moving_time_seconds / 60.0) / (a.distance_meters * 0.000621371), 2)
            else null
        end as pace_min_per_mile,

        -- Heart rate metrics
        a.has_heartrate,
        a.average_heartrate_bpm,
        a.max_heartrate_bpm,
        a.heartrate_opt_out,

        -- Power metrics
        a.average_watts,
        a.has_power_meter,
        a.kilojoules,

        -- Social metrics
        a.achievement_count,
        a.kudos_count,
        a.comment_count,
        a.athlete_count,
        a.photo_count,
        a.total_photo_count,
        a.pr_count,
        a.has_kudoed,

        -- Activity flags
        a.is_trainer,
        a.is_commute,
        a.is_manual,
        a.is_private,
        a.is_flagged,
        a.visibility,

        -- Device
        a.device_name,

        -- Scores
        a.suffer_score,

        -- Upload info
        a.upload_id,
        a.external_id,

        -- Stream availability
        s.has_time_stream,
        s.has_distance_stream,
        s.has_altitude_stream,
        s.has_velocity_stream,
        s.has_heartrate_stream,
        s.has_grade_stream,
        s.has_latlng_stream,
        s.has_moving_stream,
        coalesce(s.data_point_count, 0) as stream_data_point_count,

        -- Metadata
        a._dlt_load_id,
        a._dlt_id

    from activities a
    left join activity_streams s
        on a.activity_id = s.activity_id
)

select * from final
