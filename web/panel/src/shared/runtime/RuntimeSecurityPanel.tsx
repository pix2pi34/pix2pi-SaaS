import { useAppRuntime } from '../../app/providers/AppRuntimeContext'

export function RuntimeSecurityPanel() {
  const runtime = useAppRuntime()
  const guard = runtime.runtimeSecurityGuard

  return (
    <section className="surface side-info-card consistency-card">
      <p className="meta-label">runtime security</p>
      <h3 className="section-title">{guard.title}</h3>
      <p className="page-text">{guard.description}</p>

      <div className="contract-meta-row">
        <span className="chip">Status: {guard.status}</span>
        <span className="chip">Checks: {guard.checks.length}</span>
      </div>

      <div className="tenant-info-grid">
        {guard.checks.map((check) => (
          <article key={check.id} className="tenant-info-item">
            <span className="tenant-info-label">{check.label}</span>
            <strong>{check.status}</strong>
          </article>
        ))}
      </div>
    </section>
  )
}
