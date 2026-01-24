{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for distinct activity years.
    Grain: One row per activity_year.
    Primary key: activity_year
*/

with years as (
    select distinct activity_year
    from {{ ref('fct_strava__activities') }}
),

max_year as (
    select max(activity_year) as max_year
    from years
),

final as (
    select
        y.activity_year,
        m.max_year
    from years y
    cross join max_year m
)

select
    activity_year,
    max_year
from final
