{{
    config(
        materialized='view'
    )
}}

/*
    Staging model for Strava activity zones.
    Grain: One row per activity per zone type.
    Primary key: (activity_id, zone_type)
*/

with source as (
    select * from {{ source('strava_raw', 'activity_zones') }}
),

staged as (
    select
        _activities_id as activity_id,
        type as zone_type,
        score,
        sensor_based,
        points,
        custom_zones,
        distribution_buckets,
        resource_state,
        _dlt_load_id,
        _dlt_id
    from source
)

select
    activity_id,
    zone_type,
    score,
    sensor_based,
    points,
    custom_zones,
    distribution_buckets,
    resource_state,
    _dlt_load_id,
    _dlt_id
from staged
