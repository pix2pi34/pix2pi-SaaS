type UiEmptyStateProps = {
  label: string
  title: string
  description: string
}

export function UiEmptyState({
  label,
  title,
  description,
}: UiEmptyStateProps) {
  return (
    <section className="surface contract-state-box contract-state-box-empty">
      <p className="meta-label">{label}</p>
      <h2 className="section-title">{title}</h2>
      <p className="page-text">{description}</p>
      <div className="shared-state-note">Ortak empty state katmani aktif.</div>
    </section>
  )
}
