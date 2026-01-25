select
    sport_type,
    activity_year,
    month_start,
    month_number,
    month_label,
    activity_count,
    total_distance_km,
    total_elevation_meters,
    total_moving_time_hours,
    avg_heartrate_bpm,
    avg_speed_kmh
from dbt_sandbox_reporting.rpt_sport_trends_12mo__sport_type_month
