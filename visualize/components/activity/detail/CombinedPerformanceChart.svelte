<script>
  import { ECharts } from '@evidence-dev/core-components';

  export let streamData = [];
  export let distanceUnit = 'km';
  export let sportType = '';

  $: isKm = distanceUnit === 'km';
  $: sport = (sportType || '').toLowerCase();
  $: isRunLike = /run|walk|hike/.test(sport);

  $: xField = isKm ? 'distance_mid_km' : 'distance_mid_miles';
  $: xLabel = isKm ? 'Distance (km)' : 'Distance (mi)';

  $: elevationField = isKm ? 'avg_altitude_meters' : 'avg_altitude_feet';
  $: elevationLabel = isKm ? 'Elevation (m)' : 'Elevation (ft)';

  $: movementField = isRunLike
    ? (isKm ? 'avg_pace_min_per_km' : 'avg_pace_min_per_mile')
    : (isKm ? 'avg_velocity_kph' : 'avg_velocity_mph');
  $: movementLabel = isRunLike
    ? (isKm ? 'Pace (min/km)' : 'Pace (min/mi)')
    : (isKm ? 'Speed (km/h)' : 'Speed (mph)');

  $: chartData = streamData?.filter((row) => {
    const hasX = row?.[xField] != null;
    if (!hasX) return false;
    return row?.[elevationField] != null || row?.[movementField] != null || row?.avg_heartrate_bpm != null;
  }) ?? [];

  $: hasHeartRate = chartData.some((row) => row?.avg_heartrate_bpm != null);

  $: panelLayout = hasHeartRate
    ? {
      grids: [
        { top: 18, height: '24%' },
        { top: '39%', height: '24%' },
        { top: '60%', height: '24%' }
      ],
      bottom: 46
    }
    : {
      grids: [
        { top: 18, height: '34%' },
        { top: '53%', height: '34%' }
      ],
      bottom: 46
    };

  function fmt(value, digits = 1) {
    if (value == null || Number.isNaN(Number(value))) return 'n/a';
    return Number(value).toFixed(digits);
  }

  function getNearestRow(distanceValue) {
    if (!chartData.length || distanceValue == null) return null;
    let nearest = null;
    let minDelta = Number.POSITIVE_INFINITY;

    for (const row of chartData) {
      const x = row?.[xField];
      if (x == null) continue;
      const delta = Math.abs(Number(x) - Number(distanceValue));
      if (delta < minDelta) {
        minDelta = delta;
        nearest = row;
      }
    }
    return nearest;
  }

  $: tooltipFormatter = (params) => {
    if (!params?.length) return '';
    const distanceValue = params[0]?.axisValue ?? params[0]?.value;
    const row = getNearestRow(distanceValue);
    const lines = [`Distance: ${fmt(distanceValue, 2)} ${isKm ? 'km' : 'mi'}`];
    if (!row) return lines.join('<br/>');

    lines.push(`Elevation: ${fmt(row[elevationField], 1)} ${isKm ? 'm' : 'ft'}`);
    lines.push(`${isRunLike ? 'Pace' : 'Speed'}: ${fmt(row[movementField], isRunLike ? 2 : 1)} ${isRunLike ? (isKm ? 'min/km' : 'min/mi') : (isKm ? 'km/h' : 'mph')}`);
    if (hasHeartRate) lines.push(`Heart Rate: ${fmt(row.avg_heartrate_bpm, 0)} bpm`);

    return lines.join('<br/>');
  };
</script>

{#if chartData.length > 0}
  <ECharts
    data={chartData}
    config={{
      backgroundColor: 'transparent',
      grid: panelLayout.grids.map((grid) => ({
        left: '8%',
        right: '6%',
        top: grid.top,
        height: grid.height,
        containLabel: true
      })),
      legend: {
        top: 4
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'line' },
        formatter: tooltipFormatter
      },
      axisPointer: {
        link: [{ xAxisIndex: 'all' }]
      },
      xAxis: panelLayout.grids.map((_, index) => ({
        type: 'value',
        gridIndex: index,
        name: '',
        axisLabel: { show: false },
        splitLine: { show: false }
      })),
      yAxis: [
        {
          type: 'value',
          gridIndex: 0,
          name: '',
          position: 'left',
          axisLabel: { show: false },
          splitLine: { show: false }
        },
        {
          type: 'value',
          gridIndex: 1,
          name: '',
          position: 'left',
          inverse: isRunLike,
          axisLabel: { show: false },
          splitLine: { show: false }
        },
        ...(hasHeartRate
          ? [{
            type: 'value',
            gridIndex: 2,
            name: '',
            position: 'left',
            axisLabel: { show: false },
            splitLine: { show: false }
          }]
          : [])
      ],
      dataZoom: [
        {
          type: 'inside',
          xAxisIndex: hasHeartRate ? [0, 1, 2] : [0, 1]
        }
      ],
      dataset: {
        source: chartData
      },
      series: [
        {
          name: 'Elevation',
          type: 'line',
          xAxisIndex: 0,
          yAxisIndex: 0,
          encode: { x: xField, y: elevationField },
          showSymbol: false,
          smooth: 0.2,
          lineStyle: { width: 2, color: '#6f7d8c' }
        },
        {
          name: isRunLike ? 'Pace' : 'Speed',
          type: 'line',
          xAxisIndex: 1,
          yAxisIndex: 1,
          encode: { x: xField, y: movementField },
          showSymbol: false,
          smooth: 0.2,
          lineStyle: { width: 2, color: '#2f80ed' }
        },
        ...(hasHeartRate
          ? [{
            name: 'Heart Rate',
            type: 'line',
            xAxisIndex: 2,
            yAxisIndex: 2,
            encode: { x: xField, y: 'avg_heartrate_bpm' },
            showSymbol: false,
            smooth: 0.2,
            lineStyle: { width: 2, color: '#d14343' }
          }]
          : [])
      ]
    }}
  />
{:else}
  <p><em>No stream data available for this activity.</em></p>
{/if}
