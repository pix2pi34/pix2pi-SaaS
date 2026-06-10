type UiSuccessStateProps = {
  label: string
  title: string
  description: string
  requestId?: string
  source?: string
}

export function UiSuccessState({
  label,
  title,
  description,
  requestId,
  source,
}: UiSuccessStateProps) {
  return (
    <section className="surface state-surface state-success" aria-live="polite">
      <div className="section-head-row">
        <div>
          <p className="meta-label">{label}</p>
          <h2 className="section-title">{title}</h2>
        </div>
        <span className="chip chip-active">success</span>
      </div>

      <p className="page-text">{description}</p>

      <div className="contract-meta-row">
        {requestId ? <span className="chip">Request ID: {requestId}</span> : null}
        {source ? <span className="chip">State kaynagi: {source}</span> : null}
      </div>
    </section>
  )
}
