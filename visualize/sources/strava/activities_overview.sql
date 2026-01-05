SELECT
    activity_id,
    activity_name as name,
    activity_type,
    sport_type,
    started_at_local as start_date_local,
    distance_metric as distance_km,
    distance as distance_miles,
    moving_seconds / 60.0 as moving_time_minutes,
    elapsed_seconds / 60.0 as elapsed_time_minutes,
    elevation_gain / 3.28084 as elevation_gain_meters,
    speed_avg_metric as avg_speed_kmh,
    speed_max_metric as max_speed_kmh,
    hr_avg as average_heartrate,
    hr_max as max_heartrate,
    power_avg as average_watts,
    kilojoules,
    suffer_score,
    kudos_count,
    achievement_count,
    pr_count
FROM dbt_sandbox.fct_activities
ORDER BY started_at_local DESC