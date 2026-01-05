-- Activities with map data for Run, Walk, and Hike
WITH activities_with_coords AS (
    SELECT
        a.id as activity_id,
        a.name as activity_name,
        a.sport_type,
        a.start_date_local as start_date,
        a.distance * (1/1000) as distance_km,
        a.moving_time / 60.0 as moving_time_minutes,
        a.total_elevation_gain * 3.280839895 as elevation_gain_ft,
        a.map__summary_polyline as polyline,
        start_lat.value as start_lat,
        start_lng.value as start_lng,
        end_lat.value as end_lat,
        end_lng.value as end_lng
    FROM strava_raw.activities a
    LEFT JOIN strava_raw.activities__start_latlng start_lat
        ON a._dlt_id = start_lat._dlt_parent_id
        AND start_lat._dlt_list_idx = 0
    LEFT JOIN strava_raw.activities__start_latlng start_lng
        ON a._dlt_id = start_lng._dlt_parent_id
        AND start_lng._dlt_list_idx = 1
    LEFT JOIN strava_raw.activities__end_latlng end_lat
        ON a._dlt_id = end_lat._dlt_parent_id
        AND end_lat._dlt_list_idx = 0
    LEFT JOIN strava_raw.activities__end_latlng end_lng
        ON a._dlt_id = end_lng._dlt_parent_id
        AND end_lng._dlt_list_idx = 1
    WHERE a.sport_type IN ('Run', 'Walk', 'Hike')
        AND a.map__summary_polyline IS NOT NULL
)
SELECT
    *,
    -- Create a title for the popup
    activity_name || ' (' || sport_type || ')' as title,
    -- Create description with stats
    ROUND(distance_km, 2) || ' km • ' ||
    ROUND(moving_time_minutes, 0) || ' min • ' ||
    ROUND(elevation_gain_ft, 0) || ' ft gain' as description
FROM activities_with_coords
ORDER BY start_date DESC