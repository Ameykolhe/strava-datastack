{{
    config(
        materialized='table'
    )
}}

/*
    Reporting model for power zone distributions.
    Grain: One row per activity per zone.
    Primary key: (activity_id, zone_id)
*/

with zones as (
    select
        activity_id,
        distribution_buckets
    from {{ ref('stg_strava__activity_zones') }}
    where zone_type = 'power'
      and distribution_buckets is not null
),

buckets as (
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
        zone_min_watts,
        zone_max_watts,
        time_seconds,
        round(time_seconds / 60.0, 2) as time_minutes,
        case
            when sum(time_seconds) over (partition by activity_id) = 0 then null
            else time_seconds
                / sum(time_seconds) over (partition by activity_id)
        end as pct_in_zone
    from buckets
)

select
    activity_id,
    zone_id,
    zone_name,
    zone_min_watts,
    zone_max_watts,
    time_seconds,
    time_minutes,
    pct_in_zone
from final
