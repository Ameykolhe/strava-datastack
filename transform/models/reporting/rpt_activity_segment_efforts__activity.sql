{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for activity segment efforts table.
    Grain: One row per segment effort.
*/

with efforts as (
    select *
    from {{ ref('fct_strava__segment_efforts') }}
)

select
    effort_id,
    activity_id,
    segment_id,
    segment_name,
    distance_km,
    round(distance_meters / 1609.344, 2) as distance_miles,
    elapsed_time_seconds,
    {{ seconds_to_time_display('elapsed_time_seconds') }} as time_display,
    {{ seconds_to_time_display('elapsed_time_seconds') }} as elapsed_time_display,
    average_speed_kph,
    round(average_speed_kph / 1.60934, 2) as average_speed_mph,
    pace_min_per_km,
    round(pace_min_per_km * 1.60934, 2) as pace_min_per_mile,
    segment_average_grade as average_grade,
    segment_climb_category as climb_category,
    case segment_climb_category
        when 5 then 'HC'
        when 4 then 'Cat 1'
        when 3 then 'Cat 2'
        when 2 then 'Cat 3'
        when 1 then 'Cat 4'
        else 'NC'
    end as climb_category_label,
    pr_rank,
    is_pr,
    kom_rank,
    has_kom_rank,
    average_heartrate_bpm,
    max_heartrate_bpm,
    start_index
from efforts
where not is_hidden
