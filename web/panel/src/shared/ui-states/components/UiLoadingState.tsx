type UiLoadingStateProps = {
  label: string
  title: string
  description: string
}

export function UiLoadingState({
  label,
  title,
  description,
}: UiLoadingStateProps) {
  return (
    <section className="surface contract-state-box">
      <p className="meta-label">{label}</p>
      <h2 className="section-title">{title}</h2>
      <p className="page-text">{description}</p>

      <div className="shared-state-skeleton-grid" aria-label="loading-state">
        <div className="shared-skeleton-block" />
        <div className="shared-skeleton-block" />
        <div className="shared-skeleton-block" />
      </div>
    </section>
  )
}
