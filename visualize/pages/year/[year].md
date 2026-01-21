---
title: Year in Sports
---

```sql year_kpis
select * from strava.year_kpis
where year = ${params.year}
```

```sql year_monthly
select * from strava.year_monthly
where year = ${params.year}
order by month
```

```sql distinct_years
select * from strava.distinct_years
order by activity_year desc
```

```sql year_activities
select * from strava.activity_list
where year(started_at_local) = ${params.year}
order by started_at desc
```

# {params.year} Review

<BigValue
    data={year_kpis}
    value=activity_count
    title="Activities"
/>

<BigValue
    data={year_kpis}
    value=total_distance
    title="Distance (mi)"
    fmt='#,##0.0'
/>

<BigValue
    data={year_kpis}
    value=total_moving_time
    title="Time (hrs)"
    fmt='#,##0'
/>

<BigValue
    data={year_kpis}
    value=total_elevation_gain
    title="Elevation (ft)"
    fmt='#,##0'
/>

<BigValue
    data={year_kpis}
    value=longest_distance
    title="Longest (mi)"
    fmt='#,##0.1'
/>

<BigValue
    data={year_kpis}
    value=hardest_elevation_gain
    title="Most Elev (ft)"
    fmt='#,##0'
/>

## Monthly Trends

<BarChart
    data={year_monthly}
    x=month
    y=activity_count
    title="Activities by Month"
    yAxisTitle="Activities"
/>

<LineChart
    data={year_monthly}
    x=month
    y=total_distance
    title="Distance by Month"
    yAxisTitle="Distance (mi)"
/>

<BarChart
    data={year_monthly}
    x=month
    y=total_elevation_gain
    title="Elevation by Month"
    yAxisTitle="Elevation (ft)"
/>

## Activities in {params.year}

<DataTable
    data={year_activities}
    search=true
    rows=20
    link=activity_link
>
    <Column id=activity_name title="Activity"/>
    <Column id=sport_type title="Sport"/>
    <Column id=started_at_local title="Date" fmt="mmm d, yyyy"/>
    <Column id=distance title="Distance (mi)" fmt="#,##0.1"/>
    <Column id=moving_seconds title="Time"/>
    <Column id=elevation_gain title="Elev (ft)" fmt="#,##0"/>
    </DataTable>

## Navigate

{#each distinct_years as y}

{#if y.activity_year != params.year}

[{y.activity_year}](/year/{y.activity_year})

{/if}

{/each}

[Back to Home](/)
