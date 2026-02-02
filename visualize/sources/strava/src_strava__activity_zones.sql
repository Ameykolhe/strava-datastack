-- Activity zone distributions (heart rate, power, pace)
-- Filter by zone_type and/or activity_id in page queries
select
    activity_id,
    zone_type,
    zone_id,
    zone_name,
    zone_min_value,
    zone_max_value,
    time_seconds,
    time_minutes,
    pct_in_zone
from dbt_sandbox_reporting.rpt_activity_zones__activity_zone
order by activity_id, zone_type, zone_id