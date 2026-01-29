<!--
  Engagement Stats
  Displays activity engagement metrics including kudos, comments, achievements, PRs, and suffer score.

  @prop {Object} activity - Activity data object
-->
<script>
  import {BigValue} from '@evidence-dev/core-components';

  export let activity;

  $: showEngagement = activity?.kudos_count != null ||
      activity?.comment_count != null ||
      activity?.achievement_count != null ||
      activity?.pr_count != null ||
      activity?.suffer_score != null;
</script>

{#if activity}

  {#if showEngagement}
    <div class="details-grid">
      {#if activity.kudos_count != null}
        <BigValue
            data={[activity]}
            value='kudos_count'
            title="Kudos"
            fmt='#,##0'
        />
      {/if}

      {#if activity.comment_count != null}
        <BigValue
            data={[activity]}
            value='comment_count'
            title="Comments"
            fmt='#,##0'
        />
      {/if}

      {#if activity.achievement_count != null}
        <BigValue
            data={[activity]}
            value='achievement_count'
            title="Achievements"
            fmt='#,##0'
        />
      {/if}

      {#if activity.pr_count != null}
        <BigValue
            data={[activity]}
            value='pr_count'
            title="PRs"
            fmt='#,##0'
        />
      {/if}

      {#if activity.suffer_score != null}
        <BigValue
            data={[activity]}
            value='suffer_score'
            title="Suffer Score"
            fmt='#,##0'
        />
      {/if}

    </div>

  {/if}

{/if}

<style>
  .details-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 1rem;
    margin-bottom: 2rem;
  }
</style>