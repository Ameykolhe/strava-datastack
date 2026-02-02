<!--
  Sidebar With Toggle
  Custom sidebar wrapper with slots for Strava badge and distance unit toggle.
  Provides proper mobile scrolling with custom content at bottom of sidebar.
-->
<script>
  import CustomSidebar from './CustomSidebar.svelte';
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

<CustomSidebar
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
  <div slot="mobile-bottom" class="space-y-4 text-center">
    <StravaBadge athleteId="2398447"/>
    <DistanceUnitToggle/>
  </div>
  <div slot="desktop-bottom" class="space-y-4 text-center">
    <StravaBadge athleteId="2398447"/>
    <DistanceUnitToggle/>
  </div>
</CustomSidebar>
