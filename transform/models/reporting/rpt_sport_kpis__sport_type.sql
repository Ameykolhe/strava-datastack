{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for sport-level KPIs.
    Grain: One row per sport_type.
*/

with activities as (
    select
        sport_type,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elevation_gain_meters,
        elevation_gain_feet,
        average_heartrate_bpm
    from {{ ref('fct_strava__activities') }}
),

aggregated as (
    select
        sport_type,
        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(distance_miles) as total_distance_miles,
        sum(moving_time_seconds) as total_moving_time_seconds,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours,
        sum(elevation_gain_meters) as total_elevation_meters,
        sum(elevation_gain_feet) as total_elevation_gain_feet,
        avg(average_heartrate_bpm) as avg_heartrate_bpm
    from activities
    group by sport_type
),

final as (
    select
        sport_type,
        lower(sport_type) as sport_slug,
        activity_count,
        round(total_distance_km, 1) as total_distance_km,
        round(total_distance_miles, 1) as total_distance_miles,
        round(total_moving_time_hours, 1) as total_moving_time_hours,
        round(total_elevation_meters, 0) as total_elevation_meters,
        round(total_elevation_gain_feet, 0) as total_elevation_gain_feet,
        round(avg_heartrate_bpm, 0) as avg_heartrate_bpm,
        case
            when total_moving_time_seconds > 0
                then round((total_distance_km / (total_moving_time_seconds / 3600.0)), 1)
            else null
        end as avg_speed_kmh,
        case
            when total_distance_km > 0
                then round((total_moving_time_seconds / 60.0) / total_distance_km, 2)
            else null
        end as avg_pace_min_per_km
    from aggregated
)

select
    sport_type,
    sport_slug,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_meters,
    total_elevation_gain_feet,
    avg_heartrate_bpm,
    avg_speed_kmh,
    avg_pace_min_per_km
from final
