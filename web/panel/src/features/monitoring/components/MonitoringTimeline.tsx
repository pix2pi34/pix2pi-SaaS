import type { TimelineItem } from '../types/monitoring.types'

type MonitoringTimelineProps = {
  timeline: TimelineItem[]
}

export function MonitoringTimeline({ timeline }: MonitoringTimelineProps) {
  return (
    <section className="surface monitoring-section">
      <div className="section-head-row">
        <div>
          <p className="meta-label">monitoring akisi</p>
          <h2 className="section-title">Monitoring timeline</h2>
        </div>
      </div>

      <div className="monitoring-timeline">
        {timeline.map((item) => (
          <article key={item.id} className="monitoring-timeline-item">
            <div className="monitoring-timeline-dot" />
            <div className="monitoring-timeline-body">
              <strong>{item.title}</strong>
              <p>{item.detail}</p>
            </div>
            <span className="activity-time">{item.time}</span>
          </article>
        ))}
      </div>
    </section>
  )
}
