<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import CustomLayout from '../components/layout/CustomLayout.svelte';
	export let data;
</script>

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
