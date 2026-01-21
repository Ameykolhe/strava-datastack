<script>
  import { onMount, onDestroy } from "svelte";

  // Props
  export let polylines = [];
  export let height = 500;

  let mapEl;
  let map;
  let L;
  let initialBounds = null;

  function resetMap() {
    if (map && initialBounds) {
      map.fitBounds(initialBounds, {
        padding: [40, 40],
        maxZoom: 14
      });
    }
  }

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
    return (
      document.documentElement.classList.contains("dark") ||
      document.body.classList.contains("dark") ||
      window.matchMedia("(prefers-color-scheme: dark)").matches
    );
  }

  async function initMap() {
    if (!mapEl) return;
    if (typeof window === "undefined") return;

    // Parse polylines - handle string, array, or JSON string
    let polylinesArray = [];
    if (typeof polylines === "string") {
      try {
        polylinesArray = JSON.parse(polylines);
      } catch {
        polylinesArray = [polylines];
      }
    } else if (Array.isArray(polylines)) {
      polylinesArray = polylines;
    }

    if (!polylinesArray || polylinesArray.length === 0) {
      return;
    }

    try {
      // Dynamically import Leaflet
      const leaflet = await import("leaflet");
      L = leaflet.default || leaflet;

      // Initialize map
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
        subdomains: "abcd",
        maxZoom: 20,
      }).addTo(map);

      // Decode all routes and calculate each activity's centroid
      const activities = [];
      for (const polyline of polylinesArray) {
        if (polyline && typeof polyline === "string") {
          const coords = decodePolyline(polyline);
          if (coords.length > 0) {
            // Calculate this activity's centroid
            const activityCentroid = coords.reduce(
              (acc, coord) => {
                acc.lat += coord[0];
                acc.lng += coord[1];
                return acc;
              },
              { lat: 0, lng: 0 }
            );
            activityCentroid.lat /= coords.length;
            activityCentroid.lng /= coords.length;

            activities.push({ coords, centroid: activityCentroid });
          }
        }
      }

      if (activities.length === 0) return;

      // Find the densest cluster by counting nearby activities for each activity
      // This finds the "density leader" - the activity with most neighbors
      const neighborCounts = activities.map((activity, i) => {
        let count = 0;
        for (let j = 0; j < activities.length; j++) {
          if (i === j) continue;
          const latDiff = activity.centroid.lat - activities[j].centroid.lat;
          const lngDiff = activity.centroid.lng - activities[j].centroid.lng;
          const dist = Math.sqrt(latDiff * latDiff + lngDiff * lngDiff);
          // ~0.15 degrees is roughly 10 miles - activities within this are "neighbors"
          if (dist < 0.15) count++;
        }
        return count;
      });

      // Find the activity with most neighbors (density center)
      const maxNeighbors = Math.max(...neighborCounts);
      const densityCenterIndex = neighborCounts.indexOf(maxNeighbors);
      const densityCenter = activities[densityCenterIndex].centroid;

      // Calculate distance of each activity from density center
      const activityDistances = activities.map((activity) => {
        const latDiff = activity.centroid.lat - densityCenter.lat;
        const lngDiff = activity.centroid.lng - densityCenter.lng;
        return Math.sqrt(latDiff * latDiff + lngDiff * lngDiff);
      });

      // Use a fixed distance threshold (~25 miles / 0.4 degrees) from density center
      // This captures the local area without pulling in distant outliers
      const distanceThreshold = 0.4;

      // Separate core activities (within threshold) from outliers
      const coreActivities = activities.filter((_, i) => activityDistances[i] <= distanceThreshold);
      const outlierActivities = activities.filter((_, i) => activityDistances[i] > distanceThreshold);

      // Draw all routes - core activities in orange, outliers in lighter color
      for (const activity of coreActivities) {
        L.polyline(activity.coords, {
          color: "#FC4C02",
          weight: 2,
          opacity: 0.4,
          lineJoin: "round",
        }).addTo(map);
      }

      for (const activity of outlierActivities) {
        L.polyline(activity.coords, {
          color: "#FC4C02",
          weight: 1.5,
          opacity: 0.15,
          lineJoin: "round",
        }).addTo(map);
      }

      // Calculate bounds from core activities only
      if (coreActivities.length > 0) {
        const coreCoords = coreActivities.flatMap((a) => a.coords);
        initialBounds = L.latLngBounds(coreCoords);

        map.fitBounds(initialBounds, {
          padding: [40, 40],
          maxZoom: 14
        });
      } else {
        // Fallback to all activities if no core
        const allCoords = activities.flatMap((a) => a.coords);
        initialBounds = L.latLngBounds(allCoords);
        map.fitBounds(initialBounds, {
          padding: [40, 40],
          maxZoom: 14
        });
      }

    } catch (err) {
      console.error("Error initializing heatmap:", err);
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

{#if polylines && polylines.length > 0}
  <div class="heatmap-container">
    <div class="activity-heatmap" bind:this={mapEl} style="height: {height}px;" />
    <button class="reset-btn" on:click={resetMap} title="Reset to initial view">
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
        <path d="M3 3v5h5"/>
      </svg>
    </button>
  </div>
{:else}
  <div class="no-map-message">
    <p>No route data available.</p>
  </div>
{/if}

<style>
  .heatmap-container {
    position: relative;
    width: 100%;
  }

  .activity-heatmap {
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