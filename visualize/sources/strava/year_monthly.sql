select
    activity_year,
    month_start,
    month_number,
    month_label,
    month_name,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet
from dbt_sandbox_reporting.rpt_year_monthly__month
