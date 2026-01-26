<!--
  Sidebar With Toggle
  Evidence sidebar wrapper that includes a Strava badge and distance unit toggle.
  Shows the toggle in a fixed position on desktop and in mobile overlay.
-->
<script>
	import { Sidebar } from '@evidence-dev/core-components';
	import DistanceUnitToggle from './DistanceUnitToggle.svelte';
	import StravaBadge from './StravaBadge.svelte';

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

<div class="relative">
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
	/>
	<div class="fixed bottom-4 w-48 pr-2 hidden md:block">
		<div class="sidebar-strava">
			<StravaBadge athleteId="2398447" />
		</div>
		<DistanceUnitToggle />
	</div>
	{#if mobileSidebarOpen}
		<div class="fixed inset-0 z-[60] pointer-events-none">
			<div
				class="absolute left-0 bottom-0 w-full sm:w-72 px-8 pb-4 pt-3 bg-base-100 border-t border-base-200 pointer-events-auto"
			>
				<div class="sidebar-strava">
					<StravaBadge athleteId="2398447" />
				</div>
				<DistanceUnitToggle />
			</div>
		</div>
	{/if}
</div>

<style>
	:global(aside.w-48 > div.fixed.w-48.bottom-8) {
		bottom: 0;
		padding-bottom: 3.5rem;
	}
	:global(.sidebar-strava) {
		display: flex;
		justify-content: center;
		width: 100%;
		text-align: center;
	}
	:global(.sidebar-strava .strava-badge-container) {
		justify-content: center;
		padding: 0.9rem 0 0.9rem 0;
		margin-top: 0.5rem;
		margin-bottom: 0.5rem;
		width: 100%;
	}
	:global(.sidebar-strava .strava-badge) {
		margin: 0 auto;
	}
</style>
