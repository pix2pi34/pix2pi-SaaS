import { useAppRuntime } from '../../app/providers/AppRuntimeContext'

export function ReleaseCandidateClosurePanel() {
  const runtime = useAppRuntime()
  const rc = runtime.releaseCandidateClosure

  return (
    <section className="surface side-info-card consistency-card">
      <p className="meta-label">release candidate</p>
      <h3 className="section-title">{rc.title}</h3>
      <p className="page-text">{rc.description}</p>

      <div className="contract-meta-row">
        <span className="chip">Status: {rc.status}</span>
        <span className="chip">Checks: {rc.checks.length}</span>
      </div>

      <div className="tenant-info-grid">
        {rc.checks.map((check) => (
          <article key={check.id} className="tenant-info-item">
            <span className="tenant-info-label">{check.label}</span>
            <strong>{check.status}</strong>
          </article>
        ))}
      </div>
    </section>
  )
}
