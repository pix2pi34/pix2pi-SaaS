import type { SessionResponse } from './types';

const demoResponse: SessionResponse = {
  accessToken: 'demo-token',
  expiresAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
  user: {
    id: 'user-1',
    fullName: 'Demo Kullanici',
    email: 'demo@pix2pi.local',
    isSuperAdmin: false,
  },
  activeTenant: {
    id: 'tenant-1',
    name: 'Merkez Tenant',
    slug: 'merkez-tenant',
  },
  tenants: [
    { id: 'tenant-1', name: 'Merkez Tenant', slug: 'merkez-tenant' },
    { id: 'tenant-2', name: 'Pilot Tenant', slug: 'pilot-tenant' },
  ],
  roles: [
    { code: 'TENANT_ADMIN', label: 'Tenant Admin' },
    { code: 'FINANCE_VIEWER', label: 'Finans Goruntuleyici' },
  ],
};

export async function loginWithPassword(email: string, password: string): Promise<SessionResponse> {
  await new Promise((resolve) => setTimeout(resolve, 300));

  if (!email || !password) {
    throw new Error('Email ve sifre zorunludur');
  }

  if (email !== 'demo@pix2pi.local' || password !== '123456') {
    throw new Error('Gecersiz kullanici bilgileri');
  }

  return demoResponse;
}

export async function logoutSession(): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, 100));
}

