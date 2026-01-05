---
title: Activity Details
---

# Activity Explorer

## Filter Activities

```sql sport_types
select distinct sport_type
from strava.activities_overview
order by sport_type
```

<Dropdown data={sport_types} name=sport value=sport_type>
    <DropdownOption value="%" valueLabel="All Sports"/>
</Dropdown>

```sql activities
select *
from strava.activities_overview
where sport_type like '${inputs.sport.value}'
order by start_date_local desc
```

## Activity Metrics

<Grid cols=3>
    <BigValue
        data={activities}
        value=distance_km
        agg=sum
        fmt='#,##0.0'
        title="Total Distance (km)"
    />
    <BigValue
        data={activities}
        value=moving_time_minutes
        agg=sum
        fmt='#,##0.0'
        title="Total Moving Time (min)"
    />
    <BigValue
        data={activities}
        value=elevation_gain_meters
        agg=sum
        fmt='#,##0'
        title="Total Elevation Gain (m)"
    />
</Grid>

## Distance Over Time

<LineChart
    data={activities}
    title="Distance per Activity"
    x=start_date_local
    y=distance_km
/>

## Speed Distribution

<Histogram
    data={activities}
    x=avg_speed_kmh
    title="Average Speed Distribution (km/h)"
/>

## Heart Rate Analysis

<LineChart
    data={activities}
    title="Average Heart Rate Over Time"
    x=start_date_local
    y=average_heartrate
/>

## All Activities

<DataTable data={activities} search=true rows=20>
    <Column id=name/>
    <Column id=sport_type/>
    <Column id=start_date_local fmt='yyyy-MM-dd HH:mm'/>
    <Column id=distance_km fmt='#,##0.00'/>
    <Column id=moving_time_minutes fmt='#,##0.0'/>
    <Column id=elevation_gain_meters fmt='#,##0'/>
    <Column id=avg_speed_kmh fmt='#,##0.0'/>
    <Column id=max_speed_kmh fmt='#,##0.0'/>
    <Column id=average_heartrate fmt='#,##0'/>
    <Column id=max_heartrate fmt='#,##0'/>
    <Column id=average_watts fmt='#,##0'/>
    <Column id=kilojoules fmt='#,##0'/>
    <Column id=kudos_count/>
</DataTable>