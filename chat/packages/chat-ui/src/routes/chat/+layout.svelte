<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import { conversationsStore } from '$lib/stores/conversations.svelte.js';
    import { settingsStore } from '$lib/stores/settings.svelte.js';
    import { authStore } from '$lib/stores/auth.svelte.js';
    import ConversationList from '$lib/components/ConversationList.svelte';
    import SettingsPanel from '$lib/components/SettingsPanel.svelte';
    import { page } from '$app/stores';

    let { children } = $props();
    let sidebarOpen = $state(true);

    const activeId = $derived($page.params.id);

    onMount(async () => {
        if (!authStore.isAuthenticated) {
            goto('/login');
            return;
        }
        await conversationsStore.load();
    });

    async function handleNewChat() {
        const id = await conversationsStore.create();
        goto(`/chat/${id}`);
    }

    async function handleExport() {
        const id = $page.params.id;
        if (!id) return;
        const token = typeof localStorage !== 'undefined' ? localStorage.getItem('chat_token') : null;
        const { API_BASE } = await import('$lib/api/client.js');
        const res = await fetch(
            `${API_BASE}/api/chat/conversations/${id}/export?format=markdown`,
            { headers: token ? { Authorization: `Bearer ${token}` } : {} },
        );
        if (!res.ok) return;
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `conversation-${id}.md`;
        a.click();
        URL.revokeObjectURL(url);
    }
</script>

<div class="flex h-screen overflow-hidden bg-gray-950 text-gray-100">
    <!-- Sidebar -->
    <aside
        class="flex flex-col bg-gray-900 transition-all duration-200 {sidebarOpen
            ? 'w-64 min-w-64'
            : 'w-0 min-w-0 overflow-hidden'}"
    >
        <div class="flex h-14 shrink-0 items-center gap-2 border-b border-gray-800 px-3">
            <span class="text-lg">🏃</span>
            <span class="text-sm font-semibold text-gray-200">Strava Chat</span>
        </div>

        <div class="flex-1 overflow-hidden">
            <ConversationList {activeId} onNewChat={handleNewChat} />
        </div>
    </aside>

    <!-- Main area -->
    <div class="flex flex-1 flex-col overflow-hidden">
        <!-- Header bar -->
        <header class="flex h-14 shrink-0 items-center gap-2 border-b border-gray-800 px-3">
            <button
                onclick={() => (sidebarOpen = !sidebarOpen)}
                class="flex h-8 w-8 items-center justify-center rounded-md text-gray-500 hover:bg-gray-800 hover:text-gray-300"
                aria-label="Toggle sidebar"
            >
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <line x1="3" y1="6" x2="21" y2="6" />
                    <line x1="3" y1="12" x2="21" y2="12" />
                    <line x1="3" y1="18" x2="21" y2="18" />
                </svg>
            </button>

            <div class="flex-1"></div>

            {#if $page.params.id}
                <button
                    onclick={handleExport}
                    class="flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-xs text-gray-500 hover:bg-gray-800 hover:text-gray-300"
                    title="Export as Markdown"
                >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4" />
                        <polyline points="7 10 12 15 17 10" />
                        <line x1="12" y1="15" x2="12" y2="3" />
                    </svg>
                    Export
                </button>
            {/if}

            <!-- Settings button -->
            <div class="relative">
                <button
                    onclick={() => settingsStore.togglePanel()}
                    class="flex h-8 w-8 items-center justify-center rounded-md text-gray-500 hover:bg-gray-800 hover:text-gray-300"
                    aria-label="Settings"
                >
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="3" />
                        <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z" />
                    </svg>
                </button>

                {#if settingsStore.showPanel}
                    <div class="absolute right-0 top-10 z-50">
                        <SettingsPanel />
                    </div>
                {/if}
            </div>
        </header>

        <!-- Page content -->
        <div class="flex-1 overflow-hidden">
            {@render children()}
        </div>
    </div>
</div>
