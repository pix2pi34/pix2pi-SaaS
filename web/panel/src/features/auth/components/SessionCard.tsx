import { useAuth } from '../context/AuthContext'

export function SessionCard() {
  const {
    status,
    user,
    session,
    refreshSession,
    signOut,
  } = useAuth()

  if (status !== 'signed_in' || !user || !session) {
    return (
      <section className="surface">
        <div className="section-head-row">
          <div>
            <p className="meta-label">session</p>
            <h2 className="section-title">Session card</h2>
          </div>
          <span className="chip">signed_out</span>
        </div>

        <p className="page-text">
          Aktif session bulunamadi. Hassas kullanici ve tenant bilgileri gizlendi.
        </p>
      </section>
    )
  }

  return (
    <section className="surface">
      <div className="section-head-row">
        <div>
          <p className="meta-label">session</p>
          <h2 className="section-title">Session card</h2>
        </div>
        <span className="chip chip-active">{session.source}</span>
      </div>

      <div className="session-grid">
        <article className="session-item">
          <span className="session-label">Kullanici</span>
          <strong>{user.displayName}</strong>
        </article>
        <article className="session-item">
          <span className="session-label">Email</span>
          <strong>{user.email}</strong>
        </article>
        <article className="session-item">
          <span className="session-label">Rol</span>
          <strong>{user.role}</strong>
        </article>
        <article className="session-item">
          <span className="session-label">Tenant</span>
          <strong>{session.tenantCode}</strong>
        </article>
      </div>

      <div className="contract-meta-row">
        <span className="chip">Auth source: {session.source}</span>
        <span className="chip">
          Remember: {session.remember ? 'localStorage' : 'sessionStorage'}
        </span>
        <span className="chip">Status: {status}</span>
      </div>

      <div className="button-row">
        <button
          type="button"
          className="secondary-button"
          onClick={() => void refreshSession()}
        >
          Session yenile
        </button>
        <button
          type="button"
          className="secondary-button"
          onClick={signOut}
        >
          Session kapat
        </button>
      </div>
    </section>
  )
}
