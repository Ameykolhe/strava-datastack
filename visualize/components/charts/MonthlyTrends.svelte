<!--
  Monthly Trends Chart
  Interactive chart showing monthly activity metrics with KPI summary.
  Displays a fixed 12-month window with pan support to navigate through history.

  Expected data shape:
  {
    month_start: Date,
    month_label: string,
    activity_count: number,
    total_distance_km: number,
    total_distance_miles: number,
    total_moving_time_hours: number,
    total_elevation_gain_feet: number
  }

  @prop {Array} data - Monthly aggregated activity data
  @prop {boolean} distanceSupported - Whether distance metrics are available
  @prop {boolean} elevationSupported - Whether elevation metrics are available
  @prop {string} distanceMonthlyField - Field name for monthly distance (total_distance_km/miles)
  @prop {string} distanceSeriesField - Field name for chart series distance
  @prop {string} distanceSeriesName - Display name for distance series
  @prop {string} distanceMonthlyTitle - Title for distance KPI
  @prop {number} minChartPoints - Minimum data points to show chart
-->
<script>
  import { BigValue, ECharts } from '@evidence-dev/core-components';
  import { pctChange } from '../lib/math.js';

  export let data = [];
  export let distanceSupported = true;
  export let elevationSupported = true;
  export let distanceMonthlyField = 'total_distance_km';
  export let distanceSeriesField = 'total_distance_km';
  export let distanceSeriesName = 'Distance (km)';
  export let distanceMonthlyTitle = 'Distance (km)';
  export let minChartPoints = 0;

  const WINDOW_MONTHS = 12;

  let selectedMonth = null;

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

  $: currentMonth = data?.[data.length - 1]?.month_label;
  $: if (!selectedMonth && currentMonth) selectedMonth = currentMonth;
  $: selectedRow = data?.find((row) => row.month_label === selectedMonth) ??
    (data?.length ? data[data.length - 1] : null);
  $: selectedIndex = data?.findIndex((row) => row.month_label === selectedRow?.month_label) ?? -1;
  $: prevRow = selectedIndex > 0 ? data[selectedIndex - 1] : null;

  const toDate = (value) => (value ? new Date(value) : value);
  const formatMonthLabel = (value) => {
    if (!value) return '';
    const date = typeof value === 'string' ? new Date(value) : value;
    if (!date || Number.isNaN(date.getTime?.())) return '';
    return date.toLocaleString('en-US', { month: 'long', year: 'numeric' });
  };

  $: selectedWithComparisons = selectedRow ? {
    ...selectedRow,
    month_start: toDate(selectedRow?.month_start),
    distance_change: distanceSupported ? pctChange(selectedRow?.[distanceMonthlyField], prevRow?.[distanceMonthlyField]) : null,
    time_change: pctChange(selectedRow?.total_moving_time_hours, prevRow?.total_moving_time_hours),
    elevation_change: elevationSupported ? pctChange(selectedRow?.total_elevation_gain_feet, prevRow?.total_elevation_gain_feet) : null,
    count_change: pctChange(selectedRow?.activity_count, prevRow?.activity_count)
  } : null;
  $: selectedMonthTitle = selectedRow ? formatMonthLabel(toDate(selectedRow.month_start)) : '';
  $: hasChartData = minChartPoints > 0 ? data?.length >= minChartPoints : true;

  // Calculate fixed 12-month window positioning (show last 12 months)
  $: totalPoints = data?.length ?? 0;
  $: windowSpan = WINDOW_MONTHS > 1 ? WINDOW_MONTHS - 1 : 1;
  $: percentSpan = totalPoints > 1 ? (windowSpan / (totalPoints - 1)) * 100 : 100;
  $: zoomStartPercent = totalPoints > WINDOW_MONTHS ? 100 - percentSpan : 0;
  $: zoomEndPercent = 100;

  // Fixed 12-month window with pan-only support
  $: dataZoom = totalPoints > WINDOW_MONTHS ? [
    {
      type: 'inside',
      xAxisIndex: 0,
      zoomLock: true,
      zoomOnMouseWheel: false,
      moveOnMouseWheel: true,
      moveOnMouseMove: false,
      start: zoomStartPercent,
      end: zoomEndPercent,
      minSpan: percentSpan,
      maxSpan: percentSpan
    },
    {
      type: 'slider',
      xAxisIndex: 0,
      zoomLock: true,
      brushSelect: false,
      height: 30,
      bottom: 8,
      showDetail: false,
      showDataShadow: true,
      start: zoomStartPercent,
      end: zoomEndPercent,
      minSpan: percentSpan,
      maxSpan: percentSpan,
      handleSize: '100%',
      handleStyle: {
        borderRadius: 4
      }
    }
  ] : [];
</script>

{#if selectedMonthTitle}
<h3>{selectedMonthTitle}</h3>
{/if}

{#if selectedWithComparisons}
<div class="monthly-kpis">
  {#if distanceSupported}
  <BigValue data={[selectedWithComparisons]} value={distanceMonthlyField} comparison="distance_change" comparisonFmt="pct1" comparisonTitle="MoM" title={distanceMonthlyTitle} fmt="#,##0.0"/>
  {/if}
  <BigValue data={[selectedWithComparisons]} value="total_moving_time_hours" comparison="time_change" comparisonFmt="pct1" comparisonTitle="MoM" title="Time (hrs)" fmt="#,##0.0"/>
  {#if elevationSupported}
  <BigValue data={[selectedWithComparisons]} value="total_elevation_gain_feet" comparison="elevation_change" comparisonFmt="pct1" comparisonTitle="MoM" title="Elevation (ft)" fmt="#,##0"/>
  {/if}
  <BigValue data={[selectedWithComparisons]} value="activity_count" comparison="count_change" comparisonFmt="pct1" comparisonTitle="MoM" title="Activity Count" fmt="#,##0"/>
</div>
{/if}

{#if hasChartData}
<ECharts
  on:click={handleMonthlyEvent}
  on:mouseover={handleMonthlyEvent}
  data={data}
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
      bottom: totalPoints > WINDOW_MONTHS ? 60 : 40,
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
      source: data
    },
    dataZoom,
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