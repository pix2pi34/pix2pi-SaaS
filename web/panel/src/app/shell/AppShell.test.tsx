import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { AppProviders } from '../providers/AppProviders'
import { ROUTE_PATHS } from '../router/RoutePaths'
import { AppShell } from './AppShell'

describe('AppShell', () => {
  it('temel shell alanlarini render eder', () => {
    render(
      <AppProviders>
        <MemoryRouter initialEntries={[ROUTE_PATHS.dashboard]}>
          <AppShell>
            <div>ornek-icerik</div>
          </AppShell>
        </MemoryRouter>
      </AppProviders>,
    )

    expect(screen.getByText('Pix2pi Panel')).toBeInTheDocument()
    expect(screen.getByText('LVL9.5 Tenant Backend Binding')).toBeInTheDocument()
    expect(
      screen.getAllByText('Tenant backend binding katmani hazir').length,
    ).toBeGreaterThan(0)
    expect(screen.getByText('ornek-icerik')).toBeInTheDocument()
    expect(screen.getAllByText(/Env:/i).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/Transport:/i).length).toBeGreaterThan(0)
  })
})
