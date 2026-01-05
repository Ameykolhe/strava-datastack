---
title: Activity Map
---

<script>
    import RouteMap from '$lib/RouteMap.svelte';
</script>

# Activity Map Explorer

Visualize your runs, walks, and hikes on an interactive map with full route paths.

## Filter by Activity Type

```sql activity_types
SELECT DISTINCT sport_type
FROM strava.map_activities
ORDER BY sport_type
```

<Dropdown data={activity_types} name=selected_sport value=sport_type>
    <DropdownOption value="%" valueLabel="All Types"/>
</Dropdown>

```sql filtered_activities
SELECT *
FROM strava.map_activities
WHERE sport_type LIKE '${inputs.selected_sport.value}'
```

## Activity Summary

<Grid cols=3>
    <BigValue
        data={filtered_activities}
        value=activity_id
        agg=count
        title="Total Activities"
    />
    <BigValue
        data={filtered_activities}
        value=distance_km
        agg=sum
        fmt='#,##0.0'
        title="Total Distance (km)"
    />
    <BigValue
        data={filtered_activities}
        value=moving_time_minutes
        agg=sum
        fmt='#,##0'
        title="Total Time (min)"
    />
</Grid>

## Activity Start Locations

{#if filtered_activities.length > 0}

<PointMap
    data={filtered_activities}
    lat=start_lat
    long=start_lng
    name=activity_name
    pointName=title
    height=500
    tooltip={[
        {id: 'description', showColumnName: false, valueClass: 'text-sm'},
        {id: 'start_date', title: 'Date', fmt: 'yyyy-MM-dd'}
    ]}
/>

## Detailed Route Paths

Get the granular coordinates for each activity to visualize the complete route.

```sql route_coordinates
SELECT *
FROM strava.activity_routes
WHERE sport_type LIKE '${inputs.selected_sport.value}'
```

{#if route_coordinates.length > 0}

### Route Visualization

<Alert status=info>
Showing detailed coordinate data for your activities.
</Alert>

**Select an activity to view its route:**

```sql activity_list
SELECT DISTINCT
    activity_id,
    activity_name,
    sport_type,
    start_date,
    distance_km,
    moving_time_minutes,
    total_points
FROM strava.activity_routes
WHERE sport_type LIKE '${inputs.selected_sport.value}'
ORDER BY start_date DESC
```

<Dropdown data={activity_list} name=selected_activity value=activity_id label=activity_name>
    <DropdownOption value="0" valueLabel="Select an activity..."/>
</Dropdown>

{#if inputs.selected_activity.value != "0"}

```sql selected_route
SELECT *
FROM strava.activity_routes
WHERE activity_id = ${inputs.selected_activity.value}
ORDER BY point_index
```

<RouteMap
    data={selected_route}
    height={600}
    title="Route Path: {selected_route[0].activity_name}"
/>

### Route Details

<Grid cols=2>
    <BigValue
        data={selected_route}
        value=total_points
        agg=max
        fmt='#,##0'
        title="Total Points"
    />
    <BigValue
        data={selected_route}
        value=distance_km
        agg=max
        fmt='#,##0.00'
        title="Distance (km)"
    />
</Grid>

### Alternative: Polyline Route

For a connected line visualization, you can use the encoded polyline with external mapping tools:

```sql selected_polyline
SELECT DISTINCT
    activity_id,
    activity_name,
    polyline
FROM strava.map_activities
WHERE activity_id = ${inputs.selected_activity.value}
```

<Details title="View Encoded Polyline">

This polyline can be decoded and displayed on mapping platforms like Google Maps, Mapbox, or Leaflet:

<DataTable data={selected_polyline} rows=5>
    <Column id=activity_name title="Activity"/>
    <Column id=polyline title="Encoded Polyline"/>
</DataTable>

**Decoding Tools:**
- [Interactive Polyline Encoder/Decoder](https://developers.google.com/maps/documentation/utilities/polylineutility)
- [Polyline Decoder (mapbox)](https://github.com/mapbox/polyline)

</Details>

### Coordinate Data

<DataTable data={selected_route} search=true rows=10>
    <Column id=point_index title="Point #"/>
    <Column id=latitude fmt='#,##0.000000'/>
    <Column id=longitude fmt='#,##0.000000'/>
</DataTable>

{/if}

{:else}

<Alert status=warning>
No detailed route coordinate data available for the selected activities. Route coordinates require GPS stream data from Strava.
</Alert>

{/if}

## Activity List

<DataTable data={filtered_activities} search=true rows=10>
    <Column id=activity_name title="Activity"/>
    <Column id=sport_type title="Type"/>
    <Column id=start_date fmt='yyyy-MM-dd HH:mm' title="Date"/>
    <Column id=distance_km fmt='#,##0.00' title="Distance (km)"/>
    <Column id=moving_time_minutes fmt='#,##0.0' title="Duration (min)"/>
    <Column id=elevation_gain_ft fmt='#,##0' title="Elevation (ft)"/>
    <Column id=start_lat fmt='#,##0.0000' title="Start Lat"/>
    <Column id=start_lng fmt='#,##0.0000' title="Start Lng"/>
</DataTable>

{:else}

<Alert status=info>
No activities found for the selected filter. Try selecting a different activity type.
</Alert>

{/if}