{{
    config(
        materialized='table'
    )
}}

with activities as (
    select * from {{ ref('fct_activities') }}
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

select * from monthly_stats
order by month_start_date
