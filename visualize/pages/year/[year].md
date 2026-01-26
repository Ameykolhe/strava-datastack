---
title: Year in Sports
sidebar_link: false
---

<script>
  import { goto } from '$app/navigation';

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
  $: year_sport_summary_display = q_year__sport_summary?.map((row) => ({
    ...row,
    distance_display: distanceUnit === 'km' ? row.total_distance_km : row.total_distance_miles,
    sport_link: `/year/${params.year}/${row.sport_slug}`
  })) ?? [];
  $: year_sport_summary_pie = year_sport_summary_display?.map((row) => ({
    name: row.sport_type,
    value: row.activity_count,
    sport_slug: row.sport_slug
  })) ?? [];
  $: year_sport_time_pie = year_sport_summary_display?.map((row) => ({
    name: row.sport_type,
    value: row.total_moving_time_hours,
    sport_slug: row.sport_slug
  })) ?? [];

  $: currentYear = Number(params.year);
  $: currentKpi = q_year__kpis?.find((row) => row.activity_year === currentYear) ?? null;
  $: prevKpi = q_year__kpis?.find((row) => row.activity_year === currentYear - 1) ?? null;
  $: yearKpisWithComparisons = currentKpi ? {
    ...currentKpi,
    distance_change: pctChange(currentKpi?.[distanceTotalField], prevKpi?.[distanceTotalField]),
    time_change: pctChange(currentKpi?.total_moving_time_hours, prevKpi?.total_moving_time_hours),
    elevation_change: pctChange(currentKpi?.total_elevation_gain_feet, prevKpi?.total_elevation_gain_feet),
    count_change: pctChange(currentKpi?.activity_count, prevKpi?.activity_count)
  } : null;

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

  const handleSportPieClick = (event) => {
    const payload = event?.detail ?? event;
    const slug = payload?.data?.sport_slug;
    if (slug && isBrowser) goto(`/year/${params.year}/${slug}`);
  };

  $: currentMonth = q_year__monthly?.[q_year__monthly.length - 1]?.month_label;
  $: if (!selectedMonth && currentMonth) selectedMonth = currentMonth;
  $: selectedRow = q_year__monthly?.find((d) => d.month_label === selectedMonth) ??
    (q_year__monthly?.length ? q_year__monthly[q_year__monthly.length - 1] : null);
  $: selectedIndex = q_year__monthly?.findIndex((d) => d.month_label === selectedRow?.month_label) ?? -1;
  $: prevRow = selectedIndex > 0 ? q_year__monthly[selectedIndex - 1] : null;

  $: selectedWithComparisons = selectedRow ? {
    ...selectedRow,
    month_start: toDate(selectedRow?.month_start),
    distance_change: pctChange(selectedRow?.[distanceMonthlyField], prevRow?.[distanceMonthlyField]),
    time_change: pctChange(selectedRow?.total_moving_time_hours, prevRow?.total_moving_time_hours),
    elevation_change: pctChange(selectedRow?.total_elevation_gain_feet, prevRow?.total_elevation_gain_feet),
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

```sql q_year__kpis
select
    activity_year,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    longest_distance_miles,
    hardest_elevation_gain_feet,
    avg_speed_mph
from strava.src_strava__kpis_year
where activity_year in (${params.year}, ${params.year} - 1)
```

```sql q_year__streaks
select
    activity_year,
    current_streak,
    longest_streak,
    active_days_year
from strava.src_strava__streaks_year
where activity_year = ${params.year}
```

```sql q_year__monthly
select
    month_start,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet
from strava.src_strava__kpis_year_month
where activity_year = ${params.year}
order by month_start
```

```sql q_year__sport_summary
select
    sport_type,
    sport_slug,
    activity_count,
    total_moving_time_hours,
    total_distance_km,
    total_distance_miles
from strava.src_strava__kpis_sport_type_year
where activity_year = ${params.year}
  and activity_count > 0
order by activity_count desc
```

```sql q_year__calendar
select
    activity_date,
    activity_count
from strava.src_strava__activity_daily_trends
where activity_year = ${params.year}
order by activity_date
```

```sql q_year__routes
select
    activity_year,
    polylines_json
from strava.src_strava__year_routes
where activity_year = ${params.year}
```

# {params.year}

## Overview

<BigValue
    data={[yearKpisWithComparisons]}
    value=activity_count
    comparison=count_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Total Activities"
    fmt="#,#0"
/>

<BigValue
    data={[yearKpisWithComparisons]}
    value={distanceTotalField}
    comparison=distance_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title={distanceTotalTitle}
    fmt="#,#0.0"
/>

<BigValue
    data={[yearKpisWithComparisons]}
    value=total_moving_time_hours
    comparison=time_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Total Time (hrs)"
    fmt="#,#0"
/>

<BigValue
    data={[yearKpisWithComparisons]}
    value=total_elevation_gain_feet
    comparison=elevation_change
    comparisonFmt=pct1
    comparisonTitle="YoY"
    title="Elevation Gain (ft)"
    fmt="#,#0"
/>

## Streaks

<BigValue
    data={q_year__streaks}
    value=active_days_year
    title="Active Days (year)"
    fmt="#,#0"
/>

<BigValue
    data={q_year__streaks}
    value=longest_streak
    title="Longest Streak (days)"
    fmt="#,#0"
/>

## Activity Calendar

<CalendarHeatmap
data={q_year__calendar}
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
  <BigValue data={[selectedWithComparisons]} value={distanceMonthlyField} comparison=distance_change comparisonFmt=pct1 comparisonTitle="MoM" title={distanceMonthlyTitle} fmt="#,#0.0"/>
  <BigValue data={[selectedWithComparisons]} value=total_moving_time_hours comparison=time_change comparisonFmt=pct1 comparisonTitle="MoM" title="Time (hrs)" fmt="#,#0.0"/>
  <BigValue data={[selectedWithComparisons]} value=total_elevation_gain_feet comparison=elevation_change comparisonFmt=pct1 comparisonTitle="MoM" title="Elevation (ft)" fmt="#,#0"/>
  <BigValue data={[selectedWithComparisons]} value=activity_count comparison=count_change comparisonFmt=pct1 comparisonTitle="MoM" title="Activity Count" fmt="#,#0"/>
</div>
{/if}

{#if q_year__monthly && q_year__monthly.length >= 2}
<ECharts
    on:click={handleMonthlyEvent}
    on:mouseover={handleMonthlyEvent}
    data={q_year__monthly}
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
            source: q_year__monthly
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
                startValue: q_year__monthly.length > 12 ? q_year__monthly[q_year__monthly.length - 12]?.month_label : q_year__monthly[0]?.month_label,
                endValue: q_year__monthly[q_year__monthly.length - 1]?.month_label
            }
        ],
        series: [
            {
                name: distanceSeriesName,
                type: 'line',
                yAxisIndex: 0,
                smooth: true,
                showSymbol: false,
                triggerLineEvent: true,
                cursor: 'pointer',
                encode: { x: 'month_label', y: distanceSeriesField }
            },
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
            {
                name: 'Elevation (ft)',
                type: 'line',
                yAxisIndex: 0,
                smooth: true,
                showSymbol: false,
                triggerLineEvent: true,
                cursor: 'pointer',
                encode: { x: 'month_label', y: 'total_elevation_gain_feet' }
            },
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

## By Sport Type

{#if year_sport_summary_pie.length > 0 || year_sport_time_pie.length > 0}
<div class="sport-summary-charts">
  {#if year_sport_summary_pie.length > 0}
  <ECharts
      on:click={handleSportPieClick}
      data={year_sport_summary_pie}
      config={{
          backgroundColor: 'transparent',
          tooltip: { trigger: 'item' },
          legend: { show: false },
          title: {
              text: 'Activities',
              left: '35%',
              top: '50%',
              textAlign: 'center',
              textVerticalAlign: 'middle'
          },
          series: [
              {
                  name: 'Activities',
                  type: 'pie',
                  radius: ['30%', '70%'],
                  center: ['35%', '50%'],
                  avoidLabelOverlap: false,
                  itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 1 },
                  label: { show: false },
                  labelLine: { show: false },
                  data: year_sport_summary_pie
              }
          ]
      }}
  />
  {/if}

  {#if year_sport_time_pie.length > 0}
  <ECharts
      on:click={handleSportPieClick}
      data={year_sport_time_pie}
      config={{
          backgroundColor: 'transparent',
          tooltip: { trigger: 'item' },
          legend: {
              top: 'middle',
              right: 0,
              orient: 'vertical'
          },
          title: {
              text: 'Time (hrs)',
              left: '35%',
              top: '50%',
              textAlign: 'center',
              textVerticalAlign: 'middle'
          },
          series: [
              {
                  name: 'Time (hrs)',
                  type: 'pie',
                  radius: ['30%', '70%'],
                  center: ['35%', '50%'],
                  avoidLabelOverlap: false,
                  itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 1 },
                  label: { show: false },
                  labelLine: { show: false },
                  data: year_sport_time_pie
              }
          ]
      }}
  />
  {/if}
</div>
{/if}

## Activity Heatmap

{#if q_year__routes.length > 0 && q_year__routes[0].polylines_json}

<ActivityHeatmap
    polylines={q_year__routes[0].polylines_json}
height={500}
/>

{:else}

No routes available to display for this year.

{/if}

<style>
  .sport-summary-charts {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
  }

  @media (max-width: 900px) {
    .sport-summary-charts {
      grid-template-columns: 1fr;
    }
  }
</style>
