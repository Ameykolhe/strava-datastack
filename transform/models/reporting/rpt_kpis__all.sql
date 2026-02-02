{{
    config(
        materialized='table'
    )
}}

/*
    Consolidated reporting model for KPIs across multiple grains.

    Grain column indicates the aggregation level:
    - all: Overall lifetime KPIs (1 row)
    - year: Yearly KPIs (one row per year from min to current, includes zeros)
    - day: Daily KPIs (only days with activities, no zero rows)
    - year_month: Monthly KPIs (one row per month from min to current, includes zeros)
    - sport_type: Per-sport lifetime KPIs (one row per sport)
    - sport_type_year: Per-sport yearly KPIs (sport × year, includes zeros)
    - sport_type_day: Per-sport daily KPIs (sport × day, only days with activities)
    - sport_type_year_month: Per-sport monthly KPIs (sport × month, includes zeros)

    Note: Day-level grains exclude zero-value rows (sparse data for calendars).
          Other grains include zeros for continuous chart rendering.
    Aggregates in one pass using GROUPING SETS for optimal performance.
*/

with activities as (
    select
        sport_type,
        lower(sport_type) as sport_slug,
        activity_year,
        activity_date,
        date_trunc('month', activity_date)::date as month_start,
        distance_km,
        distance_miles,
        moving_time_seconds,
        elevation_gain_feet,
        average_heartrate_bpm
    from {{ ref('fct_strava__activities') }}
    where activity_date is not null
),

-- Calculate date bounds for generating complete dimensions
date_bounds as (
    select
        min(activity_date) as min_date,
        current_date as max_date,
        extract(year from min(activity_date))::int as min_year,
        extract(year from current_date)::int as max_year,
        date_trunc('month', min(activity_date))::date as min_month,
        date_trunc('month', current_date)::date as max_month
    from activities
),

-- Get distinct sports
sports as (
    select distinct
        sport_type,
        sport_slug
    from activities
),

-- Calculate date bounds per sport
sport_bounds as (
    select
        sport_type,
        sport_slug,
        min(activity_date) as min_date,
        current_date as max_date,
        date_trunc('month', min(activity_date))::date as min_month,
        date_trunc('month', current_date)::date as max_month
    from activities
    group by sport_type, sport_slug
),

-- Aggregate activities using GROUPING SETS for all grains in one pass
-- Simplified: only group by identifying columns, not derived fields
aggregated as (
    select
        sport_type,
        sport_slug,
        activity_year,
        activity_date,
        month_start,
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
        (),                                           -- all
        (activity_year),                              -- year
        (activity_date),                              -- day
        (month_start),                                -- year_month
        (sport_type, sport_slug),                     -- sport_type
        (sport_type, sport_slug, activity_year),      -- sport_type_year
        (sport_type, sport_slug, activity_date),      -- sport_type_day
        (sport_type, sport_slug, month_start)         -- sport_type_year_month
    )
),

