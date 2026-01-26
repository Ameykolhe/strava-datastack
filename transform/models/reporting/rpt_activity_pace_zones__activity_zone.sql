{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for pace zone distributions.
    Grain: One row per activity per zone.
    Primary key: (activity_id, zone_id)
*/

with zones as (
    select
        activity_id,
        distribution_buckets
    from {{ ref('stg_strava__activity_zones') }}
    where zone_type = 'pace'
      and distribution_buckets is not null
),

buckets as (
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
    from zones
    cross join range(0, cast(json_array_length(distribution_buckets) as bigint)) as r(idx)
    cross join lateral (
        select json_extract(distribution_buckets, '$[' || idx::varchar || ']') as bucket
    ) as b
),

final as (
    select
        activity_id,
        zone_id,
        zone_name,
        case
            when zone_min_speed_mps > 0 then 1000.0 / zone_min_speed_mps
            else null
        end as zone_min_pace_sec,
        case
            when zone_max_speed_mps > 0 then 1000.0 / zone_max_speed_mps
            else null
        end as zone_max_pace_sec,
        time_seconds,
        round(time_seconds / 60.0, 2) as time_minutes,
        case
            when sum(time_seconds) over (partition by activity_id) = 0 then null
            else time_seconds
                / sum(time_seconds) over (partition by activity_id)
        end as pct_in_zone
    from buckets
),

formatted as (
    select
        activity_id,
        zone_id,
        zone_name,
        zone_min_pace_sec,
        zone_max_pace_sec,
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
        time_seconds,
        time_minutes,
        pct_in_zone
    from final
)

select
    activity_id,
    zone_id,
    zone_name,
    zone_min_pace,
    zone_max_pace,
    zone_min_pace_sec,
    zone_max_pace_sec,
    time_seconds,
    time_minutes,
    pct_in_zone
from formatted
