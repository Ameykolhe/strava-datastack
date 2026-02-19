import type { LoginRequest, LoginResponse } from '@strava-chat/shared/types';
import { API_BASE, ApiError } from './client.js';

const TOKEN_KEY = 'chat_token';

export function getStoredToken(): string | null {
    if (typeof localStorage === 'undefined') return null;
    return localStorage.getItem(TOKEN_KEY);
}

export function storeToken(token: string): void {
    localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken(): void {
    localStorage.removeItem(TOKEN_KEY);
}

export function isTokenValid(token: string): boolean {
    try {
        const parts = token.split('.');
        if (parts.length !== 3) return false;
        const payload = JSON.parse(atob(parts[1]));
        return typeof payload.exp === 'number' && Date.now() < payload.exp * 1000;
    } catch {
        return false;
    }
}

export async function login(password: string): Promise<LoginResponse> {
    const req: LoginRequest = { password };
    const res = await fetch(`${API_BASE}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(req),
    });
    if (!res.ok) {
        const body = await res.json().catch(() => ({ message: 'Login failed' }));
        throw new ApiError(res.status, body.message ?? 'Login failed');
    }
    return res.json() as Promise<LoginResponse>;
}
