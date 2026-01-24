select
    activity_year,
    to_json(polylines) as polylines
from dbt_sandbox_reporting.rpt_year_routes__year
