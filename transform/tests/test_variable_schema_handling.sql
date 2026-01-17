/*
Test: Variable schema handling
Purpose: Ensure models handle missing optional columns gracefully
This test verifies that activities without certain sensor data still process correctly
*/

with activities as (
    select * from {{ ref('fct_activities') }}
)

, schema_validation as (
    select
        count(*) as total_activities
        , count(hr_avg) as activities_with_hr
        , count(power_avg) as activities_with_power
        , count(kilojoules) as activities_with_kilojoules
        /* Ensure we can handle activities without these optional fields */
        , count(case when hr_avg is null then 1 end) as activities_without_hr
        , count(case when power_avg is null then 1 end) as activities_without_power

    from activities
)

/* This test passes if we successfully loaded activities with varying schemas */
/* Fail only if ALL activities are null for all optional fields (indicates a parsing error) */
select
    'All optional sensor data is null across all activities' as validation_error
from schema_validation
where
    total_activities > 0
    and activities_with_hr = 0
    and activities_with_power = 0
    and activities_with_kilojoules = 0
    and activities_without_hr = total_activities
    and activities_without_power = total_activities