<script lang="ts">
    import '../app.css';
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import { page } from '$app/stores';
    import { authStore } from '$lib/stores/auth.svelte.js';

    let { children } = $props();

    onMount(() => {
        const isLoginPage = $page.url.pathname.startsWith('/login');
        if (!authStore.isAuthenticated && !isLoginPage) {
            goto('/login');
        }
    });
</script>

{@render children()}
