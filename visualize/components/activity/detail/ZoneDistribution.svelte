<!--
  Zone Distribution
  Displays zone distribution with bar chart and data table.
  Handles HR, Power, and Pace zones with appropriate column configurations.

  @prop {Array} zoneData - Zone distribution data
  @prop {string} zoneType - Type of zone ('hr' | 'power' | 'pace')
  @prop {string} title - Section title
-->
<script>
  import {BarChart, DataTable, Column} from '@evidence-dev/core-components';

  export let zoneData;
  export let zoneType;
  export let title;

  // Column configurations by zone type
  $: minColumn = zoneType === 'hr' ? 'zone_min_bpm' :
      zoneType === 'power' ? 'zone_min_watts' :
          'zone_min_pace';

  $: maxColumn = zoneType === 'hr' ? 'zone_max_bpm' :
      zoneType === 'power' ? 'zone_max_watts' :
          'zone_max_pace';

  $: minLabel = zoneType === 'hr' ? 'Min (bpm)' :
      zoneType === 'power' ? 'Min (W)' :
          'Min (/km)';

  $: maxLabel = zoneType === 'hr' ? 'Max (bpm)' :
      zoneType === 'power' ? 'Max (W)' :
          'Max (/km)';

  $: minFormat = (zoneType === 'hr' || zoneType === 'power') ? '#,##0' : undefined;
</script>

{#if zoneData && zoneData.length > 0}
  <h3>{title}</h3>

  <div class="zone-split">
    <BarChart
        data={zoneData}
        x='zone_name'
        y='pct_in_zone'
        sort={false}
        yMin={0}
        yMax={1}
        yFmt="0%"
        yAxisLabels={false}
        xGridlines={false}
        yGridlines={false}
        echartsOptions={{
      grid: {},
      xAxis: {
        axisLabel: {
          rotate: 90,
          interval: 0,
          formatter: (value) => value
        }
      }
    }}
    />
    <div>
      <DataTable data={zoneData} rows={5}>
        <Column id='zone_name' title="Zone"/>
        <Column id={minColumn} title={minLabel} fmt={minFormat}/>
        <Column id={maxColumn} title={maxLabel} fmt={minFormat}/>
      </DataTable>
    </div>
  </div>
{/if}

<style>
  .zone-split {
    display: grid;
    grid-template-columns: minmax(0, 7fr) minmax(0, 3fr);
    gap: 16px;
    align-items: start;
    margin-bottom: 2rem;
  }

  @media (max-width: 900px) {
    .zone-split {
      grid-template-columns: minmax(0, 1fr);
    }
  }
</style>