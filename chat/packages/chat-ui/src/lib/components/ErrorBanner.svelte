<script lang="ts">
    interface Props {
        message: string;
        onDismiss?: () => void;
    }

    let { message, onDismiss }: Props = $props();
</script>

<div class="flex items-start gap-3 rounded-lg border border-red-800 bg-red-950/50 px-4 py-3 text-sm text-red-300">
    <svg
        class="mt-0.5 h-4 w-4 shrink-0 text-red-400"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="2"
    >
        <circle cx="12" cy="12" r="10" />
        <line x1="12" y1="8" x2="12" y2="12" />
        <line x1="12" y1="16" x2="12.01" y2="16" />
    </svg>
    <span class="flex-1">{message}</span>
    {#if onDismiss}
        <button
            onclick={onDismiss}
            class="shrink-0 text-red-400 hover:text-red-200"
            aria-label="Dismiss error"
        >
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="6" x2="6" y2="18" />
                <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
        </button>
    {/if}
</div>
