{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for daily activity counts.
    Grain: One row per activity_date.
    Primary key: activity_date
*/

with daily as (
    select
        activity_date,
        activity_year,
        activity_count
    from {{ ref('rpt_home_daily_trends__day') }}
)

select
    activity_date,
    activity_year,
    activity_count
from daily
