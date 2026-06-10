import { useAppRuntime } from '../../app/providers/AppRuntimeContext'

export function ValidationClosurePanel() {
  const runtime = useAppRuntime()
  const validation = runtime.validationClosure

  return (
    <section className="surface side-info-card consistency-card">
      <p className="meta-label">validation closure</p>
      <h3 className="section-title">Validation closure paneli</h3>

      <div className="contract-meta-row">
        <span className="chip">Status: {validation.status}</span>
        <span className="chip">Checks: {validation.checks.length}</span>
      </div>

      <div className="tenant-info-grid">
        {validation.checks.map((check) => (
          <article key={check.id} className="tenant-info-item">
            <span className="tenant-info-label">{check.label}</span>
            <strong>{check.status}</strong>
          </article>
        ))}
      </div>
    </section>
  )
}
