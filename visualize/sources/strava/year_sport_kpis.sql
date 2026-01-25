select
    sport_type,
    sport_slug,
    activity_year,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_heartrate_bpm,
    avg_speed_kmh,
    avg_pace_min_per_km
from dbt_sandbox_reporting.rpt_year_sport_kpis__sport_type_year
