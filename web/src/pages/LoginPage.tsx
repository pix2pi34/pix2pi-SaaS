import { FormEvent, useState } from 'react';
import { useAuthStore } from '../core/auth/auth-store';

export function LoginPage() {
  const login = useAuthStore((state) => state.login);
  const status = useAuthStore((state) => state.status);
  const error = useAuthStore((state) => state.error);
  const [email, setEmail] = useState('demo@pix2pi.local');
  const [password, setPassword] = useState('123456');

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await login(email, password);
  }

  return (
    <div className="auth-page">
      <div className="card auth-card">
        <div style={{ marginBottom: 20 }}>
          <strong>Pix2pi Giris</strong>
          <div className="small">Demo kullanici: demo@pix2pi.local / 123456</div>
        </div>

        <form className="form-grid" onSubmit={handleSubmit}>
          <div className="field" style={{ gridColumn: '1 / -1' }}>
            <label htmlFor="email">Email</label>
            <input id="email" value={email} onChange={(event) => setEmail(event.target.value)} />
          </div>
          <div className="field" style={{ gridColumn: '1 / -1' }}>
            <label htmlFor="password">Sifre</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </div>
          {error ? (
            <div className="small" style={{ color: 'var(--color-danger)', gridColumn: '1 / -1' }}>
              {error}
            </div>
          ) : null}
          <button type="submit" className="btn btn-primary" disabled={status === 'loading'}>
            {status === 'loading' ? 'Giris yapiliyor...' : 'Giris yap'}
          </button>
        </form>
      </div>
    </div>
  );
}

