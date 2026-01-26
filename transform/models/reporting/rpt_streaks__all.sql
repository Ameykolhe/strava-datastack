{{
    config(
        materialized='table'
    )
}}

/*
    Consolidated reporting model for activity streaks across multiple grains.
    Grain column indicates the aggregation level.
*/

with activity_dates as (
    select distinct
        sport_type,
        lower(sport_type) as sport_slug,
        activity_year,
        activity_date
    from {{ ref('fct_strava__activities') }}
    where activity_date is not null
),

grouped_activity_dates as (
    select
        case
            when grouping(sport_type) = 1 and grouping(activity_year) = 1 then 'all'
            when grouping(sport_type) = 1 and grouping(activity_year) = 0 then 'year'
            else 'sport_type_year'
        end as grain,
        sport_type,
        sport_slug,
        activity_year,
        activity_date
    from activity_dates
    group by grouping sets (
        (activity_date),
        (activity_date, activity_year),
        (activity_date, sport_type, sport_slug, activity_year)
    )
),

max_date as (
    select
        grain,
        sport_type,
        sport_slug,
        activity_year,
        max(activity_date) as max_activity_date
    from grouped_activity_dates
    group by grain, sport_type, sport_slug, activity_year
),

numbered as (
    select
        grain,
        sport_type,
        sport_slug,
        activity_year,
        activity_date,
        row_number() over (
            partition by grain, sport_type, sport_slug, activity_year
            order by activity_date
        ) as rn
    from grouped_activity_dates
),

streaks as (
    select
        grain,
        sport_type,
        sport_slug,
        activity_year,
        activity_date,
        activity_date - rn::integer as streak_group
    from numbered
),

streak_lengths as (
    select
        grain,
        sport_type,
        sport_slug,
        activity_year,
        streak_group,
        min(activity_date) as streak_start_date,
        max(activity_date) as streak_end_date,
        count(*) as streak_length
    from streaks
    group by grain, sport_type, sport_slug, activity_year, streak_group
),

current_streak as (
    select
        sl.grain,
        sl.sport_type,
        sl.sport_slug,
        sl.activity_year,
        sl.streak_length as current_streak,
        sl.streak_start_date,
        sl.streak_end_date
    from streak_lengths sl
    join max_date md
        on sl.grain = md.grain
        and sl.sport_type is not distinct from md.sport_type
        and sl.sport_slug is not distinct from md.sport_slug
        and sl.activity_year is not distinct from md.activity_year
        and sl.streak_end_date = md.max_activity_date
),

longest_streak as (
    select
        grain,
        sport_type,
        sport_slug,
        activity_year,
        max(streak_length) as longest_streak
    from streak_lengths
    group by grain, sport_type, sport_slug, activity_year
),

last_30 as (
    select
        ad.grain,
        ad.sport_type,
        ad.sport_slug,
        ad.activity_year,
        count(*) as active_days_last_30
    from grouped_activity_dates ad
    join max_date md
        on ad.grain = md.grain
        and ad.sport_type is not distinct from md.sport_type
        and ad.sport_slug is not distinct from md.sport_slug
        and ad.activity_year is not distinct from md.activity_year
    where ad.activity_date >= (md.max_activity_date - interval '29 days')
    group by ad.grain, ad.sport_type, ad.sport_slug, ad.activity_year
),

active_days as (
    select
        grain,
        sport_type,
        sport_slug,
        activity_year,
        count(*) as active_days_year
    from grouped_activity_dates
    where grain in ('year', 'sport_type_year')
    group by grain, sport_type, sport_slug, activity_year
)

select
    md.grain,
    md.sport_type,
    md.sport_slug,
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
    on md.grain = cs.grain
    and md.sport_type is not distinct from cs.sport_type
    and md.sport_slug is not distinct from cs.sport_slug
    and md.activity_year is not distinct from cs.activity_year
left join longest_streak ls
    on md.grain = ls.grain
    and md.sport_type is not distinct from ls.sport_type
    and md.sport_slug is not distinct from ls.sport_slug
    and md.activity_year is not distinct from ls.activity_year
left join last_30 l30
    on md.grain = l30.grain
    and md.sport_type is not distinct from l30.sport_type
    and md.sport_slug is not distinct from l30.sport_slug
    and md.activity_year is not distinct from l30.activity_year
left join active_days ad
    on md.grain = ad.grain
    and md.sport_type is not distinct from ad.sport_type
    and md.sport_slug is not distinct from ad.sport_slug
    and md.activity_year is not distinct from ad.activity_year
