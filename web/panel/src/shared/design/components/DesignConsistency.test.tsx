import { render, screen } from '@testing-library/react'
import { DesignTokenPanel } from './DesignTokenPanel'
import { InfoPanel } from './InfoPanel'
import { PageHero } from './PageHero'

describe('Design Consistency Layer', () => {
  it('page hero render eder', () => {
    render(
      <PageHero
        badge="aktif"
        title="Design consistency aktif"
        description="Tek tip hero yapisi kullaniliyor."
        stats={[
          { value: 'READY', label: 'hero token' },
          { value: 'READY', label: 'info card' },
        ]}
      />,
    )

    expect(screen.getByText('Design consistency aktif')).toBeInTheDocument()
    expect(screen.getByText('hero token')).toBeInTheDocument()
  })

  it('info panel render eder', () => {
    render(
      <InfoPanel
        label="bilgi"
        title="Ortak bilgi karti"
        items={['Madde 1', 'Madde 2']}
      />,
    )

    expect(screen.getByText('Ortak bilgi karti')).toBeInTheDocument()
    expect(screen.getByText('Madde 1')).toBeInTheDocument()
  })

  it('design token panel render eder', () => {
    render(<DesignTokenPanel />)

    expect(screen.getByText('Token preview')).toBeInTheDocument()
    expect(screen.getByText('Primary')).toBeInTheDocument()
    expect(screen.getByText('radius-lg')).toBeInTheDocument()
    expect(screen.getByText('space-4')).toBeInTheDocument()
  })
})
