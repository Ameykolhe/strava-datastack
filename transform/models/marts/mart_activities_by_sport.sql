with activities as (
    select * from {{ ref('fct_activities') }}
),

by_sport as (
    select
        sport_type,
        count(*) as activity_count,
        sum(distance_metric) as total_distance_km,
        sum(moving_seconds) / 3600.0 as total_moving_hours,
        avg(distance_metric) as avg_distance_km,
        avg(moving_seconds) / 60.0 as avg_moving_minutes
    from activities
    group by sport_type
)

select * from by_sport
order by activity_count desc
