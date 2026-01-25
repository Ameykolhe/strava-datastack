{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for activity streaks by sport type and year.
    Grain: One row per sport_type per activity_year.
*/

with activity_dates as (
    select
        sport_type,
        activity_year,
        activity_date
    from {{ ref('fct_strava__activities') }}
    where activity_date is not null
),

max_date as (
    select
        sport_type,
        activity_year,
        max(activity_date) as max_activity_date
    from activity_dates
    group by sport_type, activity_year
),

numbered as (
    select
        sport_type,
        activity_year,
        activity_date,
        row_number() over (
            partition by sport_type, activity_year
            order by activity_date
        ) as rn
    from activity_dates
),

streaks as (
    select
        sport_type,
        activity_year,
        activity_date,
        activity_date - rn::integer as streak_group
    from numbered
),

streak_lengths as (
    select
        sport_type,
        activity_year,
        streak_group,
        min(activity_date) as streak_start_date,
        max(activity_date) as streak_end_date,
        count(*) as streak_length
    from streaks
    group by sport_type, activity_year, streak_group
),

current_streak as (
    select
        sl.sport_type,
        sl.activity_year,
        sl.streak_length as current_streak,
        sl.streak_start_date,
        sl.streak_end_date
    from streak_lengths sl
    join max_date md
        on sl.sport_type = md.sport_type
        and sl.activity_year = md.activity_year
        and sl.streak_end_date = md.max_activity_date
),

longest_streak as (
    select
        sport_type,
        activity_year,
        max(streak_length) as longest_streak
    from streak_lengths
    group by sport_type, activity_year
),

last_30 as (
    select
        ad.sport_type,
        ad.activity_year,
        count(*) as active_days_last_30
    from activity_dates ad
    join max_date md
        on ad.sport_type = md.sport_type
        and ad.activity_year = md.activity_year
    where ad.activity_date >= (md.max_activity_date - interval '29 days')
    group by ad.sport_type, ad.activity_year
),

active_days as (
    select
        sport_type,
        activity_year,
        count(*) as active_days_year
    from activity_dates
    group by sport_type, activity_year
)

select
    md.sport_type,
    lower(md.sport_type) as sport_slug,
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
    on md.sport_type = cs.sport_type
    and md.activity_year = cs.activity_year
left join longest_streak ls
    on md.sport_type = ls.sport_type
    and md.activity_year = ls.activity_year
left join last_30 l30
    on md.sport_type = l30.sport_type
    and md.activity_year = l30.activity_year
left join active_days ad
    on md.sport_type = ad.sport_type
    and md.activity_year = ad.activity_year
