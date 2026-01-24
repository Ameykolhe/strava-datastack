select
    sport_type,
    sport_slug,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours
from dbt_sandbox_reporting.rpt_activities_by_sport__sport_type
