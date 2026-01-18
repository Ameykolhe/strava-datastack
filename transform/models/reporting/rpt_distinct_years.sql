with daily_counts as (
    select * from {{ ref('rpt_daily_activity_counts') }}
),

years as (
    select distinct
        year(activity_date) as activity_year
    from daily_counts
)

select
    activity_year,
    max(activity_year) over () as max_year
from years
order by activity_year desc
