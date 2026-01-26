---
title: Activities
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
  const setDistanceUnit = (unit) => {
    distanceUnit = unit;
    if (isBrowser) localStorage.setItem('distanceUnit', unit);
  };

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
  $: recent_activities_display = q_activity__recent_activities?.map((row) => ({
    ...row,
    distance_display: distanceUnit === 'km' ? row.distance_km : row.distance_miles
  })) ?? [];
  const indoorSports = new Set(['Badminton', 'Pickleball', 'Workout']);
  $: sport_summary_display = q_activity__sport_summary?.map((row) => ({
    ...row,
    distance_display: indoorSports.has(row.sport_type)
      ? null
      : (distanceUnit === 'km' ? row.total_distance_km : row.total_distance_miles),
    sport_link: `/activity/${row.sport_slug}`
  })) ?? [];
  $: sport_summary_pie = sport_summary_display?.map((row) => ({
    name: row.sport_type,
    value: row.activity_count,
    sport_slug: row.sport_slug
  })) ?? [];
  $: sport_time_pie = sport_summary_display?.map((row) => ({
    name: row.sport_type,
    value: row.total_moving_time_hours,
    sport_slug: row.sport_slug
  })) ?? [];

  const handleSportPieClick = (event) => {
    const payload = event?.detail ?? event;
    const slug = payload?.data?.sport_slug;
    if (slug && isBrowser) goto(`/activity/${slug}`);
  };

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

  $: currentMonth = q_activity__trends_monthly?.[q_activity__trends_monthly.length - 1]?.month_label;
  $: if (!selectedMonth && currentMonth) selectedMonth = currentMonth;
  $: selectedRow = q_activity__trends_monthly?.find((d) => d.month_label === selectedMonth) ??
    (q_activity__trends_monthly?.length ? q_activity__trends_monthly[q_activity__trends_monthly.length - 1] : null);
  $: selectedIndex = q_activity__trends_monthly?.findIndex((d) => d.month_label === selectedRow?.month_label) ?? -1;
  $: prevRow = selectedIndex > 0 ? q_activity__trends_monthly[selectedIndex - 1] : null;

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

```sql q_activity__kpis_alltime
select
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet,
    avg_speed_mph
from strava.src_strava__kpis_all
```

```sql q_activity__trends_monthly
select
    month_start,
    month_label,
    activity_count,
    total_distance_km,
    total_distance_miles,
    total_moving_time_hours,
    total_elevation_gain_feet
from strava.src_strava__kpis_year_month
order by month_start
```

```sql q_activity__streaks_alltime
select
    current_streak,
    longest_streak,
    active_days_last_30
from strava.src_strava__streaks_all
```

```sql q_activity__sport_summary
select
    sport_type,
    activity_count,
    total_moving_time_hours,
    total_distance_km,
    sport_slug
from strava.src_strava__kpis_sport_type
where activity_count > 0
order by activity_count desc
```

```sql q_activity__recent_activities
select
    activity_id,
    activity_name,
    sport_type,
    started_at,
    distance_km,
    distance_miles,
    moving_time_minutes,
    average_speed_mph,
    pace_min_per_km,
    activity_link
from strava.src_strava__activity_list
order by started_at desc
limit 20
```

## Overview

<BigValue
    data={q_activity__kpis_alltime}
    value=activity_count
    title="Total Activities"
    fmt="#,#0"
/>

<BigValue
    data={q_activity__kpis_alltime}
    value={distanceTotalField}
    title={distanceTotalTitle}
    fmt="#,#0.0"
/>

<BigValue
    data={q_activity__kpis_alltime}
    value=total_moving_time_hours
    title="Total Time (hrs)"
    fmt="#,#0"
/>

<BigValue
    data={q_activity__kpis_alltime}
    value=total_elevation_gain_feet
    title="Elevation Gain (ft)"
    fmt="#,#0"
/>

<BigValue
    data={q_activity__kpis_alltime}
    value=avg_speed_mph
    title="Avg Speed (mph)"
    fmt="#,#0.0"
/>

## Streaks

<BigValue
    data={q_activity__streaks_alltime}
    value=current_streak
    title="Current Streak (days)"
    fmt="#,#0"
/>

<BigValue
    data={q_activity__streaks_alltime}
    value=longest_streak
    title="Longest Streak (days)"
    fmt="#,#0"
/>

<BigValue
    data={q_activity__streaks_alltime}
    value=active_days_last_30
    title="Active Days (last 30)"
    fmt="#,#0"
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

<ECharts
    on:click={handleMonthlyEvent}
    on:mouseover={handleMonthlyEvent}
    data={q_activity__trends_monthly}
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
            source: q_activity__trends_monthly
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
                startValue: q_activity__trends_monthly.length > 12 ? q_activity__trends_monthly[q_activity__trends_monthly.length - 12]?.month_label : q_activity__trends_monthly[0]?.month_label,
                endValue: q_activity__trends_monthly[q_activity__trends_monthly.length - 1]?.month_label
            },
            {
                type: 'slider',
                xAxisIndex: 0,
                zoomLock: true,
                height: 50,
                bottom: 8,
                showDetail: false,
                startValue: q_activity__trends_monthly.length > 12 ? q_activity__trends_monthly[q_activity__trends_monthly.length - 12]?.month_label : q_activity__trends_monthly[0]?.month_label,
                endValue: q_activity__trends_monthly[q_activity__trends_monthly.length - 1]?.month_label
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

## By Sport Type

{#if sport_summary_pie.length > 0 || sport_time_pie.length > 0}
<div class="sport-summary-charts">
  {#if sport_summary_pie.length > 0}
  <ECharts
      on:click={handleSportPieClick}
      data={sport_summary_pie}
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
                  data: sport_summary_pie
              }
          ]
      }}
  />
  {/if}

  {#if sport_time_pie.length > 0}
  <ECharts
      on:click={handleSportPieClick}
      data={sport_time_pie}
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
                  data: sport_time_pie
              }
          ]
      }}
  />
  {/if}
</div>
{/if}

## Recent Activities

<DataTable data={recent_activities_display} link=activity_link>
    <Column id=started_at title="Date"/>
    <Column id=sport_type title="Sport"/>
    <Column id=activity_name title="Activity"/>
    <Column id=distance_display title={`Distance (${distanceUnitLabel})`}/>
    <Column id=moving_time_minutes title="Duration (min)"/>
    <Column id=average_speed_mph title="Avg Speed (mph)"/>
</DataTable>

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
