import type { DashboardAction } from '../types/dashboard.types'

type DashboardQuickActionsProps = {
  actions: DashboardAction[]
}

export function DashboardQuickActions({
  actions,
}: DashboardQuickActionsProps) {
  return (
    <section className="surface dashboard-section">
      <div className="section-head-row">
        <div>
          <p className="meta-label">hizli aksiyonlar</p>
          <h2 className="section-title">Dashboard hizli aksiyon kartlari</h2>
        </div>
      </div>

      <div className="quick-action-grid">
        {actions.map((action) => (
          <article key={action.id} className="quick-action-card">
            <div className="quick-action-head">
              <strong>{action.title}</strong>
              <span className={`quick-action-badge quick-action-badge-${action.state}`}>
                {action.state}
              </span>
            </div>
            <p>{action.detail}</p>
            <button
              type="button"
              className={action.state === 'ready' ? 'primary-button' : 'secondary-button'}
              disabled={action.state !== 'ready'}
            >
              {action.state === 'ready' ? 'Hazir' : 'Sonraki katman'}
            </button>
          </article>
        ))}
      </div>
    </section>
  )
}
