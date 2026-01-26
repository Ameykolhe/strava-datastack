{{
    config(
        materialized='table'
    )
}}

/*
    Consolidated reporting model for KPIs across multiple grains.
    Grain column indicates the aggregation level.
*/

with activities as (
    select
        sport_type,
        lower(sport_type) as sport_slug,
        activity_year,
        activity_date,
        date_trunc('month', activity_date)::date as month_start,
        extract(month from activity_date)::int as month_number,
        strftime(date_trunc('month', activity_date)::date, '%Y-%m') as month_label,
        strftime(date_trunc('month', activity_date)::date, '%b') as month_name,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elevation_gain_feet,
        average_heartrate_bpm
    from {{ ref('fct_strava__activities') }}
    where activity_date is not null
),

bounds as (
    select
        min(activity_date) as min_activity_date,
        greatest(max(activity_date), current_date) as max_activity_date,
        min(activity_year) as min_year,
        greatest(max(activity_year), extract(year from current_date)) as max_year
    from activities
),

years as (
    select
        activity_year
    from bounds b
    cross join generate_series(b.min_year, b.max_year) as t(activity_year)
),

months as (
    select
        month_start,
        extract(year from month_start)::int as activity_year,
        extract(month from month_start)::int as month_number,
        strftime(month_start, '%Y-%m') as month_label,
        strftime(month_start, '%b') as month_name
    from bounds b,
    generate_series(
        date_trunc('month', b.min_activity_date)::date,
        date_trunc('month', b.max_activity_date)::date,
        interval '1 month'
    ) as t(month_start)
),

sports as (
    select distinct
        sport_type,
        sport_slug
    from activities
),

sport_years as (
    select
        s.sport_type,
        s.sport_slug,
        y.activity_year
    from sports s
    cross join years y
),

sport_bounds as (
    select
        sport_type,
        sport_slug,
        date_trunc('month', min(activity_date))::date as min_month,
        date_trunc('month', greatest(max(activity_date), current_date))::date as max_month
    from activities
    group by sport_type, sport_slug
),

sport_months as (
    select
        b.sport_type,
        b.sport_slug,
        month_start,
        extract(year from month_start)::int as activity_year,
        extract(month from month_start)::int as month_number,
        strftime(month_start, '%Y-%m') as month_label,
        strftime(month_start, '%b') as month_name
    from sport_bounds b,
    generate_series(b.min_month, b.max_month, interval '1 month') as t(month_start)
),

grain_dimensions as (
    select
        'all' as grain,
        cast(null as varchar) as sport_type,
        cast(null as varchar) as sport_slug,
        cast(null as integer) as activity_year,
        cast(null as date) as month_start,
        cast(null as integer) as month_number,
        cast(null as varchar) as month_label,
        cast(null as varchar) as month_name

    union all

    select
        'year' as grain,
        cast(null as varchar) as sport_type,
        cast(null as varchar) as sport_slug,
        activity_year,
        cast(null as date) as month_start,
        cast(null as integer) as month_number,
        cast(null as varchar) as month_label,
        cast(null as varchar) as month_name
    from years

    union all

    select
        'year_month' as grain,
        cast(null as varchar) as sport_type,
        cast(null as varchar) as sport_slug,
        activity_year,
        month_start,
        month_number,
        month_label,
        month_name
    from months

    union all

    select
        'sport_type' as grain,
        sport_type,
        sport_slug,
        cast(null as integer) as activity_year,
        cast(null as date) as month_start,
        cast(null as integer) as month_number,
        cast(null as varchar) as month_label,
        cast(null as varchar) as month_name
    from sports

    union all

    select
        'sport_type_year' as grain,
        sport_type,
        sport_slug,
        activity_year,
        cast(null as date) as month_start,
        cast(null as integer) as month_number,
        cast(null as varchar) as month_label,
        cast(null as varchar) as month_name
    from sport_years

    union all

    select
        'sport_type_year_month' as grain,
        sport_type,
        sport_slug,
        activity_year,
        month_start,
        month_number,
        month_label,
        month_name
    from sport_months
),

aggregated as (
    select
        sport_type,
        sport_slug,
        activity_year,
        month_start,
        month_number,
        month_label,
        month_name,
        count(*) as activity_count,
        sum(distance_km) as total_distance_km,
        sum(distance_miles) as total_distance_miles,
        sum(moving_time_seconds) as total_moving_time_seconds,
        sum(moving_time_seconds) / 3600.0 as total_moving_time_hours,
        sum(elevation_gain_feet) as total_elevation_gain_feet,
        max(distance_miles) as longest_distance_miles,
        max(elevation_gain_feet) as hardest_elevation_gain_feet,
        avg(average_heartrate_bpm) as avg_heartrate_bpm
    from activities
    group by grouping sets (
        (),
        (activity_year),
        (activity_year, month_start, month_number, month_label, month_name),
        (sport_type, sport_slug),
        (sport_type, sport_slug, activity_year),
        (sport_type, sport_slug, activity_year, month_start, month_number, month_label, month_name)
    )
),

final as (
    select
        d.grain,
        d.sport_type,
        d.sport_slug,
        d.activity_year,
        d.month_start,
        d.month_number,
        d.month_label,
        d.month_name,
        coalesce(a.activity_count, 0) as activity_count,
        coalesce(a.total_distance_km, 0) as total_distance_km,
        coalesce(a.total_distance_miles, 0) as total_distance_miles,
        coalesce(a.total_moving_time_seconds, 0) as total_moving_time_seconds,
        coalesce(a.total_moving_time_hours, 0) as total_moving_time_hours,
        coalesce(a.total_elevation_gain_feet, 0) as total_elevation_gain_feet,
        a.longest_distance_miles as longest_distance_miles,
        a.hardest_elevation_gain_feet as hardest_elevation_gain_feet,
        a.avg_heartrate_bpm as avg_heartrate_bpm
    from grain_dimensions d
    left join aggregated a
        on d.sport_type is not distinct from a.sport_type
        and d.sport_slug is not distinct from a.sport_slug
        and d.activity_year is not distinct from a.activity_year
        and d.month_start is not distinct from a.month_start
        and d.month_number is not distinct from a.month_number
        and d.month_label is not distinct from a.month_label
        and d.month_name is not distinct from a.month_name
)

select
    grain,
    sport_type,
    sport_slug,
    activity_year,
    month_start,
    month_number,
    month_label,
    month_name,
    activity_count,
    round(total_distance_km, 1) as total_distance_km,
    round(total_distance_miles, 1) as total_distance_miles,
    round(total_moving_time_hours, 1) as total_moving_time_hours,
    round(total_elevation_gain_feet, 0) as total_elevation_gain_feet,
    case
        when total_moving_time_seconds > 0
            then round(total_distance_miles / (total_moving_time_seconds / 3600.0), 1)
        else null
    end as avg_speed_mph,
    case
        when total_moving_time_seconds > 0
            then round(total_distance_km / (total_moving_time_seconds / 3600.0), 1)
        else null
    end as avg_speed_kmh,
    case
        when total_distance_km > 0
            then round((total_moving_time_seconds / 60.0) / total_distance_km, 2)
        else null
    end as avg_pace_min_per_km,
    case
        when activity_count > 0 then round(avg_heartrate_bpm, 0)
        else null
    end as avg_heartrate_bpm,
    case
        when activity_count > 0 then round(longest_distance_miles, 1)
        else null
    end as longest_distance_miles,
    case
        when activity_count > 0 then round(hardest_elevation_gain_feet, 0)
        else null
    end as hardest_elevation_gain_feet
from final
order by
    grain,
    sport_type,
    activity_year,
    month_start
