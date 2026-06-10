import { beforeEach, describe, expect, it } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { AppProviders } from '../../../app/providers/AppProviders'
import { App } from '../../../app/App'

describe('Authentication UI', () => {
  beforeEach(() => {
    window.localStorage.clear()
    window.sessionStorage.clear()
  })

  it('gecerli bilgiler ile demo session acar', async () => {
    render(
      <AppProviders>
        <App />
      </AppProviders>,
    )

    expect(screen.getByText('Authentication UI yuzeyi hazir')).toBeInTheDocument()

    fireEvent.change(screen.getByLabelText('Email'), {
      target: { value: 'demo@pix2pi.local' },
    })

    fireEvent.change(screen.getByLabelText('Sifre'), {
      target: { value: 'Demo123' },
    })

    fireEvent.change(screen.getByLabelText('Tenant Kodu'), {
      target: { value: 'TR01' },
    })

    fireEvent.click(screen.getByRole('button', { name: 'Demo session ac' }))

    expect(await screen.findByText('Dashboard route aktif')).toBeInTheDocument()
    expect(await screen.findByText('Session card')).toBeInTheDocument()
    expect(screen.getByText('Auth source: mock')).toBeInTheDocument()
  })

  it('eksik bilgi ile hata mesaji gosterir', () => {
    render(
      <AppProviders>
        <App />
      </AppProviders>,
    )

    expect(screen.getByText('Authentication UI yuzeyi hazir')).toBeInTheDocument()

    fireEvent.change(screen.getByLabelText('Email'), {
      target: { value: '' },
    })

    fireEvent.change(screen.getByLabelText('Sifre'), {
      target: { value: '123' },
    })

    fireEvent.change(screen.getByLabelText('Tenant Kodu'), {
      target: { value: 'T' },
    })

    fireEvent.click(screen.getByRole('button', { name: 'Demo session ac' }))

    expect(screen.getByText('Email zorunludur.')).toBeInTheDocument()
  })
})
