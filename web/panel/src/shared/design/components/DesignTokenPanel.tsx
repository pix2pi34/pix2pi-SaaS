const colorTokens = [
  { label: 'Primary', className: 'token-swatch token-swatch-primary' },
  { label: 'Success', className: 'token-swatch token-swatch-success' },
  { label: 'Warning', className: 'token-swatch token-swatch-warning' },
  { label: 'Danger', className: 'token-swatch token-swatch-danger' },
]

const radiusTokens = ['radius-sm', 'radius-md', 'radius-lg', 'radius-xl']
const spacingTokens = ['space-2', 'space-3', 'space-4', 'space-6']

export function DesignTokenPanel() {
  return (
    <section className="surface side-info-card consistency-card">
      <p className="meta-label">design consistency</p>
      <h3 className="section-title">Token preview</h3>

      <div className="token-panel-grid">
        <article className="token-card">
          <strong>Renk tokenlari</strong>
          <div className="token-chip-row">
            {colorTokens.map((token) => (
              <div key={token.label} className="token-chip-item">
                <span className={token.className} />
                <span>{token.label}</span>
              </div>
            ))}
          </div>
        </article>

        <article className="token-card">
          <strong>Radius tokenlari</strong>
          <div className="shape-preview-row">
            {radiusTokens.map((token) => (
              <span key={token} className={`shape-pill ${token}`}>
                {token}
              </span>
            ))}
          </div>
        </article>

        <article className="token-card">
          <strong>Spacing tokenlari</strong>
          <div className="spacing-bars">
            {spacingTokens.map((token) => (
              <div key={token} className="spacing-bar-item">
                <span>{token}</span>
                <div className={`spacing-bar ${token}`} />
              </div>
            ))}
          </div>
        </article>
      </div>
    </section>
  )
}
