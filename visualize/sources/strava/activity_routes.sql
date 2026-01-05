-- Detailed route coordinates for Run, Walk, and Hike activities
WITH activities AS (
    SELECT
        id as activity_id,
        name as activity_name,
        sport_type,
        start_date_local,
        distance * (1/1000) as distance_km,
        moving_time / 60.0 as moving_time_minutes
    FROM strava_raw.activities
    WHERE sport_type IN ('Run', 'Walk', 'Hike')
)

, latlng_streams AS (
    SELECT
        _activities_id as activity_id,
        data as latlng_json,
        original_size as num_points
    FROM strava_raw.activity_streams
    WHERE type = 'latlng'
)

-- Parse JSON to array of double arrays and unnest
, parsed_coords AS (
    SELECT
        activity_id,
        num_points,
        unnest(latlng_json::JSON::DOUBLE[][]) as coord_pair,
        generate_subscripts(latlng_json::JSON::DOUBLE[][], 1) as point_index
    FROM latlng_streams
)

, extracted_lat_lng AS (
    SELECT
        activity_id,
        point_index,
        coord_pair[1] as latitude,
        coord_pair[2] as longitude,
        num_points
    FROM parsed_coords
)

SELECT
    a.activity_id,
    a.activity_name,
    a.sport_type,
    a.start_date_local as start_date,
    a.distance_km,
    a.moving_time_minutes,
    c.point_index,
    c.latitude,
    c.longitude,
    c.num_points as total_points
FROM activities a
INNER JOIN extracted_lat_lng c ON a.activity_id = c.activity_id
ORDER BY a.start_date_local DESC, c.point_index