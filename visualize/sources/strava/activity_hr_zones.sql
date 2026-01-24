select
    activity_id,
    zone_id,
    zone_name,
    zone_min_bpm,
    zone_max_bpm,
    time_seconds,
    time_minutes,
    pct_in_zone
from dbt_sandbox_reporting.rpt_activity_hr_zones__activity_zone
order by activity_id, zone_id
