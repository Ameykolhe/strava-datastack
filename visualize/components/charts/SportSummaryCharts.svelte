<!--
  Sport Summary Charts
  Displays pie charts for activity count and time distribution by sport type.

  @prop {Array<{sport_type: string, activity_count: number, total_moving_time_hours: number, sport_slug: string}>} summaryRows - Sport summary data
  @prop {Function|null} onSliceClick - Optional click handler for pie slices
-->
<script>
  import {ECharts} from '@evidence-dev/core-components';

  export let summaryRows = [];
  export let onSliceClick = null;

  $: activityData = summaryRows?.map((row) => ({
    name: row.sport_type,
    value: row.activity_count,
    sport_slug: row.sport_slug
  })) ?? [];
  $: timeData = summaryRows?.map((row) => ({
    name: row.sport_type,
    value: row.total_moving_time_hours,
    sport_slug: row.sport_slug
  })) ?? [];

  const handleSliceClick = (event) => {
    if (onSliceClick) onSliceClick(event);
  };

  /**
   * Build pie chart configuration options.
   * @param {string} title - Chart title displayed in center
   * @param {Array} data - Pie chart data
   * @param {boolean} showLegend - Whether to show the legend
   * @returns {object} ECharts config object
   */
  const buildPieOptions = (title, data, showLegend) => ({
    backgroundColor: 'transparent',
    tooltip: {trigger: 'item'},
    legend: showLegend ? {
      top: 'middle',
      right: 0,
      orient: 'vertical'
    } : {show: false},
    title: {
      text: title,
      left: '35%',
      top: '50%',
      textAlign: 'center',
      textVerticalAlign: 'middle'
    },
    series: [
      {
        name: title,
        type: 'pie',
        radius: ['30%', '70%'],
        center: ['35%', '50%'],
        avoidLabelOverlap: false,
        itemStyle: {borderRadius: 6, borderColor: '#fff', borderWidth: 1},
        label: {show: false},
        labelLine: {show: false},
        data
      }
    ]
  });
</script>

{#if summaryRows.length > 0}
  <div class="sport-summary-charts">
    {#if activityData.length > 0}
      <ECharts
          on:click={handleSliceClick}
          data={activityData}
          config={buildPieOptions('Activities', activityData, false)}
      />
    {/if}

    {#if timeData.length > 0}
      <ECharts
          on:click={handleSliceClick}
          data={timeData}
          config={buildPieOptions('Time (hrs)', timeData, true)}
      />
    {/if}
  </div>
{:else}
  <div class="no-data-message">
    <p>No sport data available.</p>
  </div>
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

  .no-data-message {
    padding: 2rem;
    text-align: center;
    background: var(--grey-100, #f3f4f6);
    border-radius: 8px;
    color: var(--grey-500, #6b7280);
  }
</style>
