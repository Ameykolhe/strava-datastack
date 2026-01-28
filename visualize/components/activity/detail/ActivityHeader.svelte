<!--
  Activity Header
  Displays activity name, sport type, date/time, timezone, and location.

  @prop {string} activityName - Activity name
  @prop {string} sportType - Sport type (e.g., "Run", "Ride")
  @prop {string} startedAtLocal - Local start timestamp
  @prop {string} [timezone] - Timezone identifier (optional)
  @prop {string} [locationCity] - City name (optional)
  @prop {string} [locationState] - State name (optional)
  @prop {string} [locationCountry] - Country name (optional)
-->
<script>
  export let activityName;
  export let sportType;
  export let startedAtLocal;
  export let timezone = null;
  export let locationCity = null;
  export let locationState = null;
  export let locationCountry = null;

  $: locationParts = [locationCity, locationState, locationCountry].filter(Boolean);
  $: locationDisplay = locationParts.length > 0 ? locationParts.join(', ') : null;
</script>

<h1>{activityName}</h1>

<p>
  <strong>{sportType}</strong> • {startedAtLocal}
  {#if timezone}
    ({timezone})
  {/if}
</p>

{#if locationDisplay}
<p>
  📍 {locationDisplay}
</p>
{/if}