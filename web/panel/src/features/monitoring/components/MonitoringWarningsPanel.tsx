import type { WarningItem } from '../types/monitoring.types'

type MonitoringWarningsPanelProps = {
  warnings: WarningItem[]
}

export function MonitoringWarningsPanel({
  warnings,
}: MonitoringWarningsPanelProps) {
  return (
    <section className="surface monitoring-section">
      <div className="section-head-row">
        <div>
          <p className="meta-label">uyarilar</p>
          <h2 className="section-title">Monitoring warnings panel</h2>
        </div>
      </div>

      <div className="warning-list">
        {warnings.map((warning) => (
          <article key={warning.id} className="warning-item">
            <div className={`warning-badge warning-badge-${warning.level}`}>
              {warning.level}
            </div>
            <div className="warning-body">
              <strong>{warning.title}</strong>
              <p>{warning.detail}</p>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}
