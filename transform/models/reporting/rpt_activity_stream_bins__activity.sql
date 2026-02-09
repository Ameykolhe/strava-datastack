{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for activity stream charting.
    Grain: One row per activity per 50m distance bin.
*/

with activity_points as (
    select
        p.activity_id,
        a.sport_type,
        p.distance_meters,
        p.time_seconds,
        p.altitude_meters,
        p.velocity_kph,
        p.velocity_mph,
        p.heartrate_bpm,
        p.grade_percent
    from {{ ref('fct_strava__activity_data_points') }} p
    inner join {{ ref('fct_strava__activities') }} a
        on p.activity_id = a.activity_id
),

binned as (
    select
        activity_id,
        sport_type,
        floor(distance_meters / 50)::int as bin_index,
        min(distance_meters) as distance_start_meters,
        round(avg(distance_meters) / 1000, 3) as distance_mid_km,
        round(avg(distance_meters) / 1609.344, 3) as distance_mid_miles,
        min(time_seconds) as time_start_seconds,
        round(avg(time_seconds) / 60.0, 2) as time_mid_minutes,
        round(avg(altitude_meters), 1) as avg_altitude_meters,
        round(avg(altitude_meters) * 3.28084, 1) as avg_altitude_feet,
        round(avg(velocity_kph), 2) as avg_velocity_kph,
        round(avg(velocity_mph), 2) as avg_velocity_mph,
        case
            when avg(velocity_kph) > 0 then round(60.0 / avg(velocity_kph), 2)
            else null
        end as avg_pace_min_per_km,
        case
            when avg(velocity_mph) > 0 then round(60.0 / avg(velocity_mph), 2)
            else null
        end as avg_pace_min_per_mile,
        round(avg(heartrate_bpm), 0) as avg_heartrate_bpm,
        round(avg(grade_percent), 1) as avg_grade_percent,
        round(max(velocity_kph), 2) as max_velocity_kph,
        max(heartrate_bpm) as max_heartrate_bpm,
        round(max(grade_percent), 1) as max_grade_percent,
        round(min(grade_percent), 1) as min_grade_percent,
        count(*) as point_count
    from activity_points
    where distance_meters is not null
    group by activity_id, sport_type, floor(distance_meters / 50)::int
)

select
    *,
    {{ seconds_to_time_display('time_start_seconds') }} as time_display,
    avg_heartrate_bpm is not null as has_heartrate
from binned
