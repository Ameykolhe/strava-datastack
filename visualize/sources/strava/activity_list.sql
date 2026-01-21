select
    *,
    '/activity/' || sport_type || '/' || activity_id as activity_link
from dbt_sandbox.rpt_activity_list
order by started_at desc
