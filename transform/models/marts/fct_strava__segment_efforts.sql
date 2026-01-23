{{
    config(
        materialized='table'
    )
}}

/*
    Fact table for Strava segment efforts.
    Grain: One row per segment effort.
    Primary key: effort_id
    Foreign keys: activity_id, segment_id
*/

with segment_efforts as (
    select * from {{ ref('stg_strava__activity_segment_efforts') }}
),

activities as (
    select
        activity_id,
        activity_name,
        sport_type,
        started_at as activity_started_at
    from {{ ref('stg_strava__activities') }}
),

final as (
    select
        -- Primary key
        se.effort_id,

        -- Foreign keys
        se.activity_id,
        se.segment_id,
        se.athlete_id,

        -- Context from activity
        a.activity_name,
        a.sport_type as activity_sport_type,

        -- Effort details
        se.effort_name,

        -- Timestamps
        se.started_at,
        se.started_at_local,

        -- Date dimensions
        date_trunc('day', se.started_at_local)::date as effort_date,
        extract(year from se.started_at_local)::int as effort_year,
        extract(month from se.started_at_local)::int as effort_month,

        -- Performance metrics
        se.distance_meters,
        round(se.distance_meters / 1000, 3) as distance_km,

        se.elapsed_time_seconds,
        se.moving_time_seconds,
        round(se.elapsed_time_seconds / 60.0, 2) as elapsed_time_minutes,
        round(se.moving_time_seconds / 60.0, 2) as moving_time_minutes,

        -- Speed (calculated)
        case
            when se.elapsed_time_seconds > 0 then round(se.distance_meters / se.elapsed_time_seconds, 2)
            else null
        end as average_speed_mps,
        case
            when se.elapsed_time_seconds > 0 then round((se.distance_meters / se.elapsed_time_seconds) * 3.6, 2)
            else null
        end as average_speed_kph,

        -- Pace
        case
            when se.distance_meters > 0 then round((se.elapsed_time_seconds / 60.0) / (se.distance_meters / 1000), 2)
            else null
        end as pace_min_per_km,

        -- Stream indices (for linking to stream data points)
        se.start_index,
        se.end_index,
        se.end_index - se.start_index as point_count,

        -- Rankings
        se.pr_rank,
        se.kom_rank,
        se.pr_rank = 1 as is_pr,
        se.kom_rank is not null as has_kom_rank,

        -- Heart rate
        se.average_heartrate_bpm,
        se.max_heartrate_bpm,

        -- Power
        se.has_power_meter,

        -- Visibility
        se.visibility,
        se.is_hidden,

        -- Segment context (denormalized for convenience)
        se.segment_name,
        se.segment_activity_type,
        se.segment_distance_meters,
        se.segment_average_grade,
        se.segment_climb_category,
        se.segment_city,
        se.segment_state,
        se.segment_country,

        -- Metadata
        se._dlt_load_id,
        se._dlt_id

    from segment_efforts se
    left join activities a
        on se.activity_id = a.activity_id
)

select * from final
