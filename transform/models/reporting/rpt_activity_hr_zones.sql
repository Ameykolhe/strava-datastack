{{
    config(
        materialized='table'
    )
}}

with activity_zones as (
    select * from {{ ref('fct_activity_zones') }}
    where zone_type = 'heartrate'
),

hr_zones as (
    select
        activity_id,
        zone_index as zone_id,
        zone_name,
        zone_seconds as seconds_in_zone,
        min as zone_min_bpm,
        max as zone_max_bpm,
        is_sensor_based,
        has_custom_zone_set
    from activity_zones
),

/* Calculate percentage of total time in each zone per activity */
zone_totals as (
    select
        activity_id,
        sum(seconds_in_zone) as total_zone_seconds
    from hr_zones
    group by activity_id
),

hr_zones_with_pct as (
    select
        hz.activity_id,
        hz.zone_id,
        hz.zone_name,
        hz.seconds_in_zone,
        hz.zone_min_bpm,
        hz.zone_max_bpm,
        case
            when zt.total_zone_seconds > 0
            then round(hz.seconds_in_zone * 100.0 / zt.total_zone_seconds, 1)
            else 0
        end as pct_in_zone,
        hz.is_sensor_based,
        hz.has_custom_zone_set
    from hr_zones hz
    left join zone_totals zt on hz.activity_id = zt.activity_id
)

select * from hr_zones_with_pct
order by activity_id, zone_id
