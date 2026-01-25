{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for activity streaks by year.
    Grain: One row per activity_year.
*/

with activity_dates as (
    select
        activity_year,
        activity_date
    from {{ ref('fct_strava__activities') }}
    where activity_date is not null
),

max_date as (
    select
        activity_year,
        max(activity_date) as max_activity_date
    from activity_dates
    group by activity_year
),

numbered as (
    select
        activity_year,
        activity_date,
        row_number() over (partition by activity_year order by activity_date) as rn
    from activity_dates
),

streaks as (
    select
        activity_year,
        activity_date,
        activity_date - rn::integer as streak_group
    from numbered
),

streak_lengths as (
    select
        activity_year,
        streak_group,
        min(activity_date) as streak_start_date,
        max(activity_date) as streak_end_date,
        count(*) as streak_length
    from streaks
    group by activity_year, streak_group
),

current_streak as (
    select
        sl.activity_year,
        sl.streak_length as current_streak,
        sl.streak_start_date,
        sl.streak_end_date
    from streak_lengths sl
    join max_date md
        on sl.activity_year = md.activity_year
        and sl.streak_end_date = md.max_activity_date
),

longest_streak as (
    select
        activity_year,
        max(streak_length) as longest_streak
    from streak_lengths
    group by activity_year
),

last_30 as (
    select
        ad.activity_year,
        count(*) as active_days_last_30
    from activity_dates ad
    join max_date md
        on ad.activity_year = md.activity_year
    where ad.activity_date >= (md.max_activity_date - interval '29 days')
    group by ad.activity_year
),

active_days as (
    select
        activity_year,
        count(*) as active_days_year
    from activity_dates
    group by activity_year
)

select
    md.activity_year,
    md.max_activity_date,
    cs.current_streak,
    cs.streak_start_date as current_streak_start_date,
    cs.streak_end_date as current_streak_end_date,
    ls.longest_streak,
    l30.active_days_last_30,
    ad.active_days_year
from max_date md
left join current_streak cs
    on md.activity_year = cs.activity_year
left join longest_streak ls
    on md.activity_year = ls.activity_year
left join last_30 l30
    on md.activity_year = l30.activity_year
left join active_days ad
    on md.activity_year = ad.activity_year
