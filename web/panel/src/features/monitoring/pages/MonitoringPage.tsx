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
import { DashboardQuickActions } from '../../dashboard/components/DashboardQuickActions'
import { TenantLayoutInfoCard } from '../../tenant/components/TenantLayoutInfoCard'
import { TenantSwitcherCard } from '../../tenant/components/TenantSwitcherCard'
import { useTenant } from '../../tenant/context/TenantContext'
import { MonitoringHealthOverview } from '../components/MonitoringHealthOverview'
import { MonitoringServiceStatusTable } from '../components/MonitoringServiceStatusTable'
import { MonitoringTimeline } from '../components/MonitoringTimeline'
import { MonitoringWarningsPanel } from '../components/MonitoringWarningsPanel'
import { useMonitoringSummary } from '../hooks/useMonitoringSummary'

const nextLayers = ['LVL9 RC kapanisi', 'LVL10 baslangic paketi']

export function MonitoringPage() {
  const runtime = useAppRuntime()
  const { status: authStatus } = useAuth()
  const { activeTenant } = useTenant()
  const monitoringState = useMonitoringSummary(activeTenant?.code ?? '')
  const hasData =
    monitoringState.status === 'success' &&
    monitoringState.data &&
    monitoringState.data.cards.length > 0

  const canManualRetry =
    authStatus === 'signed_in' &&
    Boolean(activeTenant) &&
    runtime.runtimeSecurityGuard.status !== 'block' &&
    !runtime.runtimeSafetyGate.shouldBlockApp

  function handleRetry() {
    if (!canManualRetry) {
      return
    }

    monitoringState.refresh()
  }

  return (
    <>
      <PageHero
        badge="aktif rota"
        title="Monitoring route aktif"
        description="Monitoring route artik gercek health ve warnings endpointlerine hazir hybrid transport omurgasi ile calisiyor. Endpointler varsa real veri, yoksa mock fallback kullaniliyor."
        stats={[
          { value: 'READY', label: 'real health transport' },
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
              {monitoringState.status === 'loading' ? (
                <UiLoadingState
                  label="monitoring state"
                  title="Monitoring contract verisi yukleniyor"
                  description="Health ve warnings adapter aktif. Ortak loading state kullaniliyor."
                />
              ) : null}

              {monitoringState.status === 'error' ? (
                <UiErrorState
                  label="monitoring state"
                  title="Monitoring contract hatasi"
                  description={monitoringState.errorMessage}
                  requestId={monitoringState.requestId}
                  source={monitoringState.source}
                  mode={runtime.apiTransportMode}
                  retryLabel="Monitoring tekrar dene"
                  onRetry={handleRetry}
                />
              ) : null}

              {monitoringState.status === 'success' && !hasData ? (
                <UiEmptyState
                  label="monitoring state"
                  title="Monitoring verisi bulunamadi"
                  description="Contract cevabi geldi ancak gosterilecek monitoring verisi bulunamadi."
                />
              ) : null}

              {hasData && monitoringState.data ? (
                <>
                  <UiSuccessState
                    label="monitoring state"
                    title="Monitoring contract basariyla yuklendi"
                    description="Monitoring health ve warnings transport omurgasi aktif. Hybrid veya live modda endpointler okunuyor."
                    source={monitoringState.source}
                    requestId={monitoringState.requestId}
                  />
                  <MonitoringHealthOverview cards={monitoringState.data.cards} />
                  <MonitoringWarningsPanel warnings={monitoringState.data.warnings} />
                  <MonitoringServiceStatusTable services={monitoringState.data.services} />
                  <MonitoringTimeline timeline={monitoringState.data.timeline} />
                  <DashboardQuickActions
                    actions={[
                      {
                        id: 'contract-refresh',
                        title: 'Monitoring yenile',
                        detail: 'Health ve warnings endpointleri tekrar cagrilabilir.',
                        state: 'ready',
                      },
                      {
                        id: 'warning-drilldown',
                        title: 'Warning detay',
                        detail: 'Warnings endpointi artik real transport omurgasi ile bagli.',
                        state: 'next',
                      },
                      {
                        id: 'tenant-context',
                        title: 'Tenant baglami aktif',
                        detail: activeTenant
                          ? `${activeTenant.code} icin monitoring contract gosteriliyor.`
                          : 'tenant baglami bekleniyor',
                        state: 'ready',
                      },
                    ]}
                  />
                  <TenantSwitcherCard />
                </>
              ) : null}
            </>
          )}
        </div>

        <aside className="auth-side-column">
          <TenantLayoutInfoCard />

          <InfoPanel
            label="monitoring transport ozeti"
            title="Health / warnings entegrasyon durumu"
            items={[
              `Health path: ${API_ENDPOINTS.healthSummary}`,
              `Warnings path: ${API_ENDPOINTS.monitoringWarnings}`,
              `Transport mode: ${runtime.apiTransportMode}`,
              `Base URL: ${runtime.apiBaseUrl}`,
              `Aktif kaynak: ${monitoringState.source || 'bekleniyor'}`,
              `Request ID: ${monitoringState.requestId || 'bekleniyor'}`,
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
            <h3 className="section-title">Monitoring yenileme</h3>
            <div className="button-row">
              <button
                type="button"
                className="secondary-button"
                onClick={handleRetry}
                disabled={!canManualRetry}
              >
                Monitoring yenile
              </button>
            </div>
            <div className="contract-meta-row">
              <span className="chip">Health: {API_ENDPOINTS.healthSummary}</span>
              <span className="chip">Warnings: {API_ENDPOINTS.monitoringWarnings}</span>
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
