select
    sport_type,
    sport_slug,
    activity_year,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_mph,
    avg_speed_kmh,
    avg_pace_min_per_km,
    avg_heartrate_bpm,
    longest_distance_miles,
    hardest_elevation_gain_feet
from dbt_sandbox_reporting.rpt_kpis__all
where grain = 'sport_type_year'
