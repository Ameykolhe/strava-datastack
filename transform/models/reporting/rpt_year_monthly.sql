{{
    config(
        materialized='table'
    )
}}

with activities as (
    select * from {{ ref('fct_activities') }}
),

years as (
    select distinct
        extract(year from started_at_local) as year
    from activities
),

months as (
    select *
    from (
        values
            (1, 'Jan'),
            (2, 'Feb'),
            (3, 'Mar'),
            (4, 'Apr'),
            (5, 'May'),
            (6, 'Jun'),
            (7, 'Jul'),
            (8, 'Aug'),
            (9, 'Sep'),
            (10, 'Oct'),
            (11, 'Nov'),
            (12, 'Dec')
    ) as m(month, month_name)
),

year_months as (
    select
        y.year,
        m.month,
        m.month_name,
        cast(
            y.year || '-' || lpad(cast(m.month as varchar), 2, '0') || '-01'
            as date
        ) as month_start_date
    from years y
    cross join months m
    where
        cast(
            y.year || '-' || lpad(cast(m.month as varchar), 2, '0') || '-01'
            as date
        ) <= date_trunc('month', current_date)::date
),

monthly_stats as (
    select
        date_trunc('month', started_at_local)::date as month_start_date,
        extract(year from started_at_local) as year,
        extract(month from started_at_local) as month,
        count(*) as activity_count,
        sum(distance) as total_distance,
        sum(moving_seconds) as total_moving_time,
        sum(elevation_gain) as total_elevation_gain
    from activities
    group by
        date_trunc('month', started_at_local)::date,
        extract(year from started_at_local),
        extract(month from started_at_local)
)

select
    year_months.month_start_date,
    year_months.year,
    year_months.month,
    year_months.month_name,
    coalesce(monthly_stats.activity_count, 0) as activity_count,
    coalesce(monthly_stats.total_distance, 0) as total_distance,
    coalesce(monthly_stats.total_moving_time, 0) as total_moving_time,
    coalesce(monthly_stats.total_elevation_gain, 0) as total_elevation_gain
from year_months
left join monthly_stats
    on year_months.year = monthly_stats.year
    and year_months.month = monthly_stats.month
order by
    year_months.year,
    year_months.month
