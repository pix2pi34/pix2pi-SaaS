type SummaryCard = {
  id?: string
  label?: string
  value?: string
  detail?: string
}

type DashboardSummaryPanelProps = {
  cards?: SummaryCard[] | null
}

function normalizeCards(cards?: SummaryCard[] | null): Required<SummaryCard>[] {
  if (!Array.isArray(cards)) {
    return []
  }

  return cards.map((card, index) => ({
    id:
      typeof card?.id === 'string' && card.id.trim()
        ? card.id
        : `summary-card-${index + 1}`,
    label:
      typeof card?.label === 'string' && card.label.trim()
        ? card.label
        : `Ozet ${index + 1}`,
    value:
      typeof card?.value === 'string' && card.value.trim()
        ? card.value
        : '--',
    detail:
      typeof card?.detail === 'string' && card.detail.trim()
        ? card.detail
        : 'detay bekleniyor',
  }))
}

export function DashboardSummaryPanel({
  cards,
}: DashboardSummaryPanelProps) {
  const safeCards = normalizeCards(cards)

  return (
    <section className="surface">
      <div className="section-head-row">
        <div>
          <p className="meta-label">dashboard summary</p>
          <h2 className="section-title">Summary panel</h2>
        </div>
        <span className="chip chip-active">ready</span>
      </div>

      {safeCards.length === 0 ? (
        <p className="page-text">
          Summary kartlari henuz gelmedi.
        </p>
      ) : (
        <div className="summary-panel-grid">
          {safeCards.map((card) => (
            <article key={card.id} className="summary-panel-card">
              <span className="summary-panel-label">{card.label}</span>
              <strong className="summary-panel-value">{card.value}</strong>
              <p className="summary-panel-detail">{card.detail}</p>
            </article>
          ))}
        </div>
      )}
    </section>
  )
}
