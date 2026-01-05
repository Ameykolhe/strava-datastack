SELECT
    DATE_TRUNC('month', started_at_local) as month,
    sport_type,
    COUNT(*) as activity_count,
    SUM(distance_metric) as total_distance_km,
    SUM(moving_seconds) / 3600.0 as total_moving_hours,
    AVG(speed_avg_metric) as avg_speed_kmh
FROM dbt_sandbox.fct_activities
GROUP BY DATE_TRUNC('month', started_at_local), sport_type
ORDER BY month DESC, sport_type