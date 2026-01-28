<!--
  Activity Strava Stats Table
  Displays Strava social engagement metrics using BigValue components.

  @prop {Array<Object>} activityData - Array containing activity data (q_activity_detail__activity)
-->
<script lang="ts">
  import { BigValue } from '@evidence-dev/core-components';

  export let activityData: any[];
</script>

{#if activityData && activityData.length > 0}
<BigValue
  data={activityData}
  value="kudos_count"
  title="Kudos"
  fmt="#,##0"
/>

<BigValue
  data={activityData}
  value="comment_count"
  title="Comments"
  fmt="#,##0"
/>

<BigValue
  data={activityData}
  value="achievement_count"
  title="Achievements"
  fmt="#,##0"
/>

<BigValue
  data={activityData}
  value="pr_count"
  title="PRs"
  fmt="#,##0"
/>

<BigValue
  data={activityData}
  value="suffer_score"
  title="Suffer Score"
  fmt="#,##0"
/>
{/if}