with activities as (
    select * from {{ ref('fct_activities') }}
),

by_sport as (
    select
        sport_type,
        count(*) as activity_count,
        sum(moving_seconds) / 3600.0 as total_moving_hours,
        avg(moving_seconds) / 3600.0 as avg_moving_hours
    from activities
    group by sport_type
)

select * from by_sport
order by activity_count desc
