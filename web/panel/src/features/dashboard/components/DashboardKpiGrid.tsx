import type { DashboardMetric } from '../types/dashboard.types'

type DashboardKpiGridProps = {
  metrics: DashboardMetric[]
}

export function DashboardKpiGrid({ metrics }: DashboardKpiGridProps) {
  return (
    <section className="surface dashboard-section">
      <div className="section-head-row">
        <div>
          <p className="meta-label">dashboard kpi</p>
          <h2 className="section-title">Dashboard KPI kartlari</h2>
        </div>
        <span className="chip chip-active">LVL8.7</span>
      </div>

      <div className="dashboard-kpi-grid">
        {metrics.map((metric) => (
          <article key={metric.id} className="dashboard-kpi-card">
            <p className="dashboard-kpi-label">{metric.label}</p>
            <strong className="dashboard-kpi-value">{metric.value}</strong>
            <span className={`metric-delta metric-delta-${metric.tone}`}>
              {metric.delta}
            </span>
          </article>
        ))}
      </div>
    </section>
  )
}
