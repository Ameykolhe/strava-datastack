---
title: Year in Sport
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

  $: distanceSupported = q_year_sport__kpis?.length > 0 && q_year_sport__kpis[0].total_distance_km > 0;
  $: elevationSupported = q_year_sport__kpis?.length > 0 && q_year_sport__kpis[0].total_elevation_gain_feet > 0;
  $: currentYear = Number(params.year);
  $: currentKpi = q_year_sport__kpis?.find((row) => row.activity_year === currentYear) ?? null;
  $: prevKpi = q_year_sport__kpis?.find((row) => row.activity_year === currentYear - 1) ?? null;
  $: sportKpisWithComparisons = currentKpi ? {
    ...currentKpi,
    distance_change: distanceSupported ? pctChange(currentKpi?.[distanceTotalField], prevKpi?.[distanceTotalField]) : null,
    time_change: pctChange(currentKpi?.total_moving_time_hours, prevKpi?.total_moving_time_hours),
    elevation_change: elevationSupported ? pctChange(currentKpi?.total_elevation_gain_feet, prevKpi?.total_elevation_gain_feet) : null,
    count_change: pctChange(currentKpi?.activity_count, prevKpi?.activity_count),
    speed_change: pctChange(currentKpi?.avg_speed_kmh, prevKpi?.avg_speed_kmh),
    pace_change: pctChange(currentKpi?.avg_pace_min_per_km, prevKpi?.avg_pace_min_per_km),
    hr_change: pctChange(currentKpi?.avg_heartrate_bpm, prevKpi?.avg_heartrate_bpm)
  } : null;
  $: hasPace = q_year_sport__activities?.length > 0 && q_year_sport__activities[0].pace_min_per_km != null;
  $: hasHeartRate = q_year_sport__activities?.length > 0 && q_year_sport__activities[0].average_heartrate_bpm != null;
  $: hasWatts = q_year_sport__activities?.length > 0 && q_year_sport__activities[0].average_watts != null;
  $: hasSpeed = q_year_sport__activities?.length > 0 && q_year_sport__activities[0].average_speed_kph != null;
  $: activities_display = q_year_sport__activities?.map((row) => ({
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

  $: currentMonth = q_year_sport__kpis_year_month?.[q_year_sport__kpis_year_month.length - 1]?.month_label;
  $: if (!selectedMonth && currentMonth) selectedMonth = currentMonth;
  $: selectedRow = q_year_sport__kpis_year_month?.find((d) => d.month_label === selectedMonth) ??
    (q_year_sport__kpis_year_month?.length ? q_year_sport__kpis_year_month[q_year_sport__kpis_year_month.length - 1] : null);
  $: selectedIndex = q_year_sport__kpis_year_month?.findIndex((d) => d.month_label === selectedRow?.month_label) ?? -1;
  $: prevRow = selectedIndex > 0 ? q_year_sport__kpis_year_month[selectedIndex - 1] : null;

  $: selectedWithComparisons = selectedRow ? {
    ...selectedRow,
    month_start: toDate(selectedRow?.month_start),
    distance_change: distanceSupported ? pctChange(selectedRow?.[distanceMonthlyField], prevRow?.[distanceMonthlyField]) : null,
    time_change: pctChange(selectedRow?.total_moving_time_hours, prevRow?.total_moving_time_hours),
    elevation_change: elevationSupported ? pctChange(selectedRow?.total_elevation_gain_feet, prevRow?.total_elevation_gain_feet) : null,
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
  $: selectedMonthTitleText = selectedMonthTitle ? `${selectedMonthTitle}` : '';
</script>

```sql q_year_sport__kpis
select
    sport_type,
    sport_slug,
    activity_year,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_kmh,
    avg_heartrate_bpm,
    avg_pace_min_per_km
from strava.src_strava__kpis_sport_type_year
where activity_year in (${params.year}, ${params.year} - 1)
  and sport_slug = '${params.sport}'
```

```sql q_year_sport__streaks
select
    sport_type,
    sport_slug,
    activity_year,
    current_streak,
    longest_streak,
    active_days_year
from strava.src_strava__streaks_sport_type_year
where activity_year = ${params.year}
  and sport_slug = '${params.sport}'
```

```sql q_year_sport__kpis_year_month
select
    month_start,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_heartrate_bpm
from strava.src_strava__kpis_sport_type_year_month
where activity_year = ${params.year}
  and sport_slug = '${params.sport}'
order by month_start
```

```sql q_year_sport__calendar
select
    activity_date,
    activity_count
from strava.src_strava__activity_daily_trends_sport_type
where activity_year = ${params.year}
  and sport_slug = '${params.sport}'
order by activity_date
```

```sql q_year_sport__activities
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
from strava.src_strava__activity_list
where activity_year = ${params.year}
  and sport_slug = '${params.sport}'
order by started_at desc
```

# {params.year} {q_year_sport__kpis[0]?.sport_type}

## Overview

<BigValue
    data={[sportKpisWithComparisons]}
    value=activity_count
    comparison=count_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Total Activities"
    fmt="#,#0"
/>

<BigValue
    data={[sportKpisWithComparisons]}
    value=total_moving_time_hours
    comparison=time_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Total Time (hrs)"
    fmt="#,#0.0"
/>

{#if distanceSupported}
<BigValue
    data={[sportKpisWithComparisons]}
    value={distanceTotalField}
    comparison=distance_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title={distanceTotalTitle}
    fmt="#,#0.0"
/>
{/if}

{#if elevationSupported}
<BigValue
    data={[sportKpisWithComparisons]}
    value=total_elevation_gain_feet
    comparison=elevation_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Elevation Gain (ft)"
    fmt="#,#0"
/>
{/if}

{#if q_year_sport__kpis.length > 0 && q_year_sport__kpis[0].avg_speed_kmh != null}
<BigValue
    data={[sportKpisWithComparisons]}
    value=avg_speed_kmh
    comparison=speed_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Avg Speed (km/h)"
    fmt="#,#0.0"
/>
{/if}

{#if q_year_sport__kpis.length > 0 && q_year_sport__kpis[0].avg_pace_min_per_km != null}
<BigValue
    data={[sportKpisWithComparisons]}
    value=avg_pace_min_per_km
    comparison=pace_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Avg Pace (min/km)"
    fmt="#,#0.00"
/>
{/if}

{#if q_year_sport__kpis.length > 0 && q_year_sport__kpis[0].avg_heartrate_bpm != null}
<BigValue
    data={[sportKpisWithComparisons]}
    value=avg_heartrate_bpm
    comparison=hr_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Avg HR (bpm)"
    fmt="#,#0"
/>
{/if}

## Streaks

<BigValue
    data={q_year_sport__streaks}
    value=active_days_year
    title="Active Days (year)"
    fmt="#,#0"
/>

<BigValue
    data={q_year_sport__streaks}
    value=longest_streak
    title="Longest Streak (days)"
    fmt="#,#0"
/>

## Activity Calendar

<CalendarHeatmap
data={q_year_sport__calendar}
date=activity_date
value=activity_count
min=0
max=5
legend=false
/>

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
  <BigValue data={[selectedWithComparisons]} value=total_elevation_gain_feet comparison=elevation_change comparisonFmt=pct1 comparisonTitle="MoM" title="Elevation (ft)" fmt="#,#0"/>
  {/if}
  <BigValue data={[selectedWithComparisons]} value=activity_count comparison=count_change comparisonFmt=pct1 comparisonTitle="MoM" title="Activity Count" fmt="#,#0"/>
</div>
{/if}

{#if q_year_sport__kpis_year_month && q_year_sport__kpis_year_month.length >= 2}
<ECharts
    on:click={handleMonthlyEvent}
    on:mouseover={handleMonthlyEvent}
    data={q_year_sport__kpis_year_month}
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
            source: q_year_sport__kpis_year_month
        },
        dataZoom: [
            {
                type: 'inside',
                xAxisIndex: 0,
                zoomLock: true,
                zoomOnMouseWheel: false,
                zoomOnMouseMove: false,
                moveOnMouseWheel: true,
                moveOnMouseMove: true,
                startValue: q_year_sport__kpis_year_month.length > 12 ? q_year_sport__kpis_year_month[q_year_sport__kpis_year_month.length - 12]?.month_label : q_year_sport__kpis_year_month[0]?.month_label,
                endValue: q_year_sport__kpis_year_month[q_year_sport__kpis_year_month.length - 1]?.month_label
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
                encode: { x: 'month_label', y: 'total_elevation_gain_feet' }
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
{/if}

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
