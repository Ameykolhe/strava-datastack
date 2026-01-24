select
    activity_year,
    activity_count,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    longest_distance_miles,
    hardest_elevation_gain_feet
from dbt_sandbox_reporting.rpt_year_kpis__year
