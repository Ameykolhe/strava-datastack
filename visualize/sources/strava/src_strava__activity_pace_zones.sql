select
    activity_id,
    zone_id,
    zone_name,
    zone_min_pace,
    zone_max_pace,
    zone_min_pace_sec,
    zone_max_pace_sec,
    time_seconds,
    time_minutes,
    pct_in_zone
from dbt_sandbox_reporting.rpt_activity_pace_zones__activity_zone
order by activity_id, zone_id
