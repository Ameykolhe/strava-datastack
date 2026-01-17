with source as (
    select *
    from {{ source('strava', 'activities') }}
)

, renamed as (
    select
        id as activity_id
        , name as activity_name
        , start_date as started_at
        , start_date_local as started_at_local
        , achievement_count
        , pr_count
        , athlete__resource_state as athlete_resource_state
        , athlete_count
        -- , average_cadence as cadence_avg -- Column not present in source
        /* Heart rate - variable availability */
        , {{ safe_column('average_heartrate', 'double', table_ref=source('strava', 'activities')) }} as hr_avg
        , {{ safe_column('max_heartrate', 'double', table_ref=source('strava', 'activities')) }} as hr_max
        /* Convert m/s to mph */
        , average_speed * (1/1609.344) * 3600 as speed_avg
        , max_speed * (1/1609.344) * 3600 as speed_max
        /* Convert m/s to kph */
        , average_speed * (1/1000) * 3600 as speed_avg_metric
        , max_speed * (1/1000) * 3600 as speed_max_metric
        , average_speed as speed_avg_raw
        , max_speed as speed_max_raw
        /* Power - variable availability */
        , {{ safe_column('average_watts', 'double', table_ref=source('strava', 'activities')) }} as power_avg
        -- , weighted_average_watts as power_weighted_avg -- Column not present in source
        -- , max_watts as power_max -- Column not present in source
        /* Conver C to F */
        -- , average_temp * (9/5) + 32 as temperature_avg -- Column not present in source
        -- , average_temp as temperature_avg_metric -- Column not present in source
        , comment_count
        /* Convert m to mi */
        , distance * (1/1609.344) as distance
        /* Convert m to km */
        , distance * (1/1000) as distance_metric
        , distance as distance_raw
        , elapsed_time as elapsed_seconds
        , moving_time as moving_seconds
        /* Convert m to ft */
        , elev_low * 3.280839895 as elevation_min
        , elev_high * 3.280839895 as elevation_max
        /* Convert m to ft */
        , total_elevation_gain * 3.280839895 as elevation_gain
        , total_elevation_gain as elevation_gain_metric
        , elev_low as elevation_min_metric
        , elev_high as elevation_max_metric
        /* Kilojoules - variable availability */
        , {{ safe_column('kilojoules', 'double', table_ref=source('strava', 'activities')) }} as kilojoules
        /* Convert kJ to kcal */
        , {{ safe_column('kilojoules', 'double', table_ref=source('strava', 'activities')) }} * (1/4.184) as calories_burned
        , kudos_count
        -- , location_city -- Column not present in source
        -- , location_country -- Column not present in source
        -- , location_state -- Column not present in source
        , map__resource_state as map_resource_state
        , map__summary_polyline as map_summary_polyline
        , photo_count as photo_count_at_upload
        , total_photo_count as photo_count
        , resource_state
        , type as activity_type
        , sport_type
        , suffer_score
        , timezone
        , utc_offset as utc_offset_seconds
        , upload_id_str
        , visibility
        -- , weighted_average_watts -- Column not present in source
        /* Workout type - variable availability */
        , case
            when {{ safe_column('workout_type', 'bigint', table_ref=source('strava', 'activities')) }} in (1, 11) then 'Race'
            when {{ safe_column('workout_type', 'bigint', table_ref=source('strava', 'activities')) }} = 2 then 'Long Run'
            when {{ safe_column('workout_type', 'bigint', table_ref=source('strava', 'activities')) }} in (3, 12) then 'Workout'
            when {{ safe_column('workout_type', 'bigint', table_ref=source('strava', 'activities')) }} in (0, 10) or {{ safe_column('workout_type', 'bigint', table_ref=source('strava', 'activities')) }} is null then 'None'
            else 'Unknown'
        end as workout_type
        , {{ safe_column('workout_type', 'bigint', table_ref=source('strava', 'activities')) }} as workout_type_raw

        , commute as is_commute
        , {{ safe_column('device_watts', 'boolean', 'false', table_ref=source('strava', 'activities')) }} as is_device_watts
        , flagged as is_flagged
        , from_accepted_tag as is_friends_activity
        , has_heartrate as has_heartrate
        , display_hide_heartrate_option as has_display_hide_heartrate_option
        , heartrate_opt_out as has_heartrate_hidden
        , has_kudoed
        , manual as is_manual
        , private as is_private
        , trainer as is_trainer

        , athlete__id as athlete_id
        , external_id
        , gear_id
        , map__id as map_id
        , upload_id

        , _dlt_id
        , _dlt_load_id

    from source
)

select *
from renamed