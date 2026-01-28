<!--
  Activity Heart Rate Table
  Displays heart rate metrics using BigValue components.

  @prop {Array<Object>} activityData - Array containing activity data (q_activity_detail__activity)
-->
<script lang="ts">
  import { BigValue } from '@evidence-dev/core-components';

  export let activityData: any[];
</script>

{#if activityData && activityData.length > 0}
<BigValue
  data={activityData}
  value="average_heartrate_bpm"
  title="Avg HR (bpm)"
  fmt="#,##0"
/>

<BigValue
  data={activityData}
  value="max_heartrate_bpm"
  title="Max HR (bpm)"
  fmt="#,##0"
/>
{/if}