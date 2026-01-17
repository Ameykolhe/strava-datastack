/*
Test: Stream data consistency
Purpose: Ensure activity data points have consistent time-series data
*/

with data_points as (
    select * from {{ ref('fct_activity_data_points') }}
)

, validation_failures as (
    select
        activity_data_point_id
        , activity_id
        , stream_index
        , case
            when time < 0 then 'Negative time'
            when distance < 0 then 'Negative distance'
            when time_delta < 0 then 'Negative time delta'
            when distance_delta < 0 then 'Negative distance delta'
            when velocity < 0 then 'Negative velocity'
            when latitude is not null and (latitude < -90 or latitude > 90) then 'Invalid latitude'
            when longitude is not null and (longitude < -180 or longitude > 180) then 'Invalid longitude'
            when heartrate is not null and (heartrate < 0 or heartrate > 300) then 'Invalid heartrate'
            when altitude is not null and (altitude < -500 or altitude > 9000) then 'Invalid altitude'
            when grade is not null and (grade < -100 or grade > 100) then 'Invalid grade'
            else null
        end as validation_error

    from data_points
    where
        (time is not null and time < 0)
        or (distance is not null and distance < 0)
        or (time_delta is not null and time_delta < 0)
        or (distance_delta is not null and distance_delta < 0)
        or (velocity is not null and velocity < 0)
        or (latitude is not null and (latitude < -90 or latitude > 90))
        or (longitude is not null and (longitude < -180 or longitude > 180))
        or (heartrate is not null and (heartrate < 0 or heartrate > 300))
        or (altitude is not null and (altitude < -500 or altitude > 9000))
        or (grade is not null and (grade < -100 or grade > 100))
)

select *
from validation_failures