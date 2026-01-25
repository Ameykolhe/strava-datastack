select
    sport_type,
    sport_slug,
    activity_year,
    month_start,
    month_number,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_feet,
    avg_heartrate_bpm,
    avg_speed_kmh
from dbt_sandbox_reporting.rpt_year_sport_monthly__sport_type_month
