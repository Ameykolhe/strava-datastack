<!--
  Activity Header
  Displays activity name, date/time, timezone, and device.

  @prop {string} activityName - Activity name
  @prop {Date|string} startedAt - UTC start timestamp
  @prop {string} [timezone] - Timezone identifier (e.g., "(GMT+05:30) Asia/Kolkata")
  @prop {string} [deviceName] - Device name used for recording the activity
-->
<script>
  export let activityName;
  export let startedAt;
  export let timezone = null;
  export let deviceName = null;

  // Extract timezone identifier from format like "(GMT+05:30) Asia/Kolkata"
  $: timezoneId = (() => {
    if (!timezone) return null;

    // Extract the timezone name after the last space
    // e.g., "(GMT+05:30) Asia/Kolkata" -> "Asia/Kolkata"
    const match = timezone.match(/\)\s*(.+)$/);
    return match ? match[1] : timezone;
  })();

  // Format the UTC time in the activity's timezone
  $: formattedDateTime = (() => {
    if (!startedAt) return '';

    try {
      // Handle both Date objects and strings
      let date;
      if (startedAt instanceof Date) {
        date = startedAt;
      } else if (typeof startedAt === 'string') {
        date = new Date(startedAt);
      } else {
        console.warn('Unexpected startedAt type:', typeof startedAt);
        return String(startedAt);
      }

      // Format the date in the activity's timezone
      // startedAt is UTC, and we convert it to the activity's local timezone
      const formatter = new Intl.DateTimeFormat('en-US', {
        weekday: 'short',
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        hour12: true,
        timeZone: timezoneId || undefined
      });

      return formatter.format(date);
    } catch (e) {
      console.error('Error formatting date:', e, 'Input:', startedAt);
      return String(startedAt);
    }
  })();

  // Extract timezone abbreviation if available
  $: timezoneAbbr = (() => {
    if (!timezoneId || !startedAt) return timezoneId;

    try {
      // Handle both Date objects and strings
      let date;
      if (startedAt instanceof Date) {
        date = startedAt;
      } else if (typeof startedAt === 'string') {
        date = new Date(startedAt);
      } else {
        return timezoneId;
      }

      // Format with timezone name to get abbreviation
      const formatted = date.toLocaleString('en-US', {
        timeZone: timezoneId,
        timeZoneName: 'short'
      });

      // Extract timezone abbreviation (e.g., "IST", "EST", "PST")
      const match = formatted.match(/\b([A-Z]{2,5})\b$/);
      return match ? match[1] : timezoneId;
    } catch (e) {
      console.error('Error extracting timezone abbreviation:', e);
      return timezoneId;
    }
  })();
</script>

<h1>{activityName}</h1>

<p class="activity-meta">
  {formattedDateTime}
  {#if timezoneAbbr}
    <span class="timezone">{timezoneAbbr}</span>
  {/if}
  {#if deviceName}
    <span class="device-separator">•</span>
    <span class="device">{deviceName}</span>
  {/if}
</p>

<style>
  h1 {
    font-size: 2rem;
    line-height: 1.2;
    font-weight: 700;
    margin-bottom: 1rem;
  }

  .activity-meta {
    font-size: 1rem;
    line-height: 1.5;
    color: var(--grey-300);
    margin-bottom: 0.5rem;
  }

  .timezone {
    color: var(--grey-200);
    font-size: 0.9rem;
  }

  .device-separator {
    margin: 0 0.5rem;
    color: var(--grey-400);
  }

  .device {
    color: var(--grey-300);
    font-size: 0.9rem;
  }
</style>