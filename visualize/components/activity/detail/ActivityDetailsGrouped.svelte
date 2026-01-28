<!--
  Activity Details Grouped
  Displays detailed activity information organized into logical groups.

  @prop {Object} activity - Activity data object
  @prop {string} speedUnit - Speed unit preference ('kph' | 'mph')
-->
<script>
  import { BigValue } from '@evidence-dev/core-components';

  export let activity;
  export let speedUnit = 'kph';

  $: maxSpeedValue = speedUnit === 'kph' ? activity?.max_speed_kph : activity?.max_speed_mph;
  $: maxSpeedLabel = speedUnit === 'kph' ? 'Max Speed (km/h)' : 'Max Speed (mph)';

  $: showPerformanceDetails = activity?.max_speed_kph > 0 ||
                               (activity?.has_heartrate && activity?.max_heartrate_bpm != null) ||
                               activity?.kilojoules != null;

  $: showActivityInfo = activity?.workout_type != null ||
                        activity?.is_trainer ||
                        activity?.is_commute ||
                        activity?.is_manual;

  $: showLocationDevice = activity?.location_city != null ||
                          activity?.device_name != null ||
                          activity?.start_latitude != null;

  $: showPrivacySocial = activity?.visibility != null || activity?.is_private != null;

  $: showEngagement = activity?.kudos_count != null ||
                      activity?.comment_count != null ||
                      activity?.achievement_count != null ||
                      activity?.pr_count != null ||
                      activity?.suffer_score != null;
</script>

{#if activity}

{#if showPerformanceDetails}
<h3>Performance Details</h3>
<div class="details-grid">
  {#if activity.max_speed_kph > 0}
  <BigValue
    data={[activity]}
    value={speedUnit === 'kph' ? 'max_speed_kph' : 'max_speed_mph'}
    title={maxSpeedLabel}
    fmt='#,##0.0'
  />
  {/if}

  {#if activity.has_heartrate && activity.max_heartrate_bpm != null}
  <BigValue
    data={[activity]}
    value='max_heartrate_bpm'
    title="Max HR (bpm)"
    fmt='#,##0'
  />
  {/if}

  {#if activity.kilojoules != null}
  <BigValue
    data={[activity]}
    value='kilojoules'
    title="Energy (kJ)"
    fmt='#,##0'
  />
  {/if}
</div>
{/if}

{#if showActivityInfo}
<h3>Activity Info</h3>
<div class="details-grid">
  {#if activity.workout_type != null}
  <BigValue
    data={[activity]}
    value='workout_type'
    title="Workout Type"
  />
  {/if}

  {#if activity.is_trainer}
  <BigValue
    data={[{value: 'Yes'}]}
    value='value'
    title="Indoor Trainer"
  />
  {/if}

  {#if activity.is_commute}
  <BigValue
    data={[{value: 'Yes'}]}
    value='value'
    title="Commute"
  />
  {/if}

  {#if activity.is_manual}
  <BigValue
    data={[{value: 'Yes'}]}
    value='value'
    title="Manual Entry"
  />
  {/if}
</div>
{/if}

{#if showLocationDevice}
<h3>Location & Device</h3>
<div class="details-grid">
  {#if activity.device_name != null}
  <BigValue
    data={[activity]}
    value='device_name'
    title="Device"
  />
  {/if}

  {#if activity.start_latitude != null && activity.start_longitude != null}
  <BigValue
    data={[{coords: `${activity.start_latitude.toFixed(6)}, ${activity.start_longitude.toFixed(6)}`}]}
    value='coords'
    title="Start Coordinates"
  />
  {/if}

  {#if activity.end_latitude != null && activity.end_longitude != null}
  <BigValue
    data={[{coords: `${activity.end_latitude.toFixed(6)}, ${activity.end_longitude.toFixed(6)}`}]}
    value='coords'
    title="End Coordinates"
  />
  {/if}
</div>
{/if}

{#if showPrivacySocial}
<h3>Privacy & Visibility</h3>
<div class="details-grid">
  {#if activity.visibility != null}
  <BigValue
    data={[activity]}
    value='visibility'
    title="Visibility"
  />
  {/if}

  {#if activity.is_private != null}
  <BigValue
    data={[{value: activity.is_private ? 'Private' : 'Public'}]}
    value='value'
    title="Privacy Status"
  />
  {/if}
</div>
{/if}

{#if showEngagement}
<h3>Engagement & Stats</h3>
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
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin-bottom: 2rem;
  }

  h3 {
    margin-top: 2rem;
    margin-bottom: 1rem;
  }
</style>