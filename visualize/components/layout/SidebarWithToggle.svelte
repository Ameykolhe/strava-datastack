<!--
  Sidebar With Toggle
  Evidence sidebar wrapper that includes a Strava badge and distance unit toggle.
  Uses Evidence.dev default styling for proper mobile scrolling.
-->
<script>
	import { Sidebar } from '@evidence-dev/core-components';
	import DistanceUnitToggle from '../shared/DistanceUnitToggle.svelte';
	import StravaBadge from '../shared/StravaBadge.svelte';

	export let fileTree = undefined;
	export let title = undefined;
	export let logo = undefined;
	export let homePageName = undefined;
	export let builtWithEvidence = undefined;
	export let hideHeader = false;
	export let sidebarFrontMatter = undefined;
	export let sidebarDepth = 3;

	export let mobileSidebarOpen = false;
</script>

<Sidebar
	{fileTree}
	bind:mobileSidebarOpen
	{title}
	{logo}
	{homePageName}
	{builtWithEvidence}
	{hideHeader}
	{sidebarFrontMatter}
	{sidebarDepth}
>
	<div slot="below-nav" class="px-4 py-4 space-y-4">
		<StravaBadge athleteId="2398447" />
		<DistanceUnitToggle />
	</div>
</Sidebar>
