<script>
  import { DataTable, Column } from '@evidence-dev/core-components';

  export let activitiesDisplay;
  export let distanceSupported;
  export let elevationSupported;
  export let hasSpeed;
  export let hasPace;
  export let hasHeartRate;
  export let hasWatts;
  export let distanceUnitLabel;
</script>

<DataTable data={activitiesDisplay} link=activity_link>
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