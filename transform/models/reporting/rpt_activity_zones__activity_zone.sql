{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for all activity zone distributions (pace, power, heart rate).
    Grain: One row per activity per zone per zone_type.
    Primary key: (activity_id, zone_type, zone_id)

    Zone types:
    - 'pace': Pace zones with min/max pace (mm:ss format and seconds)
    - 'power': Power zones with min/max watts
    - 'heartrate': Heart rate zones with min/max bpm
*/

with pace_zones_raw as (
    select
        activity_id,
        distribution_buckets
    from {{ ref('stg_strava__activity_zones') }}
    where zone_type = 'pace'
      and distribution_buckets is not null
),

pace_buckets as (
    select
        activity_id,
        idx + 1 as zone_id,
        json_extract(bucket, '$.min')::double as zone_min_speed_mps,
        json_extract(bucket, '$.max')::double as zone_max_speed_mps,
        json_extract(bucket, '$.time')::double as time_seconds,
        coalesce(
            json_extract_string(bucket, '$.name'),
            json_extract_string(bucket, '$.zone'),
            'Zone ' || (idx + 1)::varchar
        ) as zone_name
    from pace_zones_raw
    cross join range(0, cast(json_array_length(distribution_buckets) as bigint)) as r(idx)
    cross join lateral (
        select json_extract(distribution_buckets, '$[' || idx::varchar || ']') as bucket
    ) as b
),

pace_zones as (
    select
        'pace' as zone_type,
        activity_id,
        zone_id,
        zone_name,
        -- Pace-specific fields
        case
            when zone_min_speed_mps > 0 then 1000.0 / zone_min_speed_mps
            else null
        end as zone_min_pace_sec,
        case
            when zone_max_speed_mps > 0 then 1000.0 / zone_max_speed_mps
            else null
        end as zone_max_pace_sec,
        -- Generic fields
        null::double as zone_min_value,
        null::double as zone_max_value,
        time_seconds,
        round(time_seconds / 60.0, 2) as time_minutes,
        case
            when sum(time_seconds) over (partition by activity_id) = 0 then null
            else time_seconds / sum(time_seconds) over (partition by activity_id)
        end as pct_in_zone
    from pace_buckets
),

pace_zones_formatted as (
    select
        zone_type,
        activity_id,
        zone_id,
        zone_name,
        case
            when zone_min_pace_sec is null then null
            else
                lpad(cast(floor(zone_min_pace_sec / 60.0) as varchar), 2, '0')
                || ':'
                || lpad(cast(cast(round(zone_min_pace_sec - floor(zone_min_pace_sec / 60.0) * 60.0, 0) as int) as varchar), 2, '0')
        end as zone_min_pace,
        case
            when zone_max_pace_sec is null then null
            else
                lpad(cast(floor(zone_max_pace_sec / 60.0) as varchar), 2, '0')
                || ':'
                || lpad(cast(cast(round(zone_max_pace_sec - floor(zone_max_pace_sec / 60.0) * 60.0, 0) as int) as varchar), 2, '0')
        end as zone_max_pace,
        zone_min_pace_sec,
        zone_max_pace_sec,
        zone_min_value,
        zone_max_value,
        time_seconds,
        time_minutes,
        pct_in_zone
    from pace_zones
),

power_zones_raw as (
    select
        activity_id,
        distribution_buckets
    from {{ ref('stg_strava__activity_zones') }}
    where zone_type = 'power'
      and distribution_buckets is not null
),

power_buckets as (
    select
        activity_id,
        idx + 1 as zone_id,
        json_extract(bucket, '$.min')::double as zone_min_watts,
        json_extract(bucket, '$.max')::double as zone_max_watts,
        json_extract(bucket, '$.time')::double as time_seconds,
        coalesce(
            json_extract_string(bucket, '$.name'),
            json_extract_string(bucket, '$.zone'),
            'Zone ' || (idx + 1)::varchar
        ) as zone_name
    from power_zones_raw
    cross join range(0, cast(json_array_length(distribution_buckets) as bigint)) as r(idx)
    cross join lateral (
        select json_extract(distribution_buckets, '$[' || idx::varchar || ']') as bucket
    ) as b
),

power_zones as (
    select
        'power' as zone_type,
        activity_id,
        zone_id,
        zone_name,
        -- Pace-specific fields (null for power)
        null::varchar as zone_min_pace,
        null::varchar as zone_max_pace,
        null::double as zone_min_pace_sec,
        null::double as zone_max_pace_sec,
        -- Generic fields
        zone_min_watts as zone_min_value,
        zone_max_watts as zone_max_value,
        time_seconds,
        round(time_seconds / 60.0, 2) as time_minutes,
        case
            when sum(time_seconds) over (partition by activity_id) = 0 then null
            else time_seconds / sum(time_seconds) over (partition by activity_id)
        end as pct_in_zone
    from power_buckets
),

hr_zones_raw as (
    select
        activity_id,
        distribution_buckets
    from {{ ref('stg_strava__activity_zones') }}
    where zone_type = 'heartrate'
      and distribution_buckets is not null
),

hr_buckets as (
    select
        activity_id,
        idx + 1 as zone_id,
        json_extract(bucket, '$.min')::double as zone_min_bpm,
        json_extract(bucket, '$.max')::double as zone_max_bpm,
        json_extract(bucket, '$.time')::double as time_seconds,
        coalesce(
            json_extract_string(bucket, '$.name'),
            json_extract_string(bucket, '$.zone'),
            'Zone ' || (idx + 1)::varchar
        ) as zone_name
    from hr_zones_raw
    cross join range(0, cast(json_array_length(distribution_buckets) as bigint)) as r(idx)
    cross join lateral (
        select json_extract(distribution_buckets, '$[' || idx::varchar || ']') as bucket
    ) as b
),

hr_zones as (
    select
        'heartrate' as zone_type,
        activity_id,
        zone_id,
        zone_name,
        -- Pace-specific fields (null for HR)
        null::varchar as zone_min_pace,
        null::varchar as zone_max_pace,
        null::double as zone_min_pace_sec,
        null::double as zone_max_pace_sec,
        -- Generic fields
        zone_min_bpm as zone_min_value,
        zone_max_bpm as zone_max_value,
        time_seconds,
        round(time_seconds / 60.0, 2) as time_minutes,
        case
            when sum(time_seconds) over (partition by activity_id) = 0 then null
            else time_seconds / sum(time_seconds) over (partition by activity_id)
        end as pct_in_zone
    from hr_buckets
),

combined as (
    select * from pace_zones_formatted
    union all
    select * from power_zones
    union all
    select * from hr_zones
)

select
    zone_type,
    activity_id,
    zone_id,
    zone_name,
    -- Pace-specific columns
    zone_min_pace,
    zone_max_pace,
    zone_min_pace_sec,
    zone_max_pace_sec,
    -- Generic zone value columns (watts for power, bpm for heartrate, null for pace)
    zone_min_value,
    zone_max_value,
    -- Common columns
    time_seconds,
    time_minutes,
    pct_in_zone
from combined