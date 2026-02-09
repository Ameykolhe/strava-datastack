<script>
  import {DataTable, Column} from '@evidence-dev/core-components';

  export let efforts = [];
  export let distanceUnit = 'km';
  export let speedUnit = 'kph';

  $: isKm = distanceUnit === 'km';
  $: distanceField = isKm ? 'distance_km' : 'distance_miles';
  $: paceField = isKm ? 'pace_min_per_km' : 'pace_min_per_mile';
  $: speedField = speedUnit === 'kph' ? 'average_speed_kph' : 'average_speed_mph';
  $: distanceTitle = isKm ? 'Distance (km)' : 'Distance (mi)';
  $: paceTitle = isKm ? 'Pace (min/km)' : 'Pace (min/mi)';
  $: speedTitle = speedUnit === 'kph' ? 'Avg Speed (km/h)' : 'Avg Speed (mph)';
</script>

{#if efforts?.length > 0}
  <DataTable data={efforts} rows={20}>
    <Column id='segment_name' title='Segment'/>
    <Column id={distanceField} title={distanceTitle} fmt='#,##0.00'/>
    <Column id='time_display' title='Time'/>
    <Column id={speedField} title={speedTitle} fmt='#,##0.00'/>
    <Column id={paceField} title={paceTitle} fmt='#,##0.00'/>
    <Column id='average_grade' title='Avg Grade (%)' fmt='#,##0.0'/>
    <Column id='climb_category_label' title='Climb'/>
    <Column id='pr_rank' title='PR Rank'/>
    <Column id='kom_rank' title='KOM Rank'/>
    <Column id='average_heartrate_bpm' title='Avg HR (bpm)'/>
  </DataTable>
{:else}
  <p><em>No segment data available for this activity.</em></p>
{/if}
