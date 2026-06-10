import { useAppRuntime } from '../../app/providers/AppRuntimeContext'
import { toSafeRuntimeIssue } from '../security/errorVisibility'

export function RuntimeConfigPanel() {
  const runtime = useAppRuntime()

  return (
    <section className="surface side-info-card consistency-card">
      <p className="meta-label">runtime config</p>
      <h3 className="section-title">Runtime config paneli</h3>

      <div className="tenant-info-grid">
        <article className="tenant-info-item">
          <span className="tenant-info-label">Environment</span>
          <strong>{runtime.environment}</strong>
        </article>
        <article className="tenant-info-item">
          <span className="tenant-info-label">Transport</span>
          <strong>{runtime.apiTransportMode}</strong>
        </article>
        <article className="tenant-info-item">
          <span className="tenant-info-label">Base URL</span>
          <strong>{runtime.apiBaseUrl}</strong>
        </article>
        <article className="tenant-info-item">
          <span className="tenant-info-label">Config status</span>
          <strong>{runtime.configStatus}</strong>
        </article>
      </div>

      <div className="contract-meta-row">
        <span className="chip">Version: {runtime.appVersion}</span>
        <span className="chip">Status: {runtime.configStatus}</span>
      </div>

      {runtime.configIssues.length > 0 ? (
        <div className="feedback-box feedback-warn">
          {runtime.configIssues.map((issue, index) => (
            <p key={`${issue}-${index}`}>{toSafeRuntimeIssue(issue)}</p>
          ))}
        </div>
      ) : (
        <p className="page-text">
          Runtime config dogrulandi. Endpoint wiring production mantigina hazir.
        </p>
      )}
    </section>
  )
}
