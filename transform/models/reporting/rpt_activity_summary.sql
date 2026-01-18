with activities as (
    select * from {{ ref('fct_activities') }}
),

summary as (
    select
        count(*) as total_activities,
        count(distinct date_trunc('day', started_at)) as total_active_days,
        sum(moving_seconds) / 3600.0 as total_hours,
        sum(distance) as total_distance_miles,
        sum(elevation_gain) as total_elevation_gain_feet
    from activities
)

select * from summary
