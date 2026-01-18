with stream_points as (
    select *
    from {{ ref('int_activity_stream_points') }}
)

, pivoted as (
    select
        activity_id
        , stream_index
        , {{ dbt_utils.pivot(
            'stream_type'
            , dbt_utils.get_column_values(
                table=ref('int_activity_stream_points')
                , column='stream_type'
                , order_by='stream_type'
                , default=['altitude', 'distance', 'grade', 'heartrate', 'is_moving', 'latlng', 'time', 'velocity_smooth']
            )
            , agg='max'
            , then_value='stream_point'
            , else_value='null'
            , quote_identifiers=false
        ) }}

    from stream_points
    group by all
)

, casted as (
    select
        *
        /* Cast and add computed columns */
        , cast(is_moving as integer) as is_moving_int
        , cast(time as integer) as time_int
        , cast(altitude as double) as altitude_dbl
        , cast(distance as double) as distance_dbl
        , cast(grade as double) as grade_dbl
        , cast(velocity_smooth as double) as velocity_smooth_dbl
        /* Handle optional heartrate - may not exist in all datasets */
        , cast(null as integer) as heartrate_int

    from pivoted
)

, casted_clean as (
    select
        activity_id
        , stream_index
        , is_moving_int as is_moving
        , time_int as time
        , altitude_dbl as altitude
        , distance_dbl as distance
        , grade_dbl as grade
        , heartrate_int as heartrate
        , velocity_smooth_dbl as velocity_smooth
        , latlng
    from casted
)

, deltas as (
    select
        {{ dbt_utils.generate_surrogate_key(['activity_id', 'stream_index']) }} as activity_data_point_id
        , activity_id
        , stream_index
        , is_moving
        , time
        , altitude
        , distance
        , grade
        , heartrate
        , velocity_smooth
        , latlng
        , distance - lag(distance) over (partition by activity_id order by stream_index) as distance_delta
        , time - lag(time) over (partition by activity_id order by stream_index) as time_delta

    from casted_clean
)

, final as (
    select
        activity_data_point_id
        , activity_id
        , stream_index
        , is_moving::boolean as is_moving
        , time
        , altitude
        -- , cadence -- Column not present in stream data
        , cast(null as double) as cadence
        , distance
        , grade
        , heartrate
        -- , power -- Column not present in stream data
        , cast(null as double) as power
        , case
            when time = 0 and distance is not null then 0
            else distance_delta / time_delta
        end as velocity
        , velocity_smooth
        , distance_delta
        , time_delta
        , cast(json_extract(latlng, '$[0]') as double) as latitude
        , cast(json_extract(latlng, '$[1]') as double) as longitude

    from deltas
)
select *
from final