{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for home trends (all time).
    Grain: One row per month.
*/

with date_bounds as (
    select
        min(activity_date) as min_activity_date,
        max(activity_date) as max_activity_date
    from {{ ref('fct_strava__activities') }}
),

months as (
    select
        month_start
    from date_bounds b,
    generate_series(
        date_trunc('month', b.min_activity_date)::date,
        date_trunc('month', b.max_activity_date)::date,
        interval '1 month'
    ) as t(month_start)
),

activities as (
    select
        activity_date,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elevation_gain_feet
    from {{ ref('fct_strava__activities') }}
),

monthly as (
    select
        date_trunc('month', activity_date)::date as month_start,
        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(distance_miles) as total_distance_miles,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours,
        sum(elevation_gain_feet) as total_elevation_gain_feet
    from activities a
    group by date_trunc('month', activity_date)
),

final as (
    select
        m.month_start,
        strftime(m.month_start, '%Y-%m') as month_label,
        coalesce(monthly.activity_count, 0) as activity_count,
        round(coalesce(monthly.total_distance_km, 0), 1) as total_distance_km,
        round(coalesce(monthly.total_distance_miles, 0), 1) as total_distance_miles,
        round(coalesce(monthly.total_moving_time_hours, 0), 1) as total_moving_time_hours,
        round(coalesce(monthly.total_elevation_gain_feet, 0), 0) as total_elevation_gain_feet
    from months m
    left join monthly
        on m.month_start = monthly.month_start
)

select
    month_start,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet
from final
order by month_start
