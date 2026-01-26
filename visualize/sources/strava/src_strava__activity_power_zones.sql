select
    activity_id,
    zone_id,
    zone_name,
    zone_min_watts,
    zone_max_watts,
    time_seconds,
    time_minutes,
    pct_in_zone
from dbt_sandbox_reporting.rpt_activity_power_zones__activity_zone
order by activity_id, zone_id
