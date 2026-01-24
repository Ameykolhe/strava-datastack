{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for monthly sport-level trends.
    Grain: One row per sport_type per month.
    Primary key: (sport_type, activity_year, month_number)
*/

with activities as (
    select
        sport_type,
        started_at_local,
        activity_year,
        distance_km,
        elevation_gain_meters,
        moving_time_seconds,
        average_heartrate_bpm
    from {{ ref('fct_strava__activities') }}
),

monthly as (
    select
        sport_type,
        activity_year,
        date_trunc('month', started_at_local)::date as month_start,
        extract(month from started_at_local)::int as month_number,
        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(elevation_gain_meters) as total_elevation_meters,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours,
        avg(average_heartrate_bpm) as avg_heartrate_bpm,
        sum(moving_time_seconds) as total_moving_time_seconds
    from activities
    group by sport_type, activity_year, month_start, month_number
),

final as (
    select
        sport_type,
        activity_year,
        month_start,
        month_number,
        strftime(month_start, '%Y-%m') as month_label,
        activity_count,
        round(total_distance_km, 1) as total_distance_km,
        round(total_elevation_meters, 0) as total_elevation_meters,
        round(total_moving_time_hours, 1) as total_moving_time_hours,
        round(avg_heartrate_bpm, 0) as avg_heartrate_bpm,
        case
            when total_moving_time_seconds > 0
                then round((total_distance_km / (total_moving_time_seconds / 3600.0)), 1)
            else null
        end as avg_speed_kmh
    from monthly
)

select
    sport_type,
    activity_year,
    month_start,
    month_number,
    month_label,
    activity_count,
    total_distance_km,
    total_elevation_meters,
    total_moving_time_hours,
    avg_heartrate_bpm,
    avg_speed_kmh
from final
