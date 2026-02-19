<script lang="ts">
    import { MAX_MESSAGE_LENGTH } from '@strava-chat/shared/constants';

    interface Props {
        onSend: (content: string) => void;
        onStop?: () => void;
        disabled?: boolean;
        streaming?: boolean;
    }

    let { onSend, onStop, disabled = false, streaming = false }: Props = $props();

    let content = $state('');
    let textarea: HTMLTextAreaElement | undefined = $state();

    const charCount = $derived(content.length);
    const canSend = $derived(content.trim().length > 0 && !disabled && !streaming);

    function handleKeydown(e: KeyboardEvent) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            if (canSend) submit();
        }
    }

    function submit() {
        const text = content.trim();
        if (!text) return;
        content = '';
        onSend(text);
        // Reset textarea height
        if (textarea) textarea.style.height = 'auto';
    }

    function autoResize(e: Event) {
        const el = e.target as HTMLTextAreaElement;
        el.style.height = 'auto';
        el.style.height = `${Math.min(el.scrollHeight, 200)}px`;
    }
</script>

<div class="border-t border-gray-800 bg-gray-950 px-4 py-3">
    <div class="flex items-end gap-2 rounded-xl border border-gray-700 bg-gray-800 px-3 py-2 focus-within:border-blue-500/60 focus-within:ring-1 focus-within:ring-blue-500/20">
        <textarea
            bind:this={textarea}
            bind:value={content}
            onkeydown={handleKeydown}
            oninput={autoResize}
            placeholder="Message Strava Chat…"
            rows="1"
            disabled={disabled && !streaming}
            class="flex-1 resize-none bg-transparent text-sm text-gray-100 placeholder-gray-500 outline-none disabled:opacity-50"
            style="min-height: 24px; max-height: 200px;"
        ></textarea>

        <div class="flex shrink-0 items-center gap-2">
            {#if charCount > MAX_MESSAGE_LENGTH * 0.8}
                <span class="text-xs {charCount > MAX_MESSAGE_LENGTH ? 'text-red-400' : 'text-gray-500'}">
                    {charCount}/{MAX_MESSAGE_LENGTH}
                </span>
            {/if}

            {#if streaming}
                <button
                    onclick={onStop}
                    class="flex h-8 w-8 items-center justify-center rounded-lg bg-red-600 text-white hover:bg-red-500 active:scale-95"
                    aria-label="Stop generating"
                >
                    <svg class="h-3 w-3" fill="currentColor" viewBox="0 0 24 24">
                        <rect x="6" y="6" width="12" height="12" rx="1" />
                    </svg>
                </button>
            {:else}
                <button
                    onclick={submit}
                    disabled={!canSend}
                    class="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-600 text-white transition-colors hover:bg-blue-500 active:scale-95 disabled:cursor-not-allowed disabled:opacity-30"
                    aria-label="Send message"
                >
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <line x1="22" y1="2" x2="11" y2="13" />
                        <polygon points="22 2 15 22 11 13 2 9 22 2" />
                    </svg>
                </button>
            {/if}
        </div>
    </div>
    <p class="mt-1.5 text-center text-[10px] text-gray-700">
        Enter to send · Shift+Enter for newline
    </p>
</div>
