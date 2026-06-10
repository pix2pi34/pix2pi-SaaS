import { useState, type FormEvent } from 'react'
import { useAppRuntime } from '../../../app/providers/AppRuntimeContext'
import { UiErrorState } from '../../../shared/ui-states/components/UiErrorState'
import { useAuth } from '../context/AuthContext'

function validateEmail(value: string) {
  return /\S+@\S+\.\S+/.test(value)
}

export function LoginCard() {
  const runtime = useAppRuntime()
  const {
    signIn,
    errorMessage,
    errorRequestId,
    errorSource,
    status,
    canRetryAuthMe,
    retryAuthMe,
  } = useAuth()

  const [email, setEmail] = useState('demo@pix2pi.local')
  const [password, setPassword] = useState('Demo123')
  const [tenantCode, setTenantCode] = useState('TR01')
  const [remember, setRemember] = useState(true)
  const [validationError, setValidationError] = useState('')

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    if (!email.trim()) {
      setValidationError('Email zorunludur.')
      return
    }

    if (!validateEmail(email.trim())) {
      setValidationError('Email formati gecersiz.')
      return
    }

    if (!password.trim()) {
      setValidationError('Sifre zorunludur.')
      return
    }

    if (tenantCode.trim().length < 3) {
      setValidationError('Tenant Kodu en az 3 karakter olmalidir.')
      return
    }

    setValidationError('')
    await signIn({
      email: email.trim(),
      password,
      tenantCode: tenantCode.trim(),
      remember,
    })
  }

  return (
    <section className="surface">
      <div className="auth-card-head">
        <div>
          <p className="meta-label">authentication</p>
          <h2 className="section-title">Authentication UI yuzeyi hazir</h2>
        </div>
        <span className="chip chip-active">LVL9.6.5</span>
      </div>

      <p className="page-text">
        Demo session akisi artik auth transport omurgasina bagli. Hybrid modda
        endpoint yoksa mock fallback ile oturum acilir.
      </p>

      <form className="auth-form" onSubmit={handleSubmit}>
        <label className="field-block">
          <span>Email</span>
          <input
            aria-label="Email"
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
          />
        </label>

        <label className="field-block">
          <span>Sifre</span>
          <input
            aria-label="Sifre"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
          />
        </label>

        <label className="field-block">
          <span>Tenant Kodu</span>
          <input
            aria-label="Tenant Kodu"
            type="text"
            value={tenantCode}
            onChange={(event) => setTenantCode(event.target.value)}
          />
        </label>

        <label className="checkbox-row">
          <input
            aria-label="Beni hatirla"
            type="checkbox"
            checked={remember}
            onChange={(event) => setRemember(event.target.checked)}
          />
          <span>Beni hatirla</span>
        </label>

        {validationError ? (
          <div className="feedback-box feedback-error">{validationError}</div>
        ) : null}

        {errorMessage ? (
          <UiErrorState
            label="auth state"
            title="Authentication hatasi"
            description={errorMessage}
            requestId={errorRequestId}
            source={errorSource}
            mode={runtime.apiTransportMode}
            retryLabel={canRetryAuthMe ? 'Session tekrar dene' : 'Tekrar dene'}
            onRetry={canRetryAuthMe ? () => void retryAuthMe() : undefined}
          />
        ) : null}

        <div className="button-row">
          <button
            type="submit"
            className="primary-button"
            disabled={status === 'loading'}
          >
            {status === 'loading' ? 'Session aciliyor...' : 'Demo session ac'}
          </button>
        </div>
      </form>

      <div className="auth-contract-grid">
        <article className="contract-card">
          <strong>POST /api/v1/auth/login</strong>
          <p>Gercek login contract noktasi</p>
        </article>
        <article className="contract-card">
          <strong>GET /api/v1/auth/me</strong>
          <p>Session restore ve me baglama noktasi</p>
        </article>
      </div>
    </section>
  )
}
