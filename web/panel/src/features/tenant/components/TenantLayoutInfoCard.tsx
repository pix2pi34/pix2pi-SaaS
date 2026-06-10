import { useAppRuntime } from '../../../app/providers/AppRuntimeContext'
import { UiErrorState } from '../../../shared/ui-states/components/UiErrorState'
import { useAuth } from '../../auth/context/AuthContext'
import { useTenant } from '../context/TenantContext'

function buildFallbackTenantName(code?: string) {
  const normalized = typeof code === 'string' ? code.trim().toUpperCase() : ''

  if (!normalized || normalized === 'TR01') {
    return 'TR01 Merkez'
  }

  if (normalized === 'TR01-FIN') {
    return 'TR01 Finans'
  }

  if (normalized === 'TR01-OPS') {
    return 'TR01 Operasyon'
  }

  return `${normalized} Tenant`
}

export function TenantLayoutInfoCard() {
  const runtime = useAppRuntime()
  const { session } = useAuth()
  const {
    activeTenant,
    tenants,
    status,
    errorMessage,
    errorRequestId,
    errorSource,
    refreshTenantContext,
  } = useTenant()

  const effectiveCode = activeTenant?.code ?? session?.tenantCode ?? 'TR01'
  const effectiveName =
    activeTenant?.name ??
    tenants.find((item) => item.code === effectiveCode)?.name ??
    buildFallbackTenantName(effectiveCode)

  const availableCount = tenants.length > 0 ? tenants.length : 1

  return (
    <section className="surface side-info-card">
      <p className="meta-label">tenant context</p>
      <h3 className="section-title">Aktif tenant baglami</h3>

      <div className="tenant-info-grid">
        <article className="tenant-info-item">
          <span className="tenant-info-label">Tenant</span>
          <strong>{effectiveName}</strong>
        </article>

        <article className="tenant-info-item">
          <span className="tenant-info-label">Kod</span>
          <strong>{effectiveCode}</strong>
        </article>

        <article className="tenant-info-item">
          <span className="tenant-info-label">Context status</span>
          <strong>{status}</strong>
        </article>

        <article className="tenant-info-item">
          <span className="tenant-info-label">Gorunen tenant sayisi</span>
          <strong>{availableCount}</strong>
        </article>
      </div>

      <div className="contract-meta-row">
        <span className="chip">Aktif kod: {effectiveCode}</span>
        <span className="chip">Status: {status}</span>
      </div>

      {errorMessage ? (
        <UiErrorState
          label="tenant state"
          title="Tenant context hatasi"
          description={errorMessage}
          requestId={errorRequestId}
          source={errorSource}
          mode={runtime.apiTransportMode}
          retryLabel="Tenant context tekrar dene"
          onRetry={() => void refreshTenantContext()}
        />
      ) : (
        <p className="page-text">
          Tenant bilgisi backend context veya guvenli fallback ile gosteriliyor.
        </p>
      )}
    </section>
  )
}
