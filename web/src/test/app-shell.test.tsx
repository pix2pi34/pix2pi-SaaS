import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it } from 'vitest';
import { AppShell } from '../layout/AppShell';
import { useAuthStore } from '../core/auth/auth-store';

beforeEach(() => {
  useAuthStore.setState({
    status: 'authenticated',
    error: null,
    session: {
      accessToken: 'token',
      expiresAt: new Date(Date.now() + 1000).toISOString(),
      user: {
        id: 'u1',
        fullName: 'Demo Kullanici',
        email: 'demo@pix2pi.local',
        isSuperAdmin: false,
      },
      activeTenant: { id: 'tenant-1', name: 'Merkez Tenant', slug: 'merkez-tenant' },
      tenants: [
        { id: 'tenant-1', name: 'Merkez Tenant', slug: 'merkez-tenant' },
        { id: 'tenant-2', name: 'Pilot Tenant', slug: 'pilot-tenant' },
      ],
      roles: [
        { code: 'TENANT_ADMIN', label: 'Tenant Admin' },
        { code: 'FINANCE_VIEWER', label: 'Finans Goruntuleyici' },
      ],
    },
  });
});

describe('app-shell', () => {
  it('renders role aware menu items', () => {
    render(
      <AppShell activeRoute="dashboard" onNavigate={() => undefined}>
        <div>icerik</div>
      </AppShell>,
    );

    expect(screen.getByText('Panel')).toBeInTheDocument();
    expect(screen.getByText('Guvenlik')).toBeInTheDocument();
    expect(screen.getByText('Exportlar')).toBeInTheDocument();
  });

  it('switches tenant from tenant selector', async () => {
    const user = userEvent.setup();
    render(
      <AppShell activeRoute="dashboard" onNavigate={() => undefined}>
        <div>icerik</div>
      </AppShell>,
    );

    await user.selectOptions(screen.getByLabelText('Tenant Sec'), 'tenant-2');
    expect(useAuthStore.getState().session?.activeTenant.slug).toBe('pilot-tenant');
  });
});

