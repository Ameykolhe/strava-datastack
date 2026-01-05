<script>
    import { onMount, onDestroy } from 'svelte';
    import { browser } from '$app/environment';
    import * as L from 'leaflet';
    import 'leaflet/dist/leaflet.css';

    export let data = [];
    export let height = 600;
    export let title = "Route Map";

    let mapContainer;
    let map;
    let polyline;
    let mounted = false;

    onMount(() => {
        if (!browser || !data || data.length === 0) {
            console.log('Browser check or data check failed', { browser, dataLength: data?.length });
            return;
        }

        mounted = true;

        // Small delay to ensure DOM is ready
        setTimeout(() => {
            try {
                console.log('Initializing map with', data.length, 'points');

                // Initialize the map centered on the first point
                const center = [data[0].latitude, data[0].longitude];
                map = L.map(mapContainer).setView(center, 13);

                // Add OpenStreetMap tiles
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                    maxZoom: 19
                }).addTo(map);

                // Create coordinates array for the polyline
                const coordinates = data.map(point => [point.latitude, point.longitude]);

                // Add the polyline
                polyline = L.polyline(coordinates, {
                    color: '#2563eb',
                    weight: 3,
                    opacity: 0.8,
                    smoothFactor: 1
                }).addTo(map);

                // Add start marker (green)
                L.circleMarker(coordinates[0], {
                    radius: 8,
                    fillColor: '#22c55e',
                    color: '#fff',
                    weight: 2,
                    opacity: 1,
                    fillOpacity: 1
                }).addTo(map).bindPopup('Start');

                // Add end marker (red)
                L.circleMarker(coordinates[coordinates.length - 1], {
                    radius: 8,
                    fillColor: '#ef4444',
                    color: '#fff',
                    weight: 2,
                    opacity: 1,
                    fillOpacity: 1
                }).addTo(map).bindPopup('End');

                // Fit map to polyline bounds
                map.fitBounds(polyline.getBounds(), { padding: [50, 50] });

                console.log('Map initialized successfully');
            } catch (err) {
                console.error('Error loading map:', err);
            }
        }, 100);
    });

    onDestroy(() => {
        if (map) {
            map.remove();
        }
    });
</script>

<div class="route-map-container">
    {#if title}
        <h3 class="map-title">{title}</h3>
    {/if}

    {#if !browser}
        <div class="loading-state" style="height: {height}px;">
            Server rendering...
        </div>
    {:else if !data || data.length === 0}
        <div class="error-state" style="height: {height}px;">
            No route data available
        </div>
    {:else if !mounted}
        <div class="loading-state" style="height: {height}px;">
            Loading map...
        </div>
    {:else}
        <div
            bind:this={mapContainer}
            class="map"
            style="height: {height}px; width: 100%; border-radius: 8px;"
        ></div>
        <p class="map-info">
            Showing route with {data.length.toLocaleString()} GPS points
        </p>
    {/if}
</div>

<style>
    .route-map-container {
        margin: 1rem 0;
    }

    .map-title {
        margin-bottom: 0.5rem;
        font-size: 1.125rem;
        font-weight: 600;
    }

    .map {
        box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
    }

    .map-info {
        margin-top: 0.5rem;
        font-size: 0.875rem;
        color: #6b7280;
    }

    .loading-state,
    .error-state {
        display: flex;
        align-items: center;
        justify-content: center;
        background: #f3f4f6;
        border-radius: 8px;
        color: #6b7280;
    }

    .error-state {
        color: #dc2626;
    }
</style>
