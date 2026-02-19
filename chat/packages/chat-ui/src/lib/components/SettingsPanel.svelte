<script lang="ts">
    import { settingsStore } from '$lib/stores/settings.svelte.js';
    import { authStore } from '$lib/stores/auth.svelte.js';
    import { goto } from '$app/navigation';

    const MODELS = [
        { id: 'claude-sonnet-4-6', label: 'Claude Sonnet 4.6 (Default)' },
        { id: 'claude-opus-4-6', label: 'Claude Opus 4.6' },
        { id: 'claude-haiku-4-5-20251001', label: 'Claude Haiku 4.5' },
    ];

    function handleModelChange(e: Event) {
        settingsStore.model = (e.target as HTMLSelectElement).value;
        settingsStore.save();
    }

    function handleTempChange(e: Event) {
        settingsStore.temperature = parseFloat((e.target as HTMLInputElement).value);
        settingsStore.save();
    }

    function logout() {
        authStore.logout();
        goto('/login');
    }
</script>

<div class="w-72 rounded-xl border border-gray-700 bg-gray-900 p-4 shadow-xl">
    <div class="mb-4 flex items-center justify-between">
        <h2 class="text-sm font-semibold text-gray-200">Settings</h2>
        <button
            onclick={() => settingsStore.togglePanel()}
            class="text-gray-500 hover:text-gray-300"
            aria-label="Close settings"
        >
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="6" x2="6" y2="18" />
                <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
        </button>
    </div>

    <div class="space-y-4">
        <div>
            <label class="mb-1.5 block text-xs font-medium text-gray-400" for="model-select">
                Model
            </label>
            <select
                id="model-select"
                value={settingsStore.model}
                onchange={handleModelChange}
                class="w-full rounded-lg border border-gray-600 bg-gray-800 px-3 py-1.5 text-sm text-gray-200 focus:border-blue-500 focus:outline-none"
            >
                {#each MODELS as m (m.id)}
                    <option value={m.id}>{m.label}</option>
                {/each}
            </select>
        </div>

        <div>
            <div class="mb-1.5 flex items-center justify-between">
                <label class="text-xs font-medium text-gray-400" for="temp-range">
                    Temperature
                </label>
                <span class="text-xs text-gray-500">{settingsStore.temperature.toFixed(1)}</span>
            </div>
            <input
                id="temp-range"
                type="range"
                min="0"
                max="1"
                step="0.1"
                value={settingsStore.temperature}
                oninput={handleTempChange}
                class="w-full accent-blue-500"
            />
            <div class="mt-0.5 flex justify-between text-[10px] text-gray-600">
                <span>Precise</span>
                <span>Creative</span>
            </div>
        </div>

        <div class="border-t border-gray-700 pt-3">
            <button
                onclick={logout}
                class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-gray-400 hover:bg-gray-800 hover:text-red-400"
            >
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" />
                    <polyline points="16 17 21 12 16 7" />
                    <line x1="21" y1="12" x2="9" y2="12" />
                </svg>
                Sign out
            </button>
        </div>
    </div>
</div>
