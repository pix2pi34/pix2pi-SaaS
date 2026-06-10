import { useAppRuntime } from '../../app/providers/AppRuntimeContext'
import { toSafeRuntimeIssue } from '../security/errorVisibility'

export function RuntimeSafetyGatePanel() {
  const runtime = useAppRuntime()
  const gate = runtime.runtimeSafetyGate

  return (
    <section className="surface side-info-card consistency-card">
      <p className="meta-label">runtime safety</p>
      <h3 className="section-title">{gate.title}</h3>

      <p className="page-text">{gate.description}</p>

      <div className="contract-meta-row">
        <span className="chip">Status: {gate.status}</span>
        <span className="chip">Block: {gate.shouldBlockApp ? 'yes' : 'no'}</span>
      </div>

      {gate.issues.length > 0 ? (
        <div className="feedback-box feedback-warn">
          {gate.issues.map((issue, index) => (
            <p key={`${issue}-${index}`}>{toSafeRuntimeIssue(issue)}</p>
          ))}
        </div>
      ) : (
        <p className="page-text">Runtime safety gate pass durumda.</p>
      )}
    </section>
  )
}
