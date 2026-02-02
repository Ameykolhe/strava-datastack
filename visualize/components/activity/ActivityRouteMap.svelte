<!--
  Activity Route Map
  Displays a single activity route on an interactive map.

  @prop {string} polyline - Encoded polyline string for the route
  @prop {number} height - Map height in pixels (default: 400)
  @prop {string} lineColor - Route line color (default: Strava orange #FC4C02)
  @prop {number} lineWeight - Route line thickness (default: 3)
-->
<script>
  import {onMount, onDestroy} from "svelte";
  import {decodePolyline} from "../lib/polyline.js";
  import {isDarkMode, getTileUrl} from "../lib/mapUtils.js";

  // Props
  export let polyline = "";
  export let height = 400;
  export let lineColor = "#FC4C02"; // Strava orange
  export let lineWeight = 3;

  let mapEl;
  let map;
  let L;
  let initialBounds = null;

  function resetMap() {
    if (map && initialBounds) {
      map.fitBounds(initialBounds, {
        padding: [30, 30]
      });
    }
  }

  async function initMap() {
    if (!mapEl || !polyline) return;
    if (typeof window === "undefined") return;

    try {
      // Dynamically import Leaflet only on client side
      const leaflet = await import("leaflet");
      L = leaflet.default || leaflet;

      const coords = decodePolyline(polyline);
      if (coords.length === 0) return;

      // Initialize map with minimal UI but interactive
      map = L.map(mapEl, {
        zoomControl: false,
        attributionControl: false,
      });

      // Add tile layer based on theme
      const darkMode = isDarkMode();
      const tileUrl = getTileUrl(darkMode);

      L.tileLayer(tileUrl, {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        subdomains: "abcd",
        maxZoom: 20,
      }).addTo(map);

      // Create polyline
      const routeLine = L.polyline(coords, {
        color: lineColor,
        weight: lineWeight,
        opacity: 0.8,
        lineJoin: "round",
      }).addTo(map);

      // Store initial bounds and fit map to route bounds with padding
      initialBounds = routeLine.getBounds();
      map.fitBounds(initialBounds, {padding: [30, 30]});

    } catch (err) {
      console.error("Error initializing route map:", err);
    }
  }

  onMount(() => {
    initMap();

    const handleResize = () => {
      if (map) map.invalidateSize();
    };
    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
    };
  });

  onDestroy(() => {
    if (map) {
      map.remove();
      map = null;
    }
  });
</script>

<svelte:head>
  <link
      rel="stylesheet"
      href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
      crossorigin=""
  />
</svelte:head>

{#if polyline}
  <div class="map-container">
    <div class="activity-route-map" bind:this={mapEl} style="height: {height}px;"/>
    <button class="reset-btn" on:click={resetMap} title="Reset to initial view">
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
           stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
        <path d="M3 3v5h5"/>
      </svg>
    </button>
  </div>
{:else}
  <div class="no-map-message">
    <p>No route data available for this activity.</p>
  </div>
{/if}

<style>
  .map-container {
    position: relative;
    width: 100%;
  }

  .activity-route-map {
    width: 100%;
    border-radius: 8px;
  }

  .reset-btn {
    position: absolute;
    top: 10px;
    right: 10px;
    z-index: 1000;
    background: white;
    border: none;
    border-radius: 4px;
    padding: 8px;
    cursor: pointer;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background-color 0.2s;
  }

  .reset-btn:hover {
    background: #f0f0f0;
  }

  .reset-btn svg {
    color: #333;
  }

  :global(.dark) .reset-btn {
    background: #374151;
  }

  :global(.dark) .reset-btn:hover {
    background: #4b5563;
  }

  :global(.dark) .reset-btn svg {
    color: #e5e7eb;
  }

  .no-map-message {
    padding: 2rem;
    text-align: center;
    background: var(--grey-100, #f3f4f6);
    border-radius: 8px;
    color: var(--grey-500, #6b7280);
  }
</style>
