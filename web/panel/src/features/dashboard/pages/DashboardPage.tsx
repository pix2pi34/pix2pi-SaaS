import { useAppRuntime } from '../../../app/providers/AppRuntimeContext'
import { API_ENDPOINTS } from '../../../shared/api/config/endpoints'
import { DesignTokenPanel } from '../../../shared/design/components/DesignTokenPanel'
import { InfoPanel } from '../../../shared/design/components/InfoPanel'
import { PageHero } from '../../../shared/design/components/PageHero'
import { ReleaseCandidateClosurePanel } from '../../../shared/runtime/ReleaseCandidateClosurePanel'
import { ReleaseReadinessPanel } from '../../../shared/runtime/ReleaseReadinessPanel'
import { RuntimeConfigPanel } from '../../../shared/runtime/RuntimeConfigPanel'
import { RuntimeSafetyGatePanel } from '../../../shared/runtime/RuntimeSafetyGatePanel'
import { RuntimeSecurityPanel } from '../../../shared/runtime/RuntimeSecurityPanel'
import { ValidationClosurePanel } from '../../../shared/runtime/ValidationClosurePanel'
import { UiEmptyState } from '../../../shared/ui-states/components/UiEmptyState'
import { UiErrorState } from '../../../shared/ui-states/components/UiErrorState'
import { UiLoadingState } from '../../../shared/ui-states/components/UiLoadingState'
import { UiSuccessState } from '../../../shared/ui-states/components/UiSuccessState'
import { useAuth } from '../../auth/context/AuthContext'
import { SessionCard } from '../../auth/components/SessionCard'
import { TenantLayoutInfoCard } from '../../tenant/components/TenantLayoutInfoCard'
import { TenantSwitcherCard } from '../../tenant/components/TenantSwitcherCard'
import { useTenant } from '../../tenant/context/TenantContext'
import { DashboardActivityFeed } from '../components/DashboardActivityFeed'
import { DashboardKpiGrid } from '../components/DashboardKpiGrid'
import { DashboardQuickActions } from '../components/DashboardQuickActions'
import { DashboardSummaryPanel } from '../components/DashboardSummaryPanel'
import { useDashboardSummary } from '../hooks/useDashboardSummary'

const nextLayers = ['LVL9 RC kapanisi', 'LVL10 baslangic paketi']

export function DashboardPage() {
  const runtime = useAppRuntime()
  const { status: authStatus } = useAuth()
  const { activeTenant } = useTenant()
  const dashboardState = useDashboardSummary(activeTenant?.code ?? '')
  const hasData =
    dashboardState.status === 'success' &&
    dashboardState.data &&
    dashboardState.data.metrics.length > 0

  const canManualRetry =
    authStatus === 'signed_in' &&
    Boolean(activeTenant) &&
    runtime.runtimeSecurityGuard.status !== 'block' &&
    !runtime.runtimeSafetyGate.shouldBlockApp

  function handleRetry() {
    if (!canManualRetry) {
      return
    }

    dashboardState.refresh()
  }

  return (
    <>
      <PageHero
        badge="aktif rota"
        title="Dashboard route aktif"
        description="Dashboard route artik gercek summary endpointine hazir hybrid transport omurgasi ile calisiyor. Endpoint varsa real veri, yoksa mock fallback kullaniliyor."
        stats={[
          { value: 'READY', label: 'real summary transport' },
          { value: runtime.apiTransportMode.toUpperCase(), label: 'transport mode' },
          { value: activeTenant?.code ?? 'TR01', label: 'aktif tenant' },
        ]}
      />

      <section className="auth-layout">
        <div className="auth-main-column">
          {runtime.runtimeSafetyGate.shouldBlockApp ||
          runtime.runtimeSecurityGuard.status === 'block' ? (
            <UiErrorState
              label="runtime security"
              title={runtime.runtimeSecurityGuard.title}
              description={runtime.runtimeSecurityGuard.description}
              source="runtime.config"
              mode={runtime.apiTransportMode}
            />
          ) : (
            <>
              {dashboardState.status === 'loading' ? (
                <UiLoadingState
                  label="dashboard state"
                  title="Dashboard verisi yukleniyor"
                  description="Summary contract ve tenant baglami birlikte yukleniyor."
                />
              ) : null}

              {dashboardState.status === 'error' ? (
                <UiErrorState
                  label="dashboard state"
                  title="Dashboard contract hatasi"
                  description={dashboardState.errorMessage}
                  requestId={dashboardState.requestId}
                  source={dashboardState.source}
                  mode={runtime.apiTransportMode}
                  retryLabel="Summary tekrar dene"
                  onRetry={handleRetry}
                />
              ) : null}

              {dashboardState.status === 'success' && !hasData ? (
                <UiEmptyState
                  label="dashboard state"
                  title="Dashboard verisi bulunamadi"
                  description="Contract cevabi geldi ancak gosterilecek dashboard verisi bulunamadi."
                />
              ) : null}

              {hasData && dashboardState.data ? (
                <>
                  <UiSuccessState
                    label="dashboard state"
                    title="Dashboard contract basariyla yuklendi"
                    description="Dashboard summary transport omurgasi aktif. Hybrid veya live modda endpointler okunuyor."
                    requestId={dashboardState.requestId}
                    source={dashboardState.source}
                  />
                  <SessionCard />
                  <DashboardKpiGrid metrics={dashboardState.data.metrics} />
                  <DashboardActivityFeed activities={dashboardState.data.activities} />
                  <DashboardQuickActions actions={dashboardState.data.actions} />
                  <DashboardSummaryPanel cards={dashboardState.data.summaryCards} />
                  <TenantSwitcherCard />
                </>
              ) : null}
            </>
          )}
        </div>

        <aside className="auth-side-column">
          <TenantLayoutInfoCard />

          <InfoPanel
            label="dashboard transport ozeti"
            title="Summary entegrasyon durumu"
            items={[
              `Endpoint path: ${API_ENDPOINTS.dashboardSummary}`,
              `Transport mode: ${runtime.apiTransportMode}`,
              `Base URL: ${runtime.apiBaseUrl}`,
              `Aktif kaynak: ${dashboardState.source || 'bekleniyor'}`,
              `Request ID: ${dashboardState.requestId || 'bekleniyor'}`,
            ]}
          />

          <RuntimeConfigPanel />
          <RuntimeSafetyGatePanel />
          <RuntimeSecurityPanel />
          <ReleaseReadinessPanel />
          <ValidationClosurePanel />
          <ReleaseCandidateClosurePanel />

          <section className="surface side-info-card consistency-card">
            <p className="meta-label">manuel kontrol</p>
            <h3 className="section-title">Dashboard yenileme</h3>
            <div className="button-row">
              <button
                type="button"
                className="secondary-button"
                onClick={handleRetry}
                disabled={!canManualRetry}
              >
                Summary yenile
              </button>
            </div>
            <div className="contract-meta-row">
              <span className="chip">Endpoint: {API_ENDPOINTS.dashboardSummary}</span>
              <span className="chip">Mode: {runtime.apiTransportMode}</span>
            </div>
            {!canManualRetry ? (
              <p className="page-text">
                Guvenlik korumasi nedeniyle manuel retry su an kisitli.
              </p>
            ) : null}
          </section>

          <InfoPanel
            label="siradaki katmanlar"
            title="Sonraki fazlar"
            items={nextLayers}
          />

          <DesignTokenPanel />
        </aside>
      </section>
    </>
  )
}
