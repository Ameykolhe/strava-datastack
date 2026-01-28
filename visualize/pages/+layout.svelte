<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import CustomLayout from '../components/layout/CustomLayout.svelte';
	import { onMount } from 'svelte';

	export let data;

	// Register service worker for offline caching
	onMount(() => {
		if ('serviceWorker' in navigator) {
			navigator.serviceWorker.register('/sw.js', { scope: '/' })
				.then((registration) => {
					console.log('Service Worker registered:', registration.scope);
				})
				.catch((error) => {
					console.error('Service Worker registration failed:', error);
				});
		}
	});
</script>

<svelte:head>
  <!-- Preconnect to critical CDNs -->
  <link rel="preconnect" href="https://unpkg.com" crossorigin />
  <link rel="dns-prefetch" href="https://unpkg.com" />

  <!-- CartoDB tiles for maps -->
  <link rel="preconnect" href="https://a.basemaps.cartocdn.com" crossorigin />
  <link rel="preconnect" href="https://b.basemaps.cartocdn.com" crossorigin />
  <link rel="preconnect" href="https://c.basemaps.cartocdn.com" crossorigin />
  <link rel="dns-prefetch" href="https://basemaps.cartocdn.com" />

  <!-- Preload critical API endpoints -->
  <link rel="preload" href="/api/pagesManifest.json" as="fetch" crossorigin />

  <!-- Preload critical fonts to prevent FOUT -->
  <link rel="preload" as="style" href="/@evidence-dev/tailwind/fonts.css" />
</svelte:head>

<CustomLayout
	{data}
	title="Strava Datastack"
	logo="/branding/strava-datastack-logo-light.svg"
	lightLogo="/branding/strava-datastack-logo-light.svg"
	darkLogo="/branding/strava-datastack-logo-dark.svg"
	githubRepo="https://github.com/Ameykolhe/strava-datastack"
>
	<slot slot="content" />
</CustomLayout>
