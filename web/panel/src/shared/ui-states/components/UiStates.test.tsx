import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { UiEmptyState } from './UiEmptyState'
import { UiErrorState } from './UiErrorState'
import { UiLoadingState } from './UiLoadingState'
import { UiSuccessState } from './UiSuccessState'

describe('Ui States', () => {
  it('loading state render eder', () => {
    render(
      <UiLoadingState
        label="test loading"
        title="Veri yukleniyor"
        description="Bekleyin"
      />,
    )

    expect(screen.getByText('Veri yukleniyor')).toBeInTheDocument()
    expect(screen.getByText('Bekleyin')).toBeInTheDocument()
  })

  it('error state metadata ve retry ile render eder', () => {
    const onRetry = vi.fn()

    render(
      <UiErrorState
        label="test error"
        title="Hata olustu"
        description="Servis cevap vermedi"
        requestId="req-test-1"
        source="dashboard.contract.live"
        mode="live"
        onRetry={onRetry}
      />,
    )

    expect(screen.getByText('Hata olustu')).toBeInTheDocument()
    expect(screen.getByText('Servis cevap vermedi')).toBeInTheDocument()
    expect(screen.getByText('Request ID: req-test-1')).toBeInTheDocument()
    expect(screen.getByText('Source: dashboard.contract.live')).toBeInTheDocument()
    expect(screen.getByText('Mode: live')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Tekrar dene' }))
    expect(onRetry).toHaveBeenCalledTimes(1)
  })

  it('empty state render eder', () => {
    render(
      <UiEmptyState
        label="test empty"
        title="Veri yok"
        description="Bos sonuc"
      />,
    )

    expect(screen.getByText('Veri yok')).toBeInTheDocument()
    expect(screen.getByText('Bos sonuc')).toBeInTheDocument()
  })

  it('success state render eder', () => {
    render(
      <UiSuccessState
        label="test success"
        title="Yukleme tamam"
        description="Her sey hazir"
        requestId="req-success-1"
        source="dashboard.contract.mock"
      />,
    )

    expect(screen.getByText('Yukleme tamam')).toBeInTheDocument()
    expect(screen.getByText('Her sey hazir')).toBeInTheDocument()
    expect(screen.getByText('Request ID: req-success-1')).toBeInTheDocument()
    expect(screen.getByText('State kaynagi: dashboard.contract.mock')).toBeInTheDocument()
  })
})
