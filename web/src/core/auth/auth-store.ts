import { create } from 'zustand';
import { loginWithPassword, logoutSession } from './mock-api';
import type { SessionResponse, SessionTenant } from './types';

type AuthStatus = 'idle' | 'loading' | 'authenticated' | 'anonymous';

type AuthState = {
  status: AuthStatus;
  session: SessionResponse | null;
  error: string | null;
  hydrate: () => void;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  switchTenant: (tenantId: string) => void;
  hasRole: (roleCode: string) => boolean;
};

const STORAGE_KEY = 'pix2pi.phase1.session';

function persistSession(session: SessionResponse | null): void {
  if (!session) {
    window.localStorage.removeItem(STORAGE_KEY);
    return;
  }

  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
}

function readPersistedSession(): SessionResponse | null {
  const raw = window.localStorage.getItem(STORAGE_KEY);
  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as SessionResponse;
  } catch {
    return null;
  }
}

function replaceActiveTenant(session: SessionResponse, tenant: SessionTenant): SessionResponse {
  return {
    ...session,
    activeTenant: tenant,
  };
}

export const useAuthStore = create<AuthState>((set, get) => ({
  status: 'idle',
  session: null,
  error: null,
  hydrate: () => {
    const session = readPersistedSession();
    set({
      status: session ? 'authenticated' : 'anonymous',
      session,
      error: null,
    });
  },
  login: async (email, password) => {
    set({ status: 'loading', error: null });
    try {
      const session = await loginWithPassword(email, password);
      persistSession(session);
      set({ status: 'authenticated', session, error: null });
    } catch (error) {
      set({ status: 'anonymous', error: error instanceof Error ? error.message : 'Beklenmeyen hata' });
    }
  },
  logout: async () => {
    await logoutSession();
    persistSession(null);
    set({ status: 'anonymous', session: null, error: null });
  },
  switchTenant: (tenantId) => {
    const current = get().session;
    if (!current) {
      return;
    }

    const nextTenant = current.tenants.find((tenant) => tenant.id === tenantId);
    if (!nextTenant) {
      return;
    }

    const nextSession = replaceActiveTenant(current, nextTenant);
    persistSession(nextSession);
    set({ session: nextSession });
  },
  hasRole: (roleCode) => {
    const current = get().session;
    return !!current?.roles.some((role) => role.code === roleCode);
  },
}));

