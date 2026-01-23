{{
    config(
        materialized='view'
    )
}}

/*
    Staging model for dlt load metadata
    Grain: One row per load
    Primary key: load_id
*/

with source as (
    select * from {{ source('strava_raw', '_dlt_loads') }}
),

staged as (
    select
        -- Primary key
        load_id,

        -- Load metadata
        schema_name,
        status as load_status,
        inserted_at as loaded_at,
        schema_version_hash

    from source
)

select * from staged
