<!--
  Activity Calendar Heatmap
  Displays a calendar heatmap showing daily activity counts.

  @prop {Array<{activity_date: string, activity_count: number}>} data - Daily activity counts
-->
<script>
  import { CalendarHeatmap } from '@evidence-dev/core-components';

  export let data = [];
</script>

{#if data && data.length > 0}
  <CalendarHeatmap
    data={data}
    date="activity_date"
    value="activity_count"
    min={0}
    max={5}
    legend={false}
  />
{:else}
  <div class="no-data-message">
    <p>No activity data available.</p>
  </div>
{/if}

<style>
  .no-data-message {
    padding: 2rem;
    text-align: center;
    background: var(--grey-100, #f3f4f6);
    border-radius: 8px;
    color: var(--grey-500, #6b7280);
  }
</style>
