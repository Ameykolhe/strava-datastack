<!--
  Distance Unit Toggle
  Toggle switch for km/mi distance units with localStorage persistence.
  Emits 'distance-unit-change' custom event when unit changes.
-->
<script>
  import {onMount} from 'svelte';
  import {browser} from '$app/environment';

  const STORAGE_KEY = 'distanceUnit';
  const VALID_UNITS = new Set(['km', 'mi']);

  let unit = 'km';

  const emitChange = (nextUnit) => {
    if (!browser) return;
    window.dispatchEvent(
        new CustomEvent('distance-unit-change', {
          detail: {unit: nextUnit}
        })
    );
  };

  const setUnit = (nextUnit) => {
    if (!VALID_UNITS.has(nextUnit)) return;
    unit = nextUnit;
    if (browser) {
      localStorage.setItem(STORAGE_KEY, unit);
      emitChange(unit);
    }
  };

  onMount(() => {
    if (!browser) return;
    const saved = localStorage.getItem(STORAGE_KEY);
    if (VALID_UNITS.has(saved)) {
      unit = saved;
    }
    emitChange(unit);
  });
</script>

<div class="flex items-center justify-between gap-2">
  <div class="text-[10px] font-semibold uppercase tracking-wide text-base-content-muted">
    Distance
  </div>
  <div class="inline-flex rounded-lg bg-base-200 p-0.5">
    <button
        type="button"
        class="px-2.5 py-1 text-xs font-semibold rounded-md transition-colors {unit === 'km'
				? 'bg-base-100 text-base-content shadow'
				: 'text-base-content-muted hover:text-base-content'}"
        on:click={() => setUnit('km')}
    >
      km
    </button>
    <button
        type="button"
        class="px-2.5 py-1 text-xs font-semibold rounded-md transition-colors {unit === 'mi'
				? 'bg-base-100 text-base-content shadow'
				: 'text-base-content-muted hover:text-base-content'}"
        on:click={() => setUnit('mi')}
    >
      mi
    </button>
  </div>
</div>
