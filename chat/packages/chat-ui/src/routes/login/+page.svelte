<script lang="ts">
    import { goto } from '$app/navigation';
    import { login } from '$lib/api/auth.js';
    import { authStore } from '$lib/stores/auth.svelte.js';

    let password = $state('');
    let loading = $state(false);
    let error = $state('');

    async function handleSubmit(e: SubmitEvent) {
        e.preventDefault();
        if (!password.trim()) return;

        loading = true;
        error = '';

        try {
            const res = await login(password);
            authStore.setToken(res.token);
            goto('/chat');
        } catch (err) {
            error = err instanceof Error ? err.message : 'Login failed';
        } finally {
            loading = false;
        }
    }
</script>

<svelte:head>
    <title>Sign in — Strava Chat</title>
</svelte:head>

<div class="flex min-h-screen items-center justify-center bg-gray-950 px-4">
    <div class="w-full max-w-sm">
        <div class="mb-8 text-center">
            <div class="mb-3 inline-flex h-12 w-12 items-center justify-center rounded-full bg-orange-500/10 text-2xl">
                🏃
            </div>
            <h1 class="text-2xl font-bold text-gray-100">Strava Chat</h1>
            <p class="mt-1 text-sm text-gray-500">Chat with your fitness data</p>
        </div>

        <form onsubmit={handleSubmit} class="space-y-4">
            <div>
                <label for="password" class="mb-1.5 block text-sm font-medium text-gray-400">
                    Password
                </label>
                <input
                    id="password"
                    type="password"
                    bind:value={password}
                    placeholder="Enter password"
                    disabled={loading}
                    class="w-full rounded-lg border border-gray-700 bg-gray-800 px-4 py-2.5 text-gray-100 placeholder-gray-600 outline-none transition focus:border-blue-500/60 focus:ring-1 focus:ring-blue-500/20 disabled:opacity-50"
                    autocomplete="current-password"
                />
            </div>

            {#if error}
                <div class="rounded-lg bg-red-950/60 border border-red-800 px-3 py-2 text-sm text-red-400">
                    {error}
                </div>
            {/if}

            <button
                type="submit"
                disabled={loading || !password.trim()}
                class="w-full rounded-lg bg-blue-600 py-2.5 text-sm font-medium text-white transition hover:bg-blue-500 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-40"
            >
                {#if loading}
                    <span class="inline-flex items-center gap-2">
                        <svg class="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                        </svg>
                        Signing in…
                    </span>
                {:else}
                    Sign in
                {/if}
            </button>
        </form>
    </div>
</div>
