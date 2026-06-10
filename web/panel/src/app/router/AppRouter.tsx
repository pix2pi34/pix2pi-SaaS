import { Navigate, Route, Routes } from 'react-router-dom'
import { useAuth } from '../../features/auth/context/AuthContext'
import { AppShell } from '../shell/AppShell'
import { LoginPage } from '../../features/auth/pages/LoginPage'
import { DashboardPage } from '../../features/dashboard/pages/DashboardPage'
import { MonitoringPage } from '../../features/monitoring/pages/MonitoringPage'
import { ROUTE_PATHS } from './RoutePaths'
import { AuthGuard } from './guards/AuthGuard'
import { TenantGuard } from './guards/TenantGuard'

function RootRedirect() {
  const { status } = useAuth()

  return (
    <Navigate
      to={status === 'signed_in' ? ROUTE_PATHS.dashboard : ROUTE_PATHS.login}
      replace
    />
  )
}

export function AppRouter() {
  return (
    <Routes>
      <Route path={ROUTE_PATHS.root} element={<RootRedirect />} />
      <Route path={ROUTE_PATHS.login} element={<LoginPage />} />

      <Route
        path={ROUTE_PATHS.app}
        element={
          <AuthGuard>
            <TenantGuard>
              <AppShell />
            </TenantGuard>
          </AuthGuard>
        }
      >
        <Route index element={<Navigate to={ROUTE_PATHS.dashboard} replace />} />
        <Route path="dashboard" element={<DashboardPage />} />
        <Route path="monitoring" element={<MonitoringPage />} />
      </Route>

      <Route path="*" element={<RootRedirect />} />
    </Routes>
  )
}
