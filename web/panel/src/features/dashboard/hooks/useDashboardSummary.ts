import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { fetchDashboardContract } from '../api/dashboardApi'
import type { DashboardContractData } from '../contracts/dashboard.contract'

type DashboardSummaryState = {
  status: 'loading' | 'success' | 'error'
  data: DashboardContractData | null
  errorMessage: string
  requestId: string
  source: string
  refresh: () => void
}

function normalizeTenantCode(code?: string) {
  const normalized = typeof code === 'string' ? code.trim().toUpperCase() : ''
  return normalized || 'TR01'
}

export function useDashboardSummary(tenantCode?: string): DashboardSummaryState {
  const effectiveTenantCode = normalizeTenantCode(tenantCode)
  const [refreshKey, setRefreshKey] = useState(0)
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading')
  const [data, setData] = useState<DashboardContractData | null>(null)
  const [errorMessage, setErrorMessage] = useState('')
  const [requestId, setRequestId] = useState('')
  const [source, setSource] = useState('')
  const requestSequenceRef = useRef(0)

  const refresh = useCallback(() => {
    setRefreshKey((prev) => prev + 1)
  }, [])

  useEffect(() => {
    let isMounted = true
    const requestSequence = ++requestSequenceRef.current

    setStatus('loading')
    setData(null)
    setErrorMessage('')
    setRequestId('')
    setSource('')

    void fetchDashboardContract(effectiveTenantCode).then((response) => {
      if (!isMounted || requestSequence !== requestSequenceRef.current) {
        return
      }

      if (!response.success) {
        setStatus('error')
        setData(null)
        setErrorMessage(response.error.message)
        setRequestId(response.meta.requestId)
        setSource(response.meta.source)
        return
      }

      setStatus('success')
      setData(response.data)
      setErrorMessage('')
      setRequestId(response.meta.requestId)
      setSource(response.meta.source)
    })

    return () => {
      isMounted = false
    }
  }, [effectiveTenantCode, refreshKey])

  return useMemo(
    () => ({
      status,
      data,
      errorMessage,
      requestId,
      source,
      refresh,
    }),
    [status, data, errorMessage, requestId, source, refresh],
  )
}
