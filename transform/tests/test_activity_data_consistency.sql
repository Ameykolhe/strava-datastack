/*
Test: Activity data consistency
Purpose: Ensure activities have consistent data (e.g., no negative speeds, reasonable durations)
*/

with activities as (
    select * from {{ ref('fct_activities') }}
)

, validation_failures as (
    select
        activity_id
        , activity_name
        , case
            when moving_seconds > elapsed_seconds then 'Moving time exceeds elapsed time'
            when distance < 0 then 'Negative distance'
            when speed_avg < 0 then 'Negative average speed'
            when elevation_gain < 0 then 'Negative elevation gain'
            when started_at > current_timestamp then 'Future start date'
            when hr_avg is not null and hr_avg < 30 then 'Unrealistic low heart rate'
            when hr_max is not null and hr_max > 250 then 'Unrealistic high heart rate'
            when power_avg is not null and power_avg < 0 then 'Negative power'
            when elapsed_seconds = 0 and distance > 0 then 'Distance without time'
            else null
        end as validation_error

    from activities
    where
        moving_seconds > elapsed_seconds
        or distance < 0
        or (speed_avg is not null and speed_avg < 0)
        or (elevation_gain is not null and elevation_gain < 0)
        or started_at > current_timestamp
        or (hr_avg is not null and hr_avg < 30)
        or (hr_max is not null and hr_max > 250)
        or (power_avg is not null and power_avg < 0)
        or (elapsed_seconds = 0 and distance > 0)
)

select *
from validation_failures