-- Generate all dimension combinations for complete date ranges
grain_dimensions as (
    -- all: One row for overall KPIs
    select
        'all' as grain,
        cast(null as varchar) as sport_type,
        cast(null as varchar) as sport_slug,
        cast(null as integer) as activity_year,
        cast(null as date) as activity_date,
        cast(null as date) as month_start

    union all

    -- year: One row per year from min to current
    select
        'year' as grain,
        cast(null as varchar) as sport_type,
        cast(null as varchar) as sport_slug,
        year_value as activity_year,
        cast(null as date) as activity_date,
        cast(null as date) as month_start
    from date_bounds
    cross join generate_series(date_bounds.min_year, date_bounds.max_year) as t(year_value)

    union all

    -- day: One row per day from min to current
    select
        'day' as grain,
        cast(null as varchar) as sport_type,
        cast(null as varchar) as sport_slug,
        cast(null as integer) as activity_year,
        day_value as activity_date,
        cast(null as date) as month_start
    from date_bounds
    cross join generate_series(date_bounds.min_date, date_bounds.max_date, interval '1 day') as t(day_value)

    union all

    -- year_month: One row per month from min to current
    select
        'year_month' as grain,
        cast(null as varchar) as sport_type,
        cast(null as varchar) as sport_slug,
        cast(null as integer) as activity_year,
        cast(null as date) as activity_date,
        month_value as month_start
    from date_bounds
    cross join generate_series(date_bounds.min_month, date_bounds.max_month, interval '1 month') as t(month_value)

    union all

    -- sport_type: One row per sport
    select
        'sport_type' as grain,
        sport_type,
        sport_slug,
        cast(null as integer) as activity_year,
        cast(null as date) as activity_date,
        cast(null as date) as month_start
    from sports

    union all

    -- sport_type_year: One row per sport × year (using sport's date range)
    select
        'sport_type_year' as grain,
        sb.sport_type,
        sb.sport_slug,
        year_value as activity_year,
        cast(null as date) as activity_date,
        cast(null as date) as month_start
    from sport_bounds sb
    cross join generate_series(extract(year from sb.min_date)::int, extract(year from sb.max_date)::int) as t(year_value)

    union all

    -- sport_type_day: One row per sport × day (using sport's date range)
    select
        'sport_type_day' as grain,
        sb.sport_type,
        sb.sport_slug,
        cast(null as integer) as activity_year,
        day_value as activity_date,
        cast(null as date) as month_start
    from sport_bounds sb
    cross join generate_series(sb.min_date, sb.max_date, interval '1 day') as t(day_value)

    union all

    -- sport_type_year_month: One row per sport × month (using sport's date range)
    select
        'sport_type_year_month' as grain,
        sb.sport_type,
        sb.sport_slug,
        cast(null as integer) as activity_year,
        cast(null as date) as activity_date,
        month_value as month_start
    from sport_bounds sb
    cross join generate_series(sb.min_month, sb.max_month, interval '1 month') as t(month_value)
),

-- Join dimensions with aggregated data
-- Key fix: Only join on identifying columns for each grain (not derived fields)
joined as (
    select
        d.grain,
        d.sport_type,
        d.sport_slug,
        -- Derive activity_year from available date fields
        coalesce(
            d.activity_year,
            extract(year from d.activity_date)::int,
            extract(year from d.month_start)::int
        ) as activity_year,
        d.activity_date,
        d.month_start,
        -- Derive month metadata from month_start
        extract(month from d.month_start)::int as month_number,
        strftime(d.month_start, '%Y-%m') as month_label,
        strftime(d.month_start, '%b') as month_name,
        -- Aggregate metrics with zero defaults
        coalesce(a.activity_count, 0) as activity_count,
        coalesce(a.total_distance_km, 0) as total_distance_km,
        coalesce(a.total_distance_miles, 0) as total_distance_miles,
        coalesce(a.total_moving_time_seconds, 0) as total_moving_time_seconds,
        coalesce(a.total_moving_time_hours, 0) as total_moving_time_hours,
        coalesce(a.total_elevation_gain_feet, 0) as total_elevation_gain_feet,
        a.longest_distance_miles,
        a.hardest_elevation_gain_feet,
        a.avg_heartrate_bpm
    from grain_dimensions d
    left join aggregated a
        on d.sport_type is not distinct from a.sport_type
        and d.sport_slug is not distinct from a.sport_slug
        and d.activity_year is not distinct from a.activity_year
        and d.activity_date is not distinct from a.activity_date
        and d.month_start is not distinct from a.month_start
)

-- Final output with calculated metrics
select
    grain,
    sport_type,
    sport_slug,
    activity_year,
    activity_date,
    month_start,
    month_number,
    month_label,
    month_name,
    activity_count,
    round(total_distance_km, 1) as total_distance_km,
    round(total_distance_miles, 1) as total_distance_miles,
    round(total_moving_time_hours, 1) as total_moving_time_hours,
    round(total_elevation_gain_feet, 0) as total_elevation_gain_feet,
    -- Average speed: miles per hour
    case
        when total_moving_time_seconds > 0
            then round(total_distance_miles / (total_moving_time_seconds / 3600.0), 1)
        else null
    end as avg_speed_mph,
    -- Average speed: kilometers per hour
    case
        when total_moving_time_seconds > 0
            then round(total_distance_km / (total_moving_time_seconds / 3600.0), 1)
        else null
    end as avg_speed_kmh,
    -- Average pace: minutes per kilometer
    case
        when total_distance_km > 0
            then round((total_moving_time_seconds / 60.0) / total_distance_km, 2)
        else null
    end as avg_pace_min_per_km,
    -- Only show aggregate metrics when there are activities
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
from joined
where
    -- Exclude zero-value rows for day-level grains (sparse data)
    -- Keep all rows (including zeros) for other grains (continuous charts)
    case
        when grain in ('day', 'sport_type_day') then activity_count > 0
        else true
    end
order by
    grain,
    sport_type,
    activity_year,
    activity_date,
    month_start