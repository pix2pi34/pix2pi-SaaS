import type { DashboardActivity } from '../types/dashboard.types'

type DashboardActivityFeedProps = {
  activities: DashboardActivity[]
}

export function DashboardActivityFeed({
  activities,
}: DashboardActivityFeedProps) {
  return (
    <section className="surface dashboard-section">
      <div className="section-head-row">
        <div>
          <p className="meta-label">akislari ozetle</p>
          <h2 className="section-title">Dashboard aktivite akisi</h2>
        </div>
      </div>

      <div className="activity-list">
        {activities.map((activity) => (
          <article key={activity.id} className="activity-item">
            <div className={`activity-state activity-state-${activity.state}`} />
            <div className="activity-body">
              <strong>{activity.title}</strong>
              <p>{activity.detail}</p>
            </div>
            <span className="activity-time">{activity.time}</span>
          </article>
        ))}
      </div>
    </section>
  )
}
