<script>
  import {addBasePath} from '@evidence-dev/sdk/utils/svelte';

  /** @type {string | undefined} */
  export let logo;

  /** @type {string | undefined} */
  export let lightLogo;

  /** @type {string | undefined} */
  export let darkLogo;

  export let title;
</script>

{#if title}
  {title}
{:else if logo || lightLogo}
  <img
      src={logo ?? lightLogo}
      alt="Home"
      class="h-5 aspect-auto block dark:hidden"
      href={addBasePath('/')}
  />
{/if}

{#if darkLogo}
  <img
      src={darkLogo}
      alt="Home"
      class="h-5 aspect-auto hidden dark:block"
      href={addBasePath('/')}
  />
{/if}
