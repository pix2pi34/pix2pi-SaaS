import type { PropsWithChildren } from 'react'
import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../../features/auth/context/AuthContext'
import { useTenant } from '../../features/tenant/context/TenantContext'
import { ROUTE_PATHS } from '../router/RoutePaths'
import { useAppRuntime } from '../providers/AppRuntimeContext'

const navItems = [
  { id: 'dashboard', label: 'Dashboard', to: ROUTE_PATHS.dashboard },
  { id: 'monitoring', label: 'Monitoring', to: ROUTE_PATHS.monitoring },
]

export function AppShell({ children }: PropsWithChildren) {
  const runtime = useAppRuntime()
  const { status: authStatus, user, session } = useAuth()
  const { activeTenant, status: tenantStatus } = useTenant()

  return (
    <div className="app-shell">
      <aside className="app-sidebar">
        <div className="brand-block">
          <div className="brand-logo">P2</div>
          <div>
            <strong className="brand-title">Pix2pi Panel</strong>
            <p className="brand-subtitle">LVL9.5 Tenant Backend Binding</p>
          </div>
        </div>

        <nav className="shell-nav" aria-label="ana gezinme">
          {navItems.map((item) => (
            <NavLink
              key={item.id}
              to={item.to}
              className={({ isActive }) =>
                `shell-nav-link${isActive ? ' shell-nav-link-active' : ''}`
              }
            >
              <span>{item.label}</span>
              <span className="nav-state">{item.to}</span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-box">
          <p className="meta-label">Calisma durumu</p>
          <div className="chip-wrap">
            <span className="chip chip-active">Shell aktif</span>
            <span className="chip chip-active">Auth: {authStatus}</span>
            <span className="chip chip-active">
              Tenant: {activeTenant ? activeTenant.code : tenantStatus}
            </span>
            <span className="chip chip-active">Transport: {runtime.apiTransportMode}</span>
            <span className="chip chip-active">
              Session source: {session ? session.source : 'none'}
            </span>
            <span className="chip chip-active">Tenant backend binding hazir</span>
          </div>
        </div>

        <div className="sidebar-box tenant-mini-box">
          <p className="meta-label">oturum baglami</p>
          <div className="sidebar-meta-list">
            <div className="sidebar-meta-item">
              <span>Kullanici</span>
              <strong>{user ? user.displayName : 'guest'}</strong>
            </div>
            <div className="sidebar-meta-item">
              <span>Tenant</span>
              <strong>{activeTenant ? activeTenant.name : 'bagli degil'}</strong>
            </div>
          </div>
        </div>
      </aside>

      <div className="app-main">
        <header className="app-topbar">
          <div>
            <p className="meta-label">Pix2pi SaaS UI Surface</p>
            <h1 className="topbar-title">Tenant backend binding katmani hazir</h1>
          </div>

          <div className="topbar-meta">
            <span className="chip">Env: {runtime.environment}</span>
            <span className="chip">API: {runtime.apiBaseUrl}</span>
            <span className="chip">Transport: {runtime.apiTransportMode}</span>
            <span className="chip">Auth: {runtime.authMode}</span>
            <span className="chip">Tenant UI: {runtime.tenantMode}</span>
            <span className="chip">Monitoring UI: {runtime.monitoringMode}</span>
            <span className="chip">Contract UI: {runtime.contractMode}</span>
            <span className="chip">State UI: {runtime.sharedStateMode}</span>
            <span className="chip">Design UI: {runtime.designMode}</span>
            <span className="chip">
              Tenant: {activeTenant ? activeTenant.code : tenantStatus}
            </span>
            <span className="chip">Version: {runtime.appVersion}</span>
          </div>
        </header>

        <main className="app-content">{children ?? <Outlet />}</main>
      </div>
    </div>
  )
}
