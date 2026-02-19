<script lang="ts">
    import type { ActiveToolCall } from '$lib/stores/messages.svelte.js';

    interface Props {
        tool: ActiveToolCall;
    }

    let { tool }: Props = $props();
    let expanded = $state(false);

    const toolIcons: Record<string, string> = {
        query_kpis: '📊',
        list_activities: '🏃',
        get_activity_detail: '🔍',
        summarize_period: '📅',
        get_streaks: '🔥',
        get_activity_zones: '❤️',
        get_segment_efforts: '⚡',
    };

    const icon = $derived(toolIcons[tool.toolName] ?? '🛠️');
</script>

<div class="my-2 rounded-lg border border-gray-700 bg-gray-800/60 text-xs">
    <button
        onclick={() => (expanded = !expanded)}
        class="flex w-full items-center gap-2 px-3 py-2 text-left hover:bg-gray-700/40"
    >
        <span class="text-sm">{icon}</span>
        <span class="font-medium text-gray-300">{tool.toolName}</span>
        {#if tool.status === 'pending'}
            <span class="ml-auto flex items-center gap-1 text-blue-400">
                <svg class="h-3 w-3 animate-spin" viewBox="0 0 24 24" fill="none">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                    <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                    />
                </svg>
                running
            </span>
        {:else if tool.status === 'done'}
            <span class="ml-auto text-green-400">
                {tool.durationMs != null ? `${tool.durationMs}ms` : 'done'}
            </span>
        {:else}
            <span class="ml-auto text-red-400">error</span>
        {/if}
        <svg
            class="h-3 w-3 text-gray-500 transition-transform {expanded ? 'rotate-180' : ''}"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
        >
            <polyline points="6 9 12 15 18 9" />
        </svg>
    </button>

    {#if expanded}
        <div class="border-t border-gray-700 px-3 py-2 space-y-2">
            <div>
                <div class="mb-1 font-semibold text-gray-500 uppercase tracking-wide text-[10px]">Input</div>
                <pre class="overflow-x-auto rounded bg-gray-900 p-2 text-gray-300">{JSON.stringify(tool.input, null, 2)}</pre>
            </div>
            {#if tool.output != null}
                <div>
                    <div class="mb-1 font-semibold text-gray-500 uppercase tracking-wide text-[10px]">Output</div>
                    <pre class="overflow-x-auto rounded bg-gray-900 p-2 text-gray-300">{JSON.stringify(tool.output, null, 2)}</pre>
                </div>
            {/if}
        </div>
    {/if}
</div>
