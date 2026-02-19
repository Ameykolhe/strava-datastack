import { getStoredToken, storeToken, clearToken, isTokenValid } from '$lib/api/auth.js';

class AuthStore {
    token = $state<string | null>(null);

    constructor() {
        // Hydrate from localStorage on first access (client-side only)
        if (typeof localStorage !== 'undefined') {
            const stored = getStoredToken();
            if (stored && isTokenValid(stored)) {
                this.token = stored;
            }
        }
    }

    get isAuthenticated(): boolean {
        return this.token !== null && isTokenValid(this.token);
    }

    setToken(token: string): void {
        storeToken(token);
        this.token = token;
    }

    logout(): void {
        clearToken();
        this.token = null;
    }
}

export const authStore = new AuthStore();
