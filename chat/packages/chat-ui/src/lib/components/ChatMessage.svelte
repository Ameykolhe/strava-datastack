<script lang="ts">
    import { marked } from 'marked';
    import type { Message } from '@strava-chat/shared/types';
    import type { StreamingMessage } from '$lib/stores/messages.svelte.js';
    import ToolCallCard from './ToolCallCard.svelte';

    interface Props {
        message?: Message;
        streaming?: StreamingMessage;
    }

    let { message, streaming }: Props = $props();

    const isUser = $derived(
        message ? message.role === 'user' : false,
    );

    const displayContent = $derived(
        streaming
            ? streaming.partialText
            : (message?.content ?? ''),
    );

    const htmlContent = $derived(() => {
        if (!displayContent) return '';
        try {
            return marked.parse(displayContent) as string;
        } catch {
            return displayContent;
        }
    });

    function formatTime(iso: string): string {
        return new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
</script>

<div class="flex {isUser ? 'justify-end' : 'justify-start'} px-4 py-2">
    <div class="max-w-[85%] {isUser ? 'max-w-[70%]' : 'w-full max-w-[85%]'}">
        {#if !isUser}
            <!-- Tool calls above message text -->
            {#if streaming?.toolCalls.length}
                {#each streaming.toolCalls as tool (tool.id)}
                    <ToolCallCard {tool} />
                {/each}
            {:else if message?.tool_calls.length}
                {#each message.tool_calls as tc (tc.id)}
                    <ToolCallCard
                        tool={{
                            id: tc.id,
                            toolName: tc.tool_name,
                            input: tc.input,
                            output: tc.output ?? undefined,
                            durationMs: tc.duration_ms ?? undefined,
                            status: 'done',
                        }}
                    />
                {/each}
            {/if}
        {/if}

        {#if displayContent || (streaming && streaming.partialText === '' && !streaming.toolCalls.length)}
            <div
                class="{isUser
                    ? 'rounded-2xl rounded-tr-sm bg-blue-600 px-4 py-2.5 text-white'
                    : 'prose prose-invert prose-sm max-w-none rounded-2xl rounded-tl-sm bg-gray-800 px-4 py-3 text-gray-100'}"
            >
                {#if isUser}
                    <p class="whitespace-pre-wrap text-sm">{displayContent}</p>
                {:else}
                    {@html htmlContent()}
                    {#if streaming && !streaming.partialText}
                        <!-- Thinking indicator -->
                        <span class="inline-flex items-center gap-1 text-gray-400">
                            <span class="animate-bounce text-lg leading-none" style="animation-delay:0ms">·</span>
                            <span class="animate-bounce text-lg leading-none" style="animation-delay:150ms">·</span>
                            <span class="animate-bounce text-lg leading-none" style="animation-delay:300ms">·</span>
                        </span>
                    {/if}
                {/if}
            </div>
        {:else if streaming && !displayContent}
            <!-- Waiting for first token -->
            <div class="rounded-2xl rounded-tl-sm bg-gray-800 px-4 py-3">
                <span class="inline-flex items-center gap-1 text-gray-400">
                    <span class="animate-bounce text-lg leading-none" style="animation-delay:0ms">·</span>
                    <span class="animate-bounce text-lg leading-none" style="animation-delay:150ms">·</span>
                    <span class="animate-bounce text-lg leading-none" style="animation-delay:300ms">·</span>
                </span>
            </div>
        {/if}

        {#if message}
            <div class="mt-1 px-1 text-[10px] text-gray-600 {isUser ? 'text-right' : 'text-left'}">
                {formatTime(message.created_at)}
                {#if !isUser && message.tokens_used}
                    · {message.tokens_used.output} tokens
                {/if}
            </div>
        {/if}
    </div>
</div>
