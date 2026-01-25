{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for sport-level trends (all time).
    Grain: One row per sport_type per month.
*/

with date_bounds as (
    select
        sport_type,
        min(activity_date) as min_activity_date,
        max(activity_date) as max_activity_date
    from {{ ref('fct_strava__activities') }}
    group by sport_type
),

activities as (
    select
        sport_type,
        started_at_local,
        distance_km,
        elevation_gain_meters,
        moving_time_seconds,
        average_heartrate_bpm
    from {{ ref('fct_strava__activities') }}
),

months as (
    select
        b.sport_type,
        month_start
    from date_bounds b,
    generate_series(
        date_trunc('month', b.min_activity_date)::date,
        date_trunc('month', b.max_activity_date)::date,
        interval '1 month'
    ) as t(month_start)
),

spine as (
    select
        m.sport_type,
        m.month_start
    from months m
),

monthly as (
    select
        sport_type,
        date_trunc('month', started_at_local)::date as month_start,
        extract(year from started_at_local)::int as activity_year,
        extract(month from started_at_local)::int as month_number,
        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(elevation_gain_meters) as total_elevation_meters,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours,
        avg(average_heartrate_bpm) as avg_heartrate_bpm,
        sum(moving_time_seconds) as total_moving_time_seconds
    from activities a
    group by sport_type, month_start, activity_year, month_number
),

final as (
    select
        s.sport_type,
        extract(year from s.month_start)::int as activity_year,
        s.month_start,
        extract(month from s.month_start)::int as month_number,
        strftime(s.month_start, '%Y-%m') as month_label,
        coalesce(m.activity_count, 0) as activity_count,
        round(coalesce(m.total_distance_km, 0), 1) as total_distance_km,
        round(coalesce(m.total_elevation_meters, 0), 0) as total_elevation_meters,
        round(coalesce(m.total_moving_time_hours, 0), 1) as total_moving_time_hours,
        round(m.avg_heartrate_bpm, 0) as avg_heartrate_bpm,
        case
            when m.total_moving_time_seconds > 0
                then round((m.total_distance_km / (m.total_moving_time_seconds / 3600.0)), 1)
            else null
        end as avg_speed_kmh
    from spine s
    left join monthly m
        on s.sport_type = m.sport_type
        and s.month_start = m.month_start
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
order by sport_type, month_start
