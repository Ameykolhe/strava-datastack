SELECT
    sport_type,
    COUNT(*) as activity_count,
    SUM(distance_metric) as total_distance_km,
    SUM(moving_seconds) / 3600.0 as total_moving_hours,
    AVG(distance_metric) as avg_distance_km,
    AVG(moving_seconds) / 60.0 as avg_moving_minutes,
    SUM(elevation_gain / 3.28084) as total_elevation_meters,
    AVG(speed_avg_metric) as avg_speed_kmh
FROM dbt_sandbox.fct_activities
GROUP BY sport_type
ORDER BY activity_count DESC