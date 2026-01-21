{{
    config(
        materialized='table'
    )
}}

with activities as (
    select * from {{ ref('fct_activities') }}
),

activity_list as (
    select
        activity_id,
        activity_name,
        started_at,
        started_at_local,
        sport_type,
        distance,
        moving_seconds,
        elevation_gain,
        hr_avg,
        power_avg
    from activities
)

select * from activity_list
order by started_at desc
