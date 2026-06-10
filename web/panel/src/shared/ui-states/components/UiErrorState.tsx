import type { ApiTransportMode } from '../../api/client/httpClient'

type UiErrorStateProps = {
  label: string
  title: string
  description: string
  requestId?: string
  source?: string
  mode?: ApiTransportMode
  retryLabel?: string
  onRetry?: () => void
}

export function UiErrorState({
  label,
  title,
  description,
  requestId,
  source,
  mode,
  retryLabel = 'Tekrar dene',
  onRetry,
}: UiErrorStateProps) {
  return (
    <section className="surface state-surface state-error" aria-live="polite">
      <div className="section-head-row">
        <div>
          <p className="meta-label">{label}</p>
          <h2 className="section-title">{title}</h2>
        </div>
        <span className="chip chip-warn">error</span>
      </div>

      <p className="page-text">{description}</p>

      <div className="contract-meta-row">
        {requestId ? <span className="chip">Request ID: {requestId}</span> : null}
        {source ? <span className="chip">Source: {source}</span> : null}
        {mode ? <span className="chip">Mode: {mode}</span> : null}
      </div>

      {onRetry ? (
        <div className="button-row">
          <button
            type="button"
            className="secondary-button"
            onClick={onRetry}
          >
            {retryLabel}
          </button>
        </div>
      ) : null}
    </section>
  )
}
