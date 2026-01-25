---
title: Sport
sidebar_link: false
---

<script>
  let selectedMonth = null;
  let distanceUnit = 'km';
  const isBrowser = typeof window !== 'undefined';
  if (isBrowser) {
    const storedDistanceUnit = localStorage.getItem('distanceUnit');
    if (storedDistanceUnit) distanceUnit = storedDistanceUnit;
  }

  if (isBrowser) {
    window.addEventListener('distance-unit-change', (event) => {
      if (event?.detail?.unit) distanceUnit = event.detail.unit;
    });
  }

  $: distanceUnitLabel = distanceUnit === 'km' ? 'km' : 'mi';
  $: distanceTotalField = distanceUnit === 'km' ? 'total_distance_km' : 'total_distance_miles';
  $: distanceMonthlyField = distanceUnit === 'km' ? 'total_distance_km' : 'total_distance_miles';
  $: distanceSeriesField = distanceMonthlyField;
  $: distanceSeriesName = distanceUnit === 'km' ? 'Distance (km)' : 'Distance (mi)';
  $: distanceTotalTitle = distanceUnit === 'km' ? 'Total Distance (km)' : 'Total Distance (mi)';
  $: distanceMonthlyTitle = distanceUnit === 'km' ? 'Distance (km)' : 'Distance (mi)';

  $: sportTitle = sport_kpis?.[0]?.sport_type ?? params.sport;
  $: distanceSupported = sport_kpis?.length > 0 && sport_kpis[0].total_distance_km > 0;
  $: elevationSupported = sport_kpis?.length > 0 && sport_kpis[0].total_elevation_gain_feet > 0;
  $: hasPace = activities?.length > 0 && activities[0].pace_min_per_km != null;
  $: hasHeartRate = activities?.length > 0 && activities[0].average_heartrate_bpm != null;
  $: hasWatts = activities?.length > 0 && activities[0].average_watts != null;
  $: hasSpeed = activities?.length > 0 && activities[0].average_speed_kph != null;
  $: activities_display = activities?.map((row) => ({
    ...row,
    distance_display: distanceUnit === 'km' ? row.distance_km : row.distance_miles
  })) ?? [];

  const monthFromEvent = (event) => {
    if (!event) return null;
    const payload = event.detail ?? event;
    if (payload.axisValue) return payload.axisValue;
    if (payload.data && payload.data.month_label) return payload.data.month_label;
    if (payload.name && typeof payload.name === 'string') return payload.name;
    if (typeof payload.value === 'string') return payload.value;
    if (Array.isArray(payload.data) && payload.data.length) return payload.data[0];
    if (Array.isArray(payload.value) && payload.value.length) return payload.value[0];
    if (payload.value && payload.value.month_label) return payload.value.month_label;
    return null;
  };

  const handleMonthlyEvent = (event) => {
    const month = monthFromEvent(event);
    if (month) selectedMonth = month;
  };

  $: currentMonth = monthly_stats?.[monthly_stats.length - 1]?.month_label;
  $: if (!selectedMonth && currentMonth) selectedMonth = currentMonth;
  $: selectedRow = monthly_stats?.find((d) => d.month_label === selectedMonth) ??
    (monthly_stats?.length ? monthly_stats[monthly_stats.length - 1] : null);
  $: selectedIndex = monthly_stats?.findIndex((d) => d.month_label === selectedRow?.month_label) ?? -1;
  $: prevRow = selectedIndex > 0 ? monthly_stats[selectedIndex - 1] : null;

  $: selectedWithComparisons = selectedRow ? {
    ...selectedRow,
    month_start: toDate(selectedRow?.month_start),
    distance_change: distanceSupported ? pctChange(selectedRow?.[distanceMonthlyField], prevRow?.[distanceMonthlyField]) : null,
    time_change: pctChange(selectedRow?.total_moving_time_hours, prevRow?.total_moving_time_hours),
    elevation_change: elevationSupported ? pctChange(selectedRow?.total_elevation_feet, prevRow?.total_elevation_feet) : null,
    count_change: pctChange(selectedRow?.activity_count, prevRow?.activity_count)
  } : null;
  const toDate = (value) => (value ? new Date(value) : value);
  const formatMonthLabel = (value) => {
    if (!value) return '';
    const date = typeof value === 'string' ? new Date(value) : value;
    if (!date || Number.isNaN(date.getTime?.())) return '';
    return date.toLocaleString('en-US', { month: 'long', year: 'numeric' });
  };
  const pctChange = (current, prev) => {
    if (current == null || prev == null || prev == 0) return null;
    return (current - prev) / prev;
  };
  $: selectedMonthTitle = selectedRow ? formatMonthLabel(toDate(selectedRow.month_start)) : '';
  $: selectedMonthTitleText = selectedMonthTitle ? `- ${selectedMonthTitle}` : '';
