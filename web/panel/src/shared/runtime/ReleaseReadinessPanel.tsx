import { useAppRuntime } from '../../app/providers/AppRuntimeContext'

export function ReleaseReadinessPanel() {
  const runtime = useAppRuntime()
  const readiness = runtime.releaseReadiness

  return (
    <section className="surface side-info-card consistency-card">
      <p className="meta-label">release readiness</p>
      <h3 className="section-title">Release readiness paneli</h3>

      <div className="contract-meta-row">
        <span className="chip">Status: {readiness.status}</span>
        <span className="chip">Checks: {readiness.checks.length}</span>
      </div>

      <div className="tenant-info-grid">
        {readiness.checks.map((check) => (
          <article key={check.id} className="tenant-info-item">
            <span className="tenant-info-label">{check.label}</span>
            <strong>{check.status}</strong>
          </article>
        ))}
      </div>
    </section>
  )
}
