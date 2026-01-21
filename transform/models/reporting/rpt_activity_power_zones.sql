{{
    config(
        materialized='table'
    )
}}

with activity_zones as (
    select * from {{ ref('fct_activity_zones') }}
    where zone_type = 'power'
),

power_zones as (
    select
        activity_id,
        zone_index as zone_id,
        zone_name,
        zone_seconds as seconds_in_zone,
        min as zone_min_watts,
        max as zone_max_watts,
        is_sensor_based,
        has_custom_zone_set
    from activity_zones
),

/* Calculate percentage of total time in each zone per activity */
zone_totals as (
    select
        activity_id,
        sum(seconds_in_zone) as total_zone_seconds
    from power_zones
    group by activity_id
),

power_zones_with_pct as (
    select
        pz.activity_id,
        pz.zone_id,
        pz.zone_name,
        pz.seconds_in_zone,
        pz.zone_min_watts,
        pz.zone_max_watts,
        case
            when zt.total_zone_seconds > 0
            then round(pz.seconds_in_zone * 100.0 / zt.total_zone_seconds, 1)
            else 0
        end as pct_in_zone,
        pz.is_sensor_based,
        pz.has_custom_zone_set
    from power_zones pz
    left join zone_totals zt on pz.activity_id = zt.activity_id
)

select * from power_zones_with_pct
order by activity_id, zone_id
