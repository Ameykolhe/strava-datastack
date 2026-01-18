with activities as (
    select * from {{ ref('fct_activities') }}
),

daily_counts as (
    select
        started_at_local::date as activity_date,
        count(*) as activity_count
    from activities
    group by started_at_local::date
)

select * from daily_counts
order by activity_date
