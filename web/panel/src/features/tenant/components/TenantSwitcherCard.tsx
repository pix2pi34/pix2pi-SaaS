import { useTenant } from '../context/TenantContext'

export function TenantSwitcherCard() {
  const {
    tenants,
    activeTenant,
    switchTenant,
    errorCode,
    errorMessage,
    status,
  } = useTenant()

  const effectiveCode = activeTenant?.code ?? tenants[0]?.code ?? ''

  return (
    <section className="surface side-info-card">
      <p className="meta-label">tenant switcher</p>
      <h3 className="section-title">Tenant secimi</h3>

      <label className="field-block" htmlFor="tenant-switcher-select">
        <span>Tenant secimi</span>
        <select
          id="tenant-switcher-select"
          aria-label="Tenant secimi"
          value={effectiveCode}
          onChange={(event) => switchTenant(event.target.value)}
          disabled={status === 'idle' || tenants.length === 0}
        >
          {tenants.map((tenant) => (
            <option key={tenant.id} value={tenant.code}>
              {tenant.code} - {tenant.name}
            </option>
          ))}
        </select>
      </label>

      <div className="contract-meta-row">
        <span className="chip">Aktif kod: {effectiveCode || 'yok'}</span>
        <span className="chip">Tenant sayisi: {tenants.length}</span>
      </div>

      {errorMessage ? (
        <div className="feedback-box feedback-error">
          <p>{errorMessage}</p>
          {errorCode ? <p>Kod: {errorCode}</p> : null}
        </div>
      ) : (
        <p className="page-text">
          Tenant degisikligi sonrasi ekran stale veri yerine yeni tenant baglami ile yenilenir.
        </p>
      )}
    </section>
  )
}
