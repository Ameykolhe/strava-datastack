<script lang="ts">
    import { goto } from '$app/navigation';
    import { conversationsStore } from '$lib/stores/conversations.svelte.js';

    let creating = $state(false);

    async function startNewChat() {
        creating = true;
        try {
            const id = await conversationsStore.create();
            goto(`/chat/${id}`);
        } finally {
            creating = false;
        }
    }
</script>

<svelte:head>
    <title>Strava Chat</title>
</svelte:head>

<div class="flex h-full flex-col items-center justify-center gap-6 px-4 text-center">
    <div>
        <div class="mb-3 text-5xl">🏃</div>
        <h2 class="text-xl font-semibold text-gray-200">Chat with your Strava data</h2>
        <p class="mt-2 max-w-sm text-sm text-gray-500">
            Ask questions about your activities, stats, and trends. Claude will query your data in real time.
        </p>
    </div>

    <div class="grid max-w-md gap-2 text-left">
        {#each [
            'How did my running go this week?',
            'What was my longest ride this year?',
            'Show me my current streak',
            'Compare my January vs February activity',
        ] as prompt}
            <button
                onclick={startNewChat}
                class="rounded-xl border border-gray-800 bg-gray-900 px-4 py-3 text-sm text-gray-400 transition hover:border-gray-700 hover:bg-gray-800 hover:text-gray-200 text-left"
            >
                "{prompt}"
            </button>
        {/each}
    </div>

    <button
        onclick={startNewChat}
        disabled={creating}
        class="flex items-center gap-2 rounded-xl bg-blue-600 px-5 py-2.5 text-sm font-medium text-white transition hover:bg-blue-500 active:scale-95 disabled:opacity-50"
    >
        {#if creating}
            <svg class="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
            Starting…
        {:else}
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <line x1="12" y1="5" x2="12" y2="19" />
                <line x1="5" y1="12" x2="19" y2="12" />
            </svg>
            New conversation
        {/if}
    </button>
</div>
