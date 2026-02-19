<script lang="ts">
    import { page } from '$app/stores';
    import { onMount, tick } from 'svelte';
    import { conversationsStore } from '$lib/stores/conversations.svelte.js';
    import { messagesStore } from '$lib/stores/messages.svelte.js';
    import { settingsStore } from '$lib/stores/settings.svelte.js';
    import ChatMessage from '$lib/components/ChatMessage.svelte';
    import MessageInput from '$lib/components/MessageInput.svelte';
    import ErrorBanner from '$lib/components/ErrorBanner.svelte';

    let messagesContainer: HTMLDivElement | undefined = $state();
    const conversationId = $derived($page.params.id);

    async function loadConversation(id: string) {
        try {
            const conv = await conversationsStore.getConversation(id);
            messagesStore.loadMessages(conv.messages, id);
            await tick();
            scrollToBottom('instant');
        } catch (err) {
            messagesStore.error = err instanceof Error ? err.message : 'Failed to load conversation';
        }
    }

    $effect(() => {
        if (conversationId) {
            loadConversation(conversationId);
        }
    });

    $effect(() => {
        // Scroll to bottom when new messages arrive or streaming updates
        if (messagesStore.messages.length || messagesStore.streaming) {
            tick().then(() => scrollToBottom('smooth'));
        }
    });

    function scrollToBottom(behavior: ScrollBehavior = 'smooth') {
        if (messagesContainer) {
            messagesContainer.scrollTo({ top: messagesContainer.scrollHeight, behavior });
        }
    }

    async function handleSend(content: string) {
        await messagesStore.send(content, settingsStore.model, settingsStore.temperature);
    }

    const conversationTitle = $derived(
        conversationsStore.list.find((c) => c.id === conversationId)?.title ?? 'Conversation',
    );
</script>

<svelte:head>
    <title>{conversationTitle} — Strava Chat</title>
</svelte:head>

<div class="flex h-full flex-col">
    <!-- Messages area -->
    <div bind:this={messagesContainer} class="flex-1 overflow-y-auto py-4">
        {#if messagesStore.messages.length === 0 && !messagesStore.streaming && !messagesStore.isStreaming}
            <div class="flex h-full items-center justify-center">
                <div class="text-center text-sm text-gray-600">
                    <div class="mb-2 text-3xl">💬</div>
                    Send a message to start chatting
                </div>
            </div>
        {:else}
            {#each messagesStore.messages as msg (msg.id)}
                <ChatMessage message={msg} />
            {/each}

            {#if messagesStore.streaming}
                <ChatMessage streaming={messagesStore.streaming} />
            {/if}
        {/if}
    </div>

    <!-- Error banner -->
    {#if messagesStore.error}
        <div class="px-4 py-2">
            <ErrorBanner
                message={messagesStore.error}
                onDismiss={() => messagesStore.clearError()}
            />
        </div>
    {/if}

    <!-- Input -->
    <MessageInput
        onSend={handleSend}
        onStop={() => messagesStore.stop()}
        streaming={messagesStore.isStreaming}
    />
</div>
