{{
    config(
        materialized='table'
    )
}}

with activities_with_routes as (
    select
        extract(year from started_at) as activity_year,
        map_summary_polyline
    from {{ ref('fct_activities') }}
    where map_summary_polyline is not null
)

select
    activity_year,
    -- Convert array to JSON string so Evidence preserves the structure
    to_json(list(map_summary_polyline)) as polylines,
    count(*) as route_count
from activities_with_routes
group by activity_year
order by activity_year desc