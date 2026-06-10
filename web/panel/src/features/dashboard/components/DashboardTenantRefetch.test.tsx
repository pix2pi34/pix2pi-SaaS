import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { AppProviders } from '../../../app/providers/AppProviders'
import { App } from '../../../app/App'

describe('Dashboard Tenant Refetch', () => {
  it('tenant degisince dashboard verisini yeniden yukler', async () => {
    render(
      <AppProviders>
        <App />
      </AppProviders>,
    )

    fireEvent.click(screen.getByRole('button', { name: 'Demo session ac' }))

    expect(await screen.findByText('Dashboard route aktif')).toBeInTheDocument()
    expect(await screen.findByText('₺148.420')).toBeInTheDocument()
    expect(screen.getByText('286')).toBeInTheDocument()

    fireEvent.change(screen.getByLabelText('Tenant secimi'), {
      target: { value: 'TR01-FIN' },
    })

    expect(await screen.findByText('₺212.940')).toBeInTheDocument()
    await waitFor(() => {
      expect(screen.getAllByText('TR01-FIN').length).toBeGreaterThan(0)
    })

    await waitFor(() => {
      expect(screen.queryByText('₺148.420')).not.toBeInTheDocument()
    })

    fireEvent.change(screen.getByLabelText('Tenant secimi'), {
      target: { value: 'TR01-OPS' },
    })

    expect(await screen.findByText('341')).toBeInTheDocument()
    await waitFor(() => {
      expect(screen.getAllByText('TR01-OPS').length).toBeGreaterThan(0)
    })

    await waitFor(() => {
      expect(screen.queryByText('286')).not.toBeInTheDocument()
    })
  })
})
