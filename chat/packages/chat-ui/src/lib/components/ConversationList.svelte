<script lang="ts">
    import { goto } from '$app/navigation';
    import { conversationsStore } from '$lib/stores/conversations.svelte.js';

    interface Props {
        activeId?: string;
        onNewChat: () => void;
    }

    let { activeId, onNewChat }: Props = $props();

    let renamingId = $state<string | null>(null);
    let renameValue = $state('');

    async function startRename(id: string, currentTitle: string) {
        renamingId = id;
        renameValue = currentTitle;
    }

    async function commitRename(id: string) {
        if (renameValue.trim()) {
            await conversationsStore.rename(id, renameValue.trim());
        }
        renamingId = null;
    }

    async function handleDelete(id: string) {
        if (!confirm('Delete this conversation?')) return;
        await conversationsStore.remove(id);
        if (activeId === id) goto('/chat');
    }

    function formatDate(iso: string): string {
        const d = new Date(iso);
        const now = new Date();
        const diffMs = now.getTime() - d.getTime();
        const diffDays = Math.floor(diffMs / 86400000);
        if (diffDays === 0) return 'Today';
        if (diffDays === 1) return 'Yesterday';
        if (diffDays < 7) return `${diffDays}d ago`;
        return d.toLocaleDateString([], { month: 'short', day: 'numeric' });
    }
</script>

<div class="flex h-full flex-col">
    <div class="flex items-center justify-between px-3 py-3">
        <span class="text-xs font-semibold uppercase tracking-wider text-gray-500">Conversations</span>
        <button
            onclick={onNewChat}
            class="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 hover:bg-gray-700 hover:text-gray-200"
            aria-label="New conversation"
        >
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <line x1="12" y1="5" x2="12" y2="19" />
                <line x1="5" y1="12" x2="19" y2="12" />
            </svg>
        </button>
    </div>

    <div class="flex-1 overflow-y-auto">
        {#if conversationsStore.loading && conversationsStore.list.length === 0}
            <div class="space-y-1 px-2">
                {#each Array(4) as _, i (i)}
                    <div class="h-12 animate-pulse rounded-lg bg-gray-800/60"></div>
                {/each}
            </div>
        {:else if conversationsStore.list.length === 0}
            <div class="px-3 py-6 text-center text-sm text-gray-600">
                No conversations yet.<br />Start a new chat above.
            </div>
        {:else}
            <ul class="space-y-0.5 px-2 pb-2">
                {#each conversationsStore.list as conv (conv.id)}
                    <li>
                        <div
                            class="group relative flex cursor-pointer flex-col rounded-lg px-3 py-2 text-sm transition-colors
                                {activeId === conv.id
                                    ? 'bg-gray-700 text-gray-100'
                                    : 'text-gray-400 hover:bg-gray-800 hover:text-gray-200'}"
                        >
                            <button
                                onclick={() => goto(`/chat/${conv.id}`)}
                                class="flex-1 text-left"
                            >
                                {#if renamingId === conv.id}
                                    <!-- svelte-ignore a11y_autofocus -->
                                    <input
                                        bind:value={renameValue}
                                        onblur={() => commitRename(conv.id)}
                                        onkeydown={(e) => {
                                            if (e.key === 'Enter') commitRename(conv.id);
                                            if (e.key === 'Escape') (renamingId = null);
                                        }}
                                        onclick={(e) => e.stopPropagation()}
                                        class="w-full rounded bg-gray-600 px-1 text-sm text-gray-100 outline-none"
                                        autofocus
                                    />
                                {:else}
                                    <div class="truncate font-medium">{conv.title}</div>
                                {/if}
                                <div class="mt-0.5 flex items-center gap-1 text-[10px] text-gray-600">
                                    <span>{formatDate(conv.updated_at)}</span>
                                    {#if conv.message_count > 0}
                                        <span>·</span>
                                        <span>{conv.message_count} msgs</span>
                                    {/if}
                                </div>
                            </button>

                            <!-- Action buttons (visible on hover) -->
                            <div class="absolute right-2 top-2 hidden items-center gap-0.5 group-hover:flex">
                                <button
                                    onclick={(e) => {
                                        e.stopPropagation();
                                        startRename(conv.id, conv.title);
                                    }}
                                    class="flex h-5 w-5 items-center justify-center rounded text-gray-500 hover:bg-gray-600 hover:text-gray-300"
                                    aria-label="Rename"
                                >
                                    <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7" />
                                        <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z" />
                                    </svg>
                                </button>
                                <button
                                    onclick={(e) => {
                                        e.stopPropagation();
                                        handleDelete(conv.id);
                                    }}
                                    class="flex h-5 w-5 items-center justify-center rounded text-gray-500 hover:bg-red-900/60 hover:text-red-400"
                                    aria-label="Delete"
                                >
                                    <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                        <polyline points="3 6 5 6 21 6" />
                                        <path d="M19 6l-1 14H6L5 6" />
                                        <path d="M10 11v6M14 11v6" />
                                    </svg>
                                </button>
                            </div>
                        </div>
                    </li>
                {/each}
            </ul>
        {/if}
    </div>
</div>
