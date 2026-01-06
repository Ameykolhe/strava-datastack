{{
    config(
        materialized='incremental'
        , unique_key='activity_stream_id'
        , on_schema_change='sync_all_columns'
    )
}}

with activity_streams as (
    select *
    from {{ ref('int_activity_streams') }}
    
    {% if is_incremental() %}

    where inserted_at > (select max(inserted_at) from {{ this }} )

    {% endif %}
)

, flattened as (
    select
        activity_stream_id
        , activity_id
        , stream_type
        , case
            when stream_type = 'latlng' then cast(unnest(latlng_list) as varchar)
            else cast(unnest(stream_list) as varchar)
        end as stream_point
        , case
            when stream_type = 'latlng' then generate_subscripts(latlng_list, 1)
            else generate_subscripts(stream_list, 1)
        end as stream_index
        , inserted_at

    from activity_streams
)

, final as (
    select
        {{ dbt_utils.generate_surrogate_key(['activity_stream_id', 'stream_index']) }} as activity_stream_point_id
        , *
    
    from flattened
)

select *
from final