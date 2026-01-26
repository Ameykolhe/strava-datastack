<!--
  Activity Route Map
  Displays a single activity route on an interactive map.

  @prop {string} polyline - Encoded polyline string for the route
  @prop {number} height - Map height in pixels (default: 400)
  @prop {string} lineColor - Route line color (default: Strava orange #FC4C02)
  @prop {number} lineWeight - Route line thickness (default: 3)
-->
<script>
  import { onMount, onDestroy } from "svelte";
  import { decodePolyline } from "./lib/polyline.js";
  import { isDarkMode, getTileUrl } from "./lib/mapUtils.js";

  // Props
  export let polyline = "";
  export let height = 400;
  export let lineColor = "#FC4C02"; // Strava orange
  export let lineWeight = 3;

  let mapEl;
  let map;
  let L;

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

      // Fit map to route bounds with padding
      map.fitBounds(routeLine.getBounds(), { padding: [30, 30] });

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
  <div class="activity-route-map" bind:this={mapEl} style="height: {height}px;" />
{:else}
  <div class="no-map-message">
    <p>No route data available for this activity.</p>
  </div>
{/if}

<style>
  .activity-route-map {
    width: 100%;
    border-radius: 8px;
  }

  .no-map-message {
    padding: 2rem;
    text-align: center;
    background: var(--grey-100, #f3f4f6);
    border-radius: 8px;
    color: var(--grey-500, #6b7280);
  }
</style>
