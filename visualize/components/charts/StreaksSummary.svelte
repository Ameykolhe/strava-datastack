<!--
  Streaks Summary
  Displays activity streaks KPIs including active days and longest streak.

  @prop {Array<{active_days_year: number, longest_streak: number}>} data - Streaks data
-->
<script>
  import {BigValue} from '@evidence-dev/core-components';

  export let data = [];
</script>

{#if data && data.length > 0}
  <BigValue
      data={data}
      value="active_days_year"
      title="Active Days (year)"
      fmt="#,##0"
  />

  <BigValue
      data={data}
      value="longest_streak"
      title="Longest Streak (days)"
      fmt="#,##0"
  />
{:else}
  <div class="no-data-message">
    <p>No streak data available.</p>
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
