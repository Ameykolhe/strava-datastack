<script>
  import { onMount, onDestroy } from "svelte";

  // Props
  export let polyline = "";
  export let height = 400;
  export let lineColor = "#FC4C02"; // Strava orange
  export let lineWeight = 3;

  let mapEl;
  let map;
  let routeLine;
  let L;

  // Decode Google polyline to array of [lat, lng] pairs
  function decodePolyline(encoded) {
    if (!encoded) return [];

    const poly = [];
    let index = 0,
      lat = 0,
      lng = 0;

    while (index < encoded.length) {
      let shift = 0,
        result = 0,
        byte;

      do {
        byte = encoded.charCodeAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lat += result & 1 ? ~(result >> 1) : result >> 1;

      shift = 0;
      result = 0;

      do {
        byte = encoded.charCodeAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lng += result & 1 ? ~(result >> 1) : result >> 1;

      poly.push([lat / 1e5, lng / 1e5]);
    }

    return poly;
  }

  function isDarkMode() {
    if (typeof window === "undefined") return false;
    // Check for Evidence dark mode class or system preference
    return (
      document.documentElement.classList.contains("dark") ||
      document.body.classList.contains("dark") ||
      window.matchMedia("(prefers-color-scheme: dark)").matches
    );
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
      const tileUrl = darkMode
        ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        : "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";

      L.tileLayer(tileUrl, {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        subdomains: "abcd",
        maxZoom: 20,
      }).addTo(map);

      // Create polyline
      routeLine = L.polyline(coords, {
        color: lineColor,
        weight: lineWeight,
        opacity: 0.8,
        lineJoin: "round",
      }).addTo(map);

      // Fit map to route bounds with padding
      map.fitBounds(routeLine.getBounds(), { padding: [30, 30] });

    } catch (err) {
      console.error("Error initializing map:", err);
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