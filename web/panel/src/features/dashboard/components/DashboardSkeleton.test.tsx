import { fireEvent, render, screen } from '@testing-library/react'
import { AppProviders } from '../../../app/providers/AppProviders'
import { App } from '../../../app/App'

describe('Dashboard Skeleton', () => {
  it('signed_in durumda dashboard shared state bloklarini gosterir', async () => {
    render(
      <AppProviders>
        <App />
      </AppProviders>,
    )

    fireEvent.click(screen.getByRole('button', { name: 'Demo session ac' }))

    expect(await screen.findByText('Dashboard route aktif')).toBeInTheDocument()
    expect(
      await screen.findByText('Dashboard contract basariyla yuklendi'),
    ).toBeInTheDocument()
    expect(screen.getByText('Dashboard KPI kartlari')).toBeInTheDocument()
    expect(screen.getByText('Dashboard aktivite akisi')).toBeInTheDocument()
    expect(screen.getByText('Dashboard hizli aksiyon kartlari')).toBeInTheDocument()
    expect(screen.getByText('Gunluk ciro')).toBeInTheDocument()
    expect(
      screen.getByText('State kaynagi: dashboard.contract.mock'),
    ).toBeInTheDocument()
    expect(
      screen.getAllByText('Endpoint: /api/v1/dashboard/summary').length,
    ).toBeGreaterThan(0)
    expect(
      screen.getByRole('button', { name: 'Summary yenile' }),
    ).toBeInTheDocument()
  })
})
