{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for sport-level monthly trends by year.
    Grain: One row per sport_type per activity_year per month.
    Primary key: (sport_type, activity_year, month_number)
*/

with activities as (
    select
        sport_type,
        activity_year,
        started_at_local,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elevation_gain_feet,
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
        sum(distance_miles) as total_distance_miles,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours,
        sum(elevation_gain_feet) as total_elevation_feet,
        avg(average_heartrate_bpm) as avg_heartrate_bpm,
        sum(moving_time_seconds) as total_moving_time_seconds
    from activities
    group by sport_type, activity_year, month_start, month_number
),

sport_years as (
    select distinct
        sport_type,
        activity_year
    from activities
),

calendar_months as (
    select
        sy.sport_type,
        sy.activity_year,
        gs.month_start::date as month_start,
        extract(month from gs.month_start)::int as month_number,
        strftime(gs.month_start, '%Y-%m') as month_label
    from sport_years sy
    cross join generate_series(
        make_date(sy.activity_year, 1, 1),
        case
            when sy.activity_year = extract(year from current_date)
                then date_trunc('month', current_date)
            else make_date(sy.activity_year, 12, 1)
        end,
        interval '1 month'
    ) as gs(month_start)
),

final as (
    select
        cm.sport_type,
        lower(cm.sport_type) as sport_slug,
        cm.activity_year,
        cm.month_start,
        cm.month_number,
        cm.month_label,
        coalesce(m.activity_count, 0) as activity_count,
        coalesce(round(m.total_distance_km, 1), 0) as total_distance_km,
        coalesce(round(m.total_distance_miles, 1), 0) as total_distance_miles,
        coalesce(round(m.total_moving_time_hours, 1), 0) as total_moving_time_hours,
        coalesce(round(m.total_elevation_feet, 0), 0) as total_elevation_feet,
        case
            when m.avg_heartrate_bpm is not null then round(m.avg_heartrate_bpm, 0)
            else null
        end as avg_heartrate_bpm,
        case
            when m.total_moving_time_seconds > 0
                then round((m.total_distance_km / (m.total_moving_time_seconds / 3600.0)), 1)
            else null
        end as avg_speed_kmh
    from calendar_months cm
    left join monthly m
        on cm.sport_type = m.sport_type
        and cm.activity_year = m.activity_year
        and cm.month_start = m.month_start
)

select
    sport_type,
    sport_slug,
    activity_year,
    month_start,
    month_number,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_feet,
    avg_heartrate_bpm,
    avg_speed_kmh
from final
order by sport_type, activity_year, month_start
