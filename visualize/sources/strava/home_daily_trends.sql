select
    activity_date,
    activity_year,
    activity_count,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_mph
from dbt_sandbox_reporting.rpt_home_daily_trends__day
