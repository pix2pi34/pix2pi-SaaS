import { render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { SessionCard } from './SessionCard'

const authState = vi.hoisted(() => ({
  status: 'signed_out',
  user: null,
  session: null,
}))

vi.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    status: authState.status,
    user: authState.user,
    session: authState.session,
    errorCode: '',
    errorMessage: '',
    errorRequestId: '',
    errorSource: '',
    canRetryAuthMe: false,
    signIn: vi.fn(),
    signOut: vi.fn(),
    refreshSession: vi.fn(),
    retryAuthMe: vi.fn(),
  }),
}))

describe('SessionCard security', () => {
  it('signed_out durumda hassas kullanici bilgisini gostermez', () => {
    authState.status = 'signed_out'
    authState.user = null
    authState.session = null

    render(<SessionCard />)

    expect(screen.getByText('Session card')).toBeInTheDocument()
    expect(screen.getByText('Aktif session bulunamadi. Hassas kullanici ve tenant bilgileri gizlendi.')).toBeInTheDocument()
    expect(screen.queryByText('demo@pix2pi.local')).not.toBeInTheDocument()
    expect(screen.queryByText('TR01')).not.toBeInTheDocument()
  })
})
