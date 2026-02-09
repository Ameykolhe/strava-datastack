<!--
  Core Metrics Grid
  Displays key activity metrics with smart conditional rendering.
  Only shows metrics that are applicable and have valid data.

  @prop {Object} activity - Activity data object
  @prop {string} distanceUnit - Distance unit preference ('km' | 'miles')
  @prop {string} speedUnit - Speed unit preference ('kph' | 'mph')
-->
<script>
  import {BigValue} from '@evidence-dev/core-components';

  export let activity;
  export let distanceUnit = 'km';
  export let speedUnit = 'kph';

  // Computed display values based on unit preference
  $: distanceValue = distanceUnit === 'km' ? activity?.distance_km : activity?.distance_miles;
  $: distanceLabel = distanceUnit === 'km' ? 'Distance (km)' : 'Distance (mi)';
  $: avgSpeedValue = speedUnit === 'kph' ? activity?.average_speed_kph : activity?.average_speed_mph;
  $: avgSpeedLabel = speedUnit === 'kph' ? 'Avg Speed (km/h)' : 'Avg Speed (mph)';
  $: paceValue = distanceUnit === 'km' ? activity?.pace_min_per_km : activity?.pace_min_per_mile;
  $: paceLabel = distanceUnit === 'km' ? 'Avg Pace (min/km)' : 'Avg Pace (min/mi)';
  $: elevationValue = activity?.elevation_gain_feet;
  $: elevationLabel = 'Elevation (ft)';

  // Computed display values for performance metrics
  $: maxSpeedValue = speedUnit === 'kph' ? activity?.max_speed_kph : activity?.max_speed_mph;
  $: maxSpeedLabel = speedUnit === 'kph' ? 'Max Speed (km/h)' : 'Max Speed (mph)';

  // Conditional display logic
  $: showDistance = activity?.distance_meters > 0;
  $: showElevation = activity?.elevation_gain_meters > 0;
  $: showSpeed = activity?.average_speed_kph > 0;
  $: showPace = activity?.pace_min_per_km != null && activity?.distance_meters > 0;
  $: showHeartRate = activity?.has_heartrate && activity?.average_heartrate_bpm != null;
  $: showPower = activity?.has_power_meter && activity?.average_watts != null;
  $: showCalories = activity?.calories_burned != null;
  $: showElapsedTime = activity?.elapsed_time_seconds !== activity?.moving_time_seconds;
  $: showMaxSpeed = activity?.max_speed_kph > 0;
  $: showMaxHeartRate = activity?.has_heartrate && activity?.max_heartrate_bpm != null;
</script>

{#if activity}
  <div class="metrics-grid">
    {#if showDistance}
      <BigValue
          data={[activity]}
          value={distanceUnit === 'km' ? 'distance_km' : 'distance_miles'}
          title={distanceLabel}
          fmt='#,##0.00'
      />
    {/if}

    <BigValue
        data={[activity]}
        value='moving_time_display'
        title="Moving Time"
    />

    {#if showElapsedTime}
      <BigValue
          data={[activity]}
          value='elapsed_time_display'
          title="Elapsed Time"
      />
    {/if}

    {#if showElevation}
      <BigValue
          data={[activity]}
          value='elevation_gain_feet'
          title={elevationLabel}
          fmt='#,##0'
      />
    {/if}

    {#if showSpeed}
      <BigValue
          data={[activity]}
          value={speedUnit === 'kph' ? 'average_speed_kph' : 'average_speed_mph'}
          title={avgSpeedLabel}
          fmt='#,##0.0'
      />
    {/if}

    {#if showPace}
      <BigValue
          data={[activity]}
          value={distanceUnit === 'km' ? 'pace_min_per_km' : 'pace_min_per_mile'}
          title={paceLabel}
          fmt='#,##0.00'
      />
    {/if}

    {#if showHeartRate}
      <BigValue
          data={[activity]}
          value='average_heartrate_bpm'
          title="Avg HR (bpm)"
          fmt='#,##0'
      />
    {/if}

    {#if showPower}
      <BigValue
          data={[activity]}
          value='average_watts'
          title="Avg Power (W)"
          fmt='#,##0'
      />
    {/if}

    {#if showCalories}
      <BigValue
          data={[activity]}
          value='calories_burned'
          title="Calories"
          fmt='#,##0'
      />
    {/if}

    {#if showMaxSpeed}
      <BigValue
          data={[activity]}
          value={speedUnit === 'kph' ? 'max_speed_kph' : 'max_speed_mph'}
          title={maxSpeedLabel}
          fmt='#,##0.0'
      />
    {/if}

    {#if showMaxHeartRate}
      <BigValue
          data={[activity]}
          value='max_heartrate_bpm'
          title="Max HR (bpm)"
          fmt='#,##0'
      />
    {/if}
  </div>
{/if}

<style>
  .metrics-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 1rem;
    margin-bottom: 2rem;
  }
</style>