</script>

```sql sport_kpis
select
    sport_type,
    sport_slug,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_kmh,
    avg_heartrate_bpm,
    avg_pace_min_per_km
from strava.sport_kpis
where sport_slug = '${params.sport}'
```

```sql monthly_stats
select
    cast(month_start as date) as month_start,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_feet,
    avg_heartrate_bpm
from strava.sport_trends_12mo
where lower(sport_type) = '${params.sport}'
order by month_start
```

```sql activities
select
    activity_id,
    activity_name,
    started_at,
    distance_km,
    distance_miles,
    moving_time_minutes,
    elevation_gain_feet,
    average_speed_kph,
    pace_min_per_km,
    average_heartrate_bpm,
    average_watts,
    activity_link
from strava.activity_list
where lower(sport_type) = '${params.sport}'
order by started_at desc
```

# {sportTitle}

## Overview

<BigValue
    data={sport_kpis}
    value=activity_count
    title="Total Activities"
    fmt="#,#0"
/>

<BigValue
    data={sport_kpis}
    value=total_moving_time_hours
    title="Total Time (hrs)"
    fmt="#,#0.0"
/>

{#if distanceSupported}
<BigValue
    data={sport_kpis}
    value={distanceTotalField}
    title={distanceTotalTitle}
    fmt="#,#0.0"
/>
{/if}

{#if elevationSupported}
<BigValue
    data={sport_kpis}
    value=total_elevation_gain_feet
    title="Elevation Gain (ft)"
    fmt="#,#0"
/>
{/if}

{#if sport_kpis.length > 0 && sport_kpis[0].avg_speed_kmh != null}
<BigValue
    data={sport_kpis}
    value=avg_speed_kmh
    title="Avg Speed (km/h)"
    fmt="#,#0.0"
/>
{/if}

{#if sport_kpis.length > 0 && sport_kpis[0].avg_pace_min_per_km != null}
<BigValue
    data={sport_kpis}
    value=avg_pace_min_per_km
    title="Avg Pace (min/km)"
    fmt="#,#0.00"
/>
{/if}

{#if sport_kpis.length > 0 && sport_kpis[0].avg_heartrate_bpm != null}
<BigValue
    data={sport_kpis}
    value=avg_heartrate_bpm
    title="Avg HR (bpm)"
    fmt="#,#0"
/>
{/if}

## Monthly Trends

{#if selectedMonthTitle}
### {selectedMonthTitle}
{/if}

{#if selectedWithComparisons}
<div class="monthly-kpis">
  {#if distanceSupported}
  <BigValue data={[selectedWithComparisons]} value={distanceMonthlyField} comparison=distance_change comparisonFmt=pct1 comparisonTitle="MoM" title={distanceMonthlyTitle} fmt="#,#0.0"/>
  {/if}
  <BigValue data={[selectedWithComparisons]} value=total_moving_time_hours comparison=time_change comparisonFmt=pct1 comparisonTitle="MoM" title="Time (hrs)" fmt="#,#0.0"/>
  {#if elevationSupported}
  <BigValue data={[selectedWithComparisons]} value=total_elevation_feet comparison=elevation_change comparisonFmt=pct1 comparisonTitle="MoM" title="Elevation (ft)" fmt="#,#0"/>
  {/if}
  <BigValue data={[selectedWithComparisons]} value=activity_count comparison=count_change comparisonFmt=pct1 comparisonTitle="MoM" title="Activity Count" fmt="#,#0"/>
</div>
{/if}

<ECharts
    on:click={handleMonthlyEvent}
    on:mouseover={handleMonthlyEvent}
    data={monthly_stats}
    showAllXAxisLabels
    config={{
        backgroundColor: 'transparent',
        legend: {
            top: 0,
            left: 0
        },
        grid: {
            left: '3%',
            right: '3%',
            top: 28,
            bottom: 70,
            containLabel: true
        },
        tooltip: {
            show: true,
            trigger: 'axis',
            triggerOn: 'mousemove|click',
            axisPointer: { type: 'line' }
        },
        xAxis: {
            type: 'category',
            triggerEvent: true,
            axisLine: { show: false },
            axisTick: { show: false },
            splitLine: { show: false },
            axisLabel: { rotate: 90, triggerEvent: true }
        },
        yAxis: [
            {
                type: 'value',
                axisLine: { show: false },
                axisTick: { show: false },
                splitLine: { show: false },
                axisLabel: { show: false }
            },
            {
                type: 'value',
                axisLine: { show: false },
                axisTick: { show: false },
                splitLine: { show: false },
                axisLabel: { show: false }
            }
        ],
        dataset: {
            source: monthly_stats
        },
        dataZoom: [
            {
                type: 'inside',
                xAxisIndex: 0,
                zoomLock: true,
                throttle: 30,
                zoomOnMouseWheel: false,
                zoomOnMouseMove: false,
                moveOnMouseWheel: true,
                moveOnMouseMove: false,
                preventDefaultMouseWheel: true,
                preventDefaultMouseMove: true,
                startValue: monthly_stats.length > 12 ? monthly_stats[monthly_stats.length - 12]?.month_label : monthly_stats[0]?.month_label,
                endValue: monthly_stats[monthly_stats.length - 1]?.month_label
            },
            {
                type: 'slider',
                xAxisIndex: 0,
                zoomLock: true,
                height: 50,
                bottom: 8,
                showDetail: false,
                startValue: monthly_stats.length > 12 ? monthly_stats[monthly_stats.length - 12]?.month_label : monthly_stats[0]?.month_label,
                endValue: monthly_stats[monthly_stats.length - 1]?.month_label
            }
        ],
        series: [
            ...(distanceSupported ? [{
                name: distanceSeriesName,
                type: 'line',
                yAxisIndex: 0,
                smooth: true,
                showSymbol: false,
                triggerLineEvent: true,
                cursor: 'pointer',
                encode: { x: 'month_label', y: distanceSeriesField }
            }] : []),
            {
                name: 'Time (hrs)',
                type: 'line',
                yAxisIndex: 1,
                smooth: true,
                showSymbol: false,
                triggerLineEvent: true,
                cursor: 'pointer',
                encode: { x: 'month_label', y: 'total_moving_time_hours' }
            },
            ...(elevationSupported ? [{
                name: 'Elevation (ft)',
                type: 'line',
                yAxisIndex: 0,
                smooth: true,
                showSymbol: false,
                triggerLineEvent: true,
                cursor: 'pointer',
                encode: { x: 'month_label', y: 'total_elevation_feet' }
            }] : []),
            {
                name: 'Activity Count',
                type: 'bar',
                yAxisIndex: 1,
                barMaxWidth: 16,
                itemStyle: { opacity: 0.5 },
                cursor: 'pointer',
                encode: { x: 'month_label', y: 'activity_count' }
            }
        ]
    }}
/>

## All Activities

<DataTable data={activities_display} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=activity_name title="Activity"/>
    {#if distanceSupported}
    <Column id=distance_display title={`Distance (${distanceUnitLabel})`}/>
    {/if}
    <Column id=moving_time_minutes title="Duration (min)"/>
    {#if elevationSupported}
    <Column id=elevation_gain_feet title="Elevation (ft)"/>
    {/if}
    {#if hasSpeed}
    <Column id=average_speed_kph title="Avg Speed (km/h)"/>
    {/if}
    {#if hasPace}
    <Column id=pace_min_per_km title="Pace (min/km)"/>
    {/if}
    {#if hasHeartRate}
    <Column id=average_heartrate_bpm title="Avg HR"/>
    {/if}
    {#if hasWatts}
    <Column id=average_watts title="Avg Watts"/>
    {/if}
</DataTable>

[Back to Activities](/activity)

<style>
  .monthly-kpis {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 12px;
    margin: 12px 0 16px;
  }
</style>
