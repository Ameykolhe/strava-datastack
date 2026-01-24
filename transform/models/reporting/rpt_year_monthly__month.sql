{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for monthly year rollups.
    Grain: One row per activity_year per month.
    Primary key: (activity_year, month_number)
*/

with activities as (
    select
        started_at_local,
        activity_year,
        distance_miles,
        elevation_gain_feet
    from {{ ref('fct_strava__activities') }}
),

monthly as (
    select
        activity_year,
        date_trunc('month', started_at_local)::date as month_start,
        extract(month from started_at_local)::int as month_number,
        count(*) as activity_count,
        sum(distance_miles) as total_distance_miles,
        sum(elevation_gain_feet) as total_elevation_gain_feet
    from activities
    group by activity_year, month_start, month_number
),

final as (
    select
        activity_year,
        month_start,
        month_number,
        strftime(month_start, '%b') as month_name,
        activity_count,
        round(total_distance_miles, 1) as total_distance_miles,
        round(total_elevation_gain_feet, 0) as total_elevation_gain_feet
    from monthly
)

select
    activity_year,
    month_start,
    month_number,
    month_name,
    activity_count,
    total_distance_miles,
    total_elevation_gain_feet
from final
