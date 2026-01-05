SELECT
    COUNT(*) as total_activities,
    SUM(distance_metric) as total_distance_km,
    SUM(distance) as total_distance_miles,
    SUM(moving_seconds) / 3600.0 as total_moving_hours,
    SUM(elevation_gain / 3.28084) as total_elevation_meters,
    AVG(speed_avg_metric) as avg_speed_kmh,
    MAX(speed_max_metric) as max_speed_kmh,
    AVG(hr_avg) as avg_heartrate,
    MAX(hr_max) as max_heartrate,
    SUM(kilojoules) as total_kilojoules,
    SUM(kudos_count) as total_kudos
FROM dbt_sandbox.fct_activities