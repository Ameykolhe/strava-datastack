select
    sport_type,
    sport_slug,
    activity_year,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours
from dbt_sandbox_reporting.rpt_year_sport_summary__sport_type_year
