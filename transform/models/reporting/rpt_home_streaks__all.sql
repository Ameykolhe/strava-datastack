{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for activity streaks and recent activity days.
    Grain: Single row (all activities).
*/

with activity_dates as (
    select
        distinct activity_date
    from {{ ref('fct_strava__activities') }}
    where activity_date is not null
),

max_date as (
    select
        max(activity_date) as max_activity_date
    from activity_dates
),

numbered as (
    select
        activity_date,
        row_number() over (order by activity_date) as rn
    from activity_dates
),

streaks as (
    select
        activity_date,
        activity_date - rn::integer as streak_group
    from numbered
),

streak_lengths as (
    select
        streak_group,
        min(activity_date) as streak_start_date,
        max(activity_date) as streak_end_date,
        count(*) as streak_length
    from streaks
    group by streak_group
),

current_streak as (
    select
        sl.streak_length as current_streak,
        sl.streak_start_date,
        sl.streak_end_date
    from streak_lengths sl
    join max_date md
        on sl.streak_end_date = md.max_activity_date
),

longest_streak as (
    select
        max(streak_length) as longest_streak
    from streak_lengths
),

last_30 as (
    select
        count(*) as active_days_last_30
    from activity_dates ad
    cross join max_date md
    where ad.activity_date >= (md.max_activity_date - interval '29 days')
)

select
    md.max_activity_date,
    cs.current_streak,
    cs.streak_start_date as current_streak_start_date,
    cs.streak_end_date as current_streak_end_date,
    ls.longest_streak,
    l30.active_days_last_30
from max_date md
left join current_streak cs
    on true
left join longest_streak ls
    on true
left join last_30 l30
    on true
