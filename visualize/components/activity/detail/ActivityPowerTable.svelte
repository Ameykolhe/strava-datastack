<!--
  Activity Power Table
  Displays power and energy metrics using BigValue components.

  @prop {Array<Object>} activityData - Array containing activity data (q_activity_detail__activity)
-->
<script lang="ts">
  import { BigValue } from '@evidence-dev/core-components';

  export let activityData: any[];
</script>

{#if activityData && activityData.length > 0}
<BigValue
  data={activityData}
  value="average_watts"
  title="Avg Power (W)"
  fmt="#,##0"
/>

<BigValue
  data={activityData}
  value="kilojoules"
  title="Energy (kJ)"
  fmt="#,##0"
/>
{/if}