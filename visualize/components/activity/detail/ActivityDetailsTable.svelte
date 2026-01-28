<!--
  Activity Details Table
  Displays comprehensive activity metrics using BigValue components.

  @prop {Array<Object>} activityData - Array containing activity data (q_activity_detail__activity)
-->
<script lang="ts">
  import { BigValue } from '@evidence-dev/core-components';

  export let activityData: any[];
</script>

{#if activityData && activityData.length > 0}
<BigValue
  data={activityData}
  value="sport_type"
  title="Sport Type"
/>

<BigValue
  data={activityData}
  value="workout_type"
  title="Workout Type"
/>

<BigValue
  data={activityData}
  value="elapsed_time_seconds"
  title="Elapsed Time (sec)"
  fmt="#,##0"
/>

<BigValue
  data={activityData}
  value="moving_time_seconds"
  title="Moving Time (sec)"
  fmt="#,##0"
/>

<BigValue
  data={activityData}
  value="distance_miles"
  title="Distance (mi)"
  fmt="#,##0.00"
/>

<BigValue
  data={activityData}
  value="elevation_gain_feet"
  title="Elevation Gain (ft)"
  fmt="#,##0"
/>

<BigValue
  data={activityData}
  value="average_speed_mph"
  title="Avg Speed (mph)"
  fmt="#,##0.0"
/>

<BigValue
  data={activityData}
  value="max_speed_mph"
  title="Max Speed (mph)"
  fmt="#,##0.0"
/>
{/if}