{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for yearly route polylines.
    Grain: One row per activity_year.
    Primary key: activity_year
*/

with activities as (
    select
        activity_year,
        polyline
    from {{ ref('fct_strava__activities') }}
    where polyline is not null
        and trim(polyline) != ''
),

aggregated as (
    select
        activity_year,
        list(polyline) as polylines
    from activities
    group by activity_year
)

select
    activity_year,
    polylines
from aggregated
