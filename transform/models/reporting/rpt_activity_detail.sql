{{
    config(
        materialized='table'
    )
}}

with activities as (
    select * from {{ ref('fct_activities') }}
),

activity_detail as (
    select
        activity_id,
        activity_name,
        activity_type,
        sport_type,
        workout_type,
        started_at,
        started_at_local,
        timezone,

        /* Duration metrics */
        elapsed_seconds,
        moving_seconds,

        /* Distance and elevation */
        distance,
        distance_metric,
        elevation_gain,
        elevation_min,
        elevation_max,

        /* Speed metrics */
        speed_avg,
        speed_max,
        speed_avg_metric,
        speed_max_metric,

        /* Heart rate metrics */
        has_heartrate,
        hr_avg,
        hr_max,

        /* Power metrics */
        power_avg,
        kilojoules,
        calories_burned,
        is_device_watts,

        /* Strava engagement */
        kudos_count,
        comment_count,
        achievement_count,
        pr_count,
        suffer_score,

        /* Flags */
        is_commute,
        is_trainer,
        is_manual,
        is_private,

        /* Map data */
        map_id,
        map_summary_polyline,
        gear_id

    from activities
)

select * from activity_detail
