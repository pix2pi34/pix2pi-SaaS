import { beforeEach, describe, expect, it } from 'vitest';
import { useAuthStore } from '../core/auth/auth-store';

beforeEach(() => {
  window.localStorage.clear();
  useAuthStore.setState({ status: 'idle', session: null, error: null });
});

describe('auth-store', () => {
  it('hydrates anonymous state when local storage is empty', () => {
    useAuthStore.getState().hydrate();
    expect(useAuthStore.getState().status).toBe('anonymous');
  });

  it('logs in with valid demo credentials', async () => {
    await useAuthStore.getState().login('demo@pix2pi.local', '123456');
    expect(useAuthStore.getState().status).toBe('authenticated');
    expect(useAuthStore.getState().session?.activeTenant.slug).toBe('merkez-tenant');
  });

  it('switches tenant and persists session', async () => {
    await useAuthStore.getState().login('demo@pix2pi.local', '123456');
    useAuthStore.getState().switchTenant('tenant-2');
    expect(useAuthStore.getState().session?.activeTenant.slug).toBe('pilot-tenant');
    expect(window.localStorage.getItem('pix2pi.phase1.session')).toContain('pilot-tenant');
  });
});

