<!--
  Activities List Component
  Reusable data table for displaying activity lists with automatic column detection.

  Expected data shape (from src_strava__activity_detail):
  {
    activity_id: number,
    activity_name: string,
    sport_type: string (optional),
    started_at: Date/string,
    distance_km: number,
    distance_miles: number,
    moving_time_minutes: number,
    elevation_gain_feet: number,
    average_speed_kph: number,
    pace_min_per_km: number,
    average_heartrate_bpm: number,
    average_watts: number,
    activity_link: string
  }

  @prop {Array} data - Activity list data
-->
<script>
  import {DataTable, Column} from '@evidence-dev/core-components';
  import {distanceUnitStore} from '../utils/distanceUnit.js';

  export let data = [];

  let distanceUnit = 'km';
  $: distanceUnit = $distanceUnitStore;

  // Compute distance-related fields based on unit preference
  $: isKm = distanceUnit === 'km';
  $: distanceUnitLabel = isKm ? 'km' : 'mi';

  // Create display data with distance_display field
  $: displayData = data?.map(row => ({
    ...row,
    distance_display: isKm ? row.distance_km : row.distance_miles
  })) ?? [];

  // Auto-detect feature support from data
  $: hasSportType = data?.some(row => row.sport_type != null) ?? false;
  $: distanceSupported = data?.some(row =>
      row.distance_km != null && row.distance_km > 0
  ) ?? false;
  $: elevationSupported = data?.some(row =>
      row.elevation_gain_feet != null && row.elevation_gain_feet > 0
  ) ?? false;
  $: hasSpeed = data?.some(row =>
      row.average_speed_kph != null
  ) ?? false;
  $: hasPace = data?.some(row =>
      row.pace_min_per_km != null
  ) ?? false;
  $: hasHeartRate = data?.some(row =>
      row.average_heartrate_bpm != null
  ) ?? false;
  $: hasWatts = data?.some(row =>
      row.average_watts != null
  ) ?? false;
</script>

<DataTable data={displayData} link=activity_link>
  <Column id=started_at title="Date"/>
  {#if hasSportType}
    <Column id=sport_type title="Sport"/>
  {/if}
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
    <Column id=pace_min_per_km title="Avg Pace (min/km)"/>
  {/if}
  {#if hasHeartRate}
    <Column id=average_heartrate_bpm title="Avg HR (bpm)"/>
  {/if}
  {#if hasWatts}
    <Column id=average_watts title="Avg Watts"/>
  {/if}
</DataTable>
