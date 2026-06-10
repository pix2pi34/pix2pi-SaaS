import { useEffect, useMemo, useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppShell } from '../layout/AppShell';
import { useAuthStore } from '../core/auth/auth-store';
import { LoginPage } from '../pages/LoginPage';
import { DashboardPage } from '../pages/DashboardPage';
import { ForbiddenPage } from '../pages/ForbiddenPage';
import { UnauthorizedPage } from '../pages/UnauthorizedPage';
import { ServiceRegistryPage } from '../features/operations/service-registry/ServiceRegistryPage';
import { MissionControlPage } from '../features/operations/mission-control/MissionControlPage';
import { JobsQueuePage } from '../features/operations/jobs-queue/JobsQueuePage';
import { WebhookMonitorPage } from '../features/operations/webhook-monitor/WebhookMonitorPage';
import { WorkflowMonitorPage } from '../features/operations/workflow-monitor/WorkflowMonitorPage';
import { PluginMonitorPage } from '../features/operations/plugin-monitor/PluginMonitorPage';
import { PublicAPIMonitorPage } from '../features/operations/publicapi-monitor/PublicAPIMonitorPage';
import { NotificationMonitorPage } from '../features/operations/notification-monitor/NotificationMonitorPage';
import { EarlyWarningPage } from '../features/operations/early-warning/EarlyWarningPage';
import { IncidentAuditPage } from '../features/operations/incident-audit/IncidentAuditPage';
import { RuntimeTopologyPage } from '../features/operations/runtime-topology/RuntimeTopologyPage';
import { RealtimeMonitorPage } from '../features/operations/realtime-monitor/RealtimeMonitorPage';
import { getRuntimeConfig } from '../core/config/runtime-config';

const tenantAdminRoutes = new Set(['security', 'service-registry', 'mission-control', 'jobs-queue', 'webhook-monitor', 'workflow-monitor', 'plugin-monitor', 'publicapi-monitor', 'notification-monitor', 'early-warning', 'incident-audit', 'runtime-topology', 'realtime-monitor']);

function AppRouter() {
  const status = useAuthStore((state) => state.status);
  const hydrate = useAuthStore((state) => state.hydrate);
  const hasRole = useAuthStore((state) => state.hasRole);
  const [route, setRoute] = useState('dashboard');

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  const config = useMemo(() => getRuntimeConfig(), []);

  if (status === 'idle' || status === 'loading') {
    return <div className="auth-page"><div className="card auth-card">Hazirlaniyor...</div></div>;
  }

  if (status === 'anonymous') {
    return <LoginPage />;
  }

  if (tenantAdminRoutes.has(route) && !hasRole('TENANT_ADMIN')) {
    return (
      <AppShell activeRoute={route} onNavigate={setRoute}>
        <ForbiddenPage />
      </AppShell>
    );
  }

  return (
    <AppShell activeRoute={route} onNavigate={setRoute}>
      {route === 'dashboard' ? <DashboardPage /> : null}
      {route === 'service-registry' ? <ServiceRegistryPage /> : null}
      {route === 'mission-control' ? <MissionControlPage /> : null}
      {route === 'jobs-queue' ? <JobsQueuePage /> : null}
      {route === 'webhook-monitor' ? <WebhookMonitorPage /> : null}
      {route === 'workflow-monitor' ? <WorkflowMonitorPage /> : null}
      {route === 'plugin-monitor' ? <PluginMonitorPage /> : null}
      {route === 'publicapi-monitor' ? <PublicAPIMonitorPage /> : null}
      {route === 'notification-monitor' ? <NotificationMonitorPage /> : null}
      {route === 'early-warning' ? <EarlyWarningPage /> : null}
      {route === 'incident-audit' ? <IncidentAuditPage /> : null}
      {route === 'runtime-topology' ? <RuntimeTopologyPage /> : null}
      {route === 'realtime-monitor' ? <RealtimeMonitorPage /> : null}
      {route === 'security' ? <DashboardPage /> : null}
      {route === 'tenants' ? <DashboardPage /> : null}
      {route === 'exports' ? <DashboardPage /> : null}

      <div className="card span-12" style={{ marginTop: 16 }}>
        <strong>Runtime</strong>
        <div className="small">
          {config.appName} · {config.environmentName} · {config.apiBaseUrl}
        </div>
      </div>
    </AppShell>
  );
}

export function App() {
  const [client] = useState(() => new QueryClient());

  return (
    <QueryClientProvider client={client}>
      <AppRouter />
    </QueryClientProvider>
  );
}

export { UnauthorizedPage };
