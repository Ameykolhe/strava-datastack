import { DEFAULT_MODEL, DEFAULT_TEMPERATURE } from '@strava-chat/shared/constants';

const SETTINGS_KEY = 'chat_settings';

interface Settings {
    model: string;
    temperature: number;
}

function loadSettings(): Settings {
    if (typeof localStorage === 'undefined') {
        return { model: DEFAULT_MODEL, temperature: DEFAULT_TEMPERATURE };
    }
    try {
        const stored = localStorage.getItem(SETTINGS_KEY);
        if (stored) return JSON.parse(stored) as Settings;
    } catch {
        // ignore
    }
    return { model: DEFAULT_MODEL, temperature: DEFAULT_TEMPERATURE };
}

class SettingsStore {
    model = $state(DEFAULT_MODEL);
    temperature = $state(DEFAULT_TEMPERATURE);
    showPanel = $state(false);

    constructor() {
        const s = loadSettings();
        this.model = s.model;
        this.temperature = s.temperature;
    }

    save(): void {
        if (typeof localStorage !== 'undefined') {
            localStorage.setItem(
                SETTINGS_KEY,
                JSON.stringify({ model: this.model, temperature: this.temperature }),
            );
        }
    }

    togglePanel(): void {
        this.showPanel = !this.showPanel;
    }
}

export const settingsStore = new SettingsStore();
