import { useMemo } from 'react';
import { useAuthStore } from '../core/auth/auth-store';

type AppShellProps = {
  activeRoute: string;
  onNavigate: (route: string) => void;
  children: React.ReactNode;
};

const menuItems = [
  { key: 'dashboard', label: 'Panel', requiredRole: null },
  { key: 'service-registry', label: 'Servisler', requiredRole: 'TENANT_ADMIN' },
  { key: 'mission-control', label: 'Mission Control', requiredRole: 'TENANT_ADMIN' },
  { key: 'jobs-queue', label: 'Jobs Queue', requiredRole: 'TENANT_ADMIN' },
  { key: 'webhook-monitor', label: 'Webhook Monitor', requiredRole: 'TENANT_ADMIN' },
  { key: 'workflow-monitor', label: 'Workflow Monitor', requiredRole: 'TENANT_ADMIN' },
  { key: 'plugin-monitor', label: 'Plugin Monitor', requiredRole: 'TENANT_ADMIN' },
  { key: 'publicapi-monitor', label: 'Public API Monitor', requiredRole: 'TENANT_ADMIN' },
  { key: 'notification-monitor', label: 'Notification Monitor', requiredRole: 'TENANT_ADMIN' },
  { key: 'early-warning', label: 'Early Warning', requiredRole: 'TENANT_ADMIN' },
  { key: 'incident-audit', label: 'Incident / Audit Center', requiredRole: 'TENANT_ADMIN' },
  { key: 'runtime-topology', label: 'Runtime Topology', requiredRole: 'TENANT_ADMIN' },
  { key: 'realtime-monitor', label: 'Realtime Monitor', requiredRole: 'TENANT_ADMIN' },
  { key: 'tenants', label: 'Tenantlar', requiredRole: 'TENANT_ADMIN' },
  { key: 'security', label: 'Guvenlik', requiredRole: 'TENANT_ADMIN' },
  { key: 'exports', label: 'Exportlar', requiredRole: 'FINANCE_VIEWER' },
];

export function AppShell({ activeRoute, onNavigate, children }: AppShellProps) {
  const session = useAuthStore((state) => state.session);
  const logout = useAuthStore((state) => state.logout);
  const switchTenant = useAuthStore((state) => state.switchTenant);
  const hasRole = useAuthStore((state) => state.hasRole);

  const visibleMenu = useMemo(
    () => menuItems.filter((item) => (item.requiredRole ? hasRole(item.requiredRole) : true)),
    [hasRole],
  );

  if (!session) {
    return null;
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar__logo">Pix2pi</div>

        <div className="sidebar__section">
          <div className="sidebar__label">Tenant</div>
          <select
            aria-label="Tenant Sec"
            value={session.activeTenant.id}
            onChange={(event) => switchTenant(event.target.value)}
          >
            {session.tenants.map((tenant) => (
              <option value={tenant.id} key={tenant.id}>
                {tenant.name}
              </option>
            ))}
          </select>
        </div>

        <div className="sidebar__section">
          <div className="sidebar__label">Menu</div>
          <ul className="sidebar__menu">
            {visibleMenu.map((item) => (
              <li key={item.key}>
                <button
                  type="button"
                  className={activeRoute === item.key ? 'active' : ''}
                  onClick={() => onNavigate(item.key)}
                >
                  {item.label}
                </button>
              </li>
            ))}
          </ul>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div>
            <strong>{session.activeTenant.name}</strong>
            <div className="small">{session.user.fullName} · {session.user.email}</div>
          </div>

          <div className="button-row">
            <span className="badge">{session.roles.map((role) => role.label).join(', ')}</span>
            <button type="button" className="btn btn-secondary" onClick={() => logout()}>
              Cikis yap
            </button>
          </div>
        </header>

        <main className="page">{children}</main>
      </div>
    </div>
  );
}
