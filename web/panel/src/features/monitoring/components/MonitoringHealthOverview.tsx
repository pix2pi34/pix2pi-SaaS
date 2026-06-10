import type { HealthCard } from '../types/monitoring.types'

type MonitoringHealthOverviewProps = {
  cards: HealthCard[]
}

export function MonitoringHealthOverview({
  cards,
}: MonitoringHealthOverviewProps) {
  return (
    <section className="surface monitoring-section">
      <div className="section-head-row">
        <div>
          <p className="meta-label">monitoring health</p>
          <h2 className="section-title">Monitoring health overview</h2>
        </div>
        <span className="chip chip-active">LVL8.7</span>
      </div>

      <div className="monitoring-health-grid">
        {cards.map((card) => (
          <article key={card.id} className="monitoring-health-card">
            <p className="monitoring-card-label">{card.label}</p>
            <strong className="monitoring-card-value">{card.value}</strong>
            <span className={`monitoring-tone monitoring-tone-${card.tone}`}>
              {card.detail}
            </span>
          </article>
        ))}
      </div>
    </section>
  )
}
