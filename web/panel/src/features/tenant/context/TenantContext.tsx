import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type PropsWithChildren,
} from 'react'
import { useAuth } from '../../auth/context/AuthContext'
import { fetchTenantContext } from '../api/tenantApi'
import type {
  TenantContextResult,
  TenantContextStatus,
  TenantItem,
} from '../types/tenant.types'

type TenantContextValue = {
  status: TenantContextStatus
  tenants: TenantItem[]
  activeTenant: TenantItem | null
  errorCode: string
  errorMessage: string
  errorRequestId: string
  errorSource: string
  setActiveTenantCode: (code: string) => void
  switchTenant: (code: string) => void
  refreshTenantContext: () => Promise<void>
}

const TenantContext = createContext<TenantContextValue | undefined>(undefined)

function normalizeTenantCode(code?: string) {
  const normalized = typeof code === 'string' ? code.trim().toUpperCase() : ''
  return normalized || 'TR01'
}

function buildTenantList(code?: string): TenantItem[] {
  const normalized = normalizeTenantCode(code)

  const base: TenantItem[] = [
    {
      id: 'tr01',
      code: 'TR01',
      name: 'TR01 Merkez',
      status: normalized === 'TR01' ? 'active' : 'available',
    },
    {
      id: 'tr01-fin',
      code: 'TR01-FIN',
      name: 'TR01 Finans',
      status: normalized === 'TR01-FIN' ? 'active' : 'available',
    },
    {
      id: 'tr01-ops',
      code: 'TR01-OPS',
      name: 'TR01 Operasyon',
      status: normalized === 'TR01-OPS' ? 'active' : 'available',
    },
  ]

  const exists = base.some((item) => item.code === normalized)

  if (!exists) {
    base.unshift({
      id: normalized.toLowerCase(),
      code: normalized,
      name: `${normalized} Tenant`,
      status: 'active',
    })
  }

  return base.map((item) => ({
    ...item,
    status: item.code === normalized ? 'active' : 'available',
  }))
}

function mergeTenantCandidates(
  currentTenants: TenantItem[],
  preferredCode?: string,
): TenantItem[] {
  const preferred = normalizeTenantCode(preferredCode)
  const fallback = buildTenantList(preferred)
  const map = new Map<string, TenantItem>()

  for (const item of fallback) {
    map.set(item.code, item)
  }

  for (const item of currentTenants) {
    map.set(item.code, {
      ...map.get(item.code),
      ...item,
    })
  }

  return Array.from(map.values()).map((item) => ({
    ...item,
    status: item.code === preferred ? 'active' : 'available',
  }))
}

function resolveActiveTenant(
  result: TenantContextResult,
  preferredCode?: string,
): TenantItem | null {
  if (result.tenants.length === 0) {
    return null
  }

  const preferred = normalizeTenantCode(preferredCode || result.currentTenantCode)
  const matched = result.tenants.find((item) => item.code === preferred)

  return matched ?? result.tenants[0] ?? null
}

function buildFallbackContext(code?: string): TenantContextResult {
  const currentTenantCode = normalizeTenantCode(code)

  return {
    currentTenantCode,
    tenants: buildTenantList(currentTenantCode),
  }
}

export function TenantProvider({ children }: PropsWithChildren) {
  const { status: authStatus, session } = useAuth()
  const [status, setStatus] = useState<TenantContextStatus>('idle')
  const [tenants, setTenants] = useState<TenantItem[]>([])
  const [activeTenant, setActiveTenant] = useState<TenantItem | null>(null)
  const [errorCode, setErrorCode] = useState('')
  const [errorMessage, setErrorMessage] = useState('')
  const [errorRequestId, setErrorRequestId] = useState('')
  const [errorSource, setErrorSource] = useState('')
  const [refreshKey, setRefreshKey] = useState(0)
  const requestSequenceRef = useRef(0)

  const refreshTenantContext = useCallback(async () => {
    setErrorCode('')
    setErrorMessage('')
    setErrorRequestId('')
    setErrorSource('')
    setRefreshKey((prev) => prev + 1)
  }, [])

  const setActiveTenantCode = useCallback((code: string) => {
    const raw = code.trim().toUpperCase()

    if (!raw) {
      setErrorCode('TENANT_CONTEXT_EMPTY_TENANT')
      setErrorMessage('Tenant secimi zorunludur.')
      setErrorRequestId('')
      setErrorSource('tenant.context.client')
      return
    }

    const switchableTenants = mergeTenantCandidates(tenants, raw)
    const availableCodes = switchableTenants.map((item) => item.code)

    if (switchableTenants.length > 0 && !availableCodes.includes(raw)) {
      setErrorCode('TENANT_CONTEXT_FORBIDDEN')
      setErrorMessage('Bu tenant baglamina erisiminiz yok.')
      setErrorRequestId('')
      setErrorSource('tenant.context.client')
      return
    }

    requestSequenceRef.current += 1

    setErrorCode('')
    setErrorMessage('')
    setErrorRequestId('')
    setErrorSource('')
    setStatus('ready')

    setTenants(
      switchableTenants.map((item) => ({
        ...item,
        status: item.code === raw ? 'active' : 'available',
      })),
    )

    setActiveTenant(
      switchableTenants.find((item) => item.code === raw) ?? null,
    )
  }, [tenants])

  const switchTenant = useCallback((code: string) => {
    setActiveTenantCode(code)
  }, [setActiveTenantCode])

  useEffect(() => {
    let isMounted = true

    if (authStatus !== 'signed_in' || !session) {
      requestSequenceRef.current += 1
      setStatus('idle')
      setTenants([])
      setActiveTenant(null)
      setErrorCode('')
      setErrorMessage('')
      setErrorRequestId('')
      setErrorSource('')
      return () => {
        isMounted = false
      }
    }

    const requestSequence = ++requestSequenceRef.current
    const preferredCode = activeTenant?.code || session.tenantCode
    const fallback = buildFallbackContext(preferredCode)

    setTenants(mergeTenantCandidates(fallback.tenants, preferredCode))
    setActiveTenant(resolveActiveTenant(fallback, preferredCode))
    setStatus('ready')
    setErrorCode('')
    setErrorMessage('')
    setErrorRequestId('')
    setErrorSource('')

    void fetchTenantContext(session)
      .then((response) => {
        if (
          !isMounted ||
          requestSequence !== requestSequenceRef.current
        ) {
          return
        }

        if (!response.success) {
          const safeTenants = mergeTenantCandidates(fallback.tenants, preferredCode)

          setTenants(safeTenants)
          setActiveTenant(
            resolveActiveTenant(
              {
                currentTenantCode: preferredCode,
                tenants: safeTenants,
              },
              preferredCode,
            ),
          )
          setStatus('ready')
          setErrorCode(response.error.code)
          setErrorMessage(response.error.message)
          setErrorRequestId(response.meta.requestId)
          setErrorSource(response.meta.source)
          return
        }

        const safeTenants = mergeTenantCandidates(
          response.data.tenants,
          response.data.currentTenantCode || preferredCode,
        )

        const nextActive = resolveActiveTenant(
          {
            currentTenantCode: response.data.currentTenantCode,
            tenants: safeTenants,
          },
          preferredCode,
        )

        setTenants(safeTenants)
        setActiveTenant(nextActive)
        setStatus('ready')
        setErrorCode('')
        setErrorMessage('')
        setErrorRequestId('')
        setErrorSource('')
      })
      .catch(() => {
        if (
          !isMounted ||
          requestSequence !== requestSequenceRef.current
        ) {
          return
        }

        const safeTenants = mergeTenantCandidates(fallback.tenants, preferredCode)

        setTenants(safeTenants)
        setActiveTenant(
          resolveActiveTenant(
            {
              currentTenantCode: preferredCode,
              tenants: safeTenants,
            },
            preferredCode,
          ),
        )
        setStatus('ready')
        setErrorCode('TENANT_CONTEXT_PROVIDER_ERROR')
        setErrorMessage('Tenant context fallback aktif.')
        setErrorRequestId('')
        setErrorSource('tenant.context.provider')
      })

    return () => {
      isMounted = false
    }
  }, [authStatus, session, refreshKey])

  const value = useMemo<TenantContextValue>(
    () => ({
      status,
      tenants,
      activeTenant,
      errorCode,
      errorMessage,
      errorRequestId,
      errorSource,
      setActiveTenantCode,
      switchTenant,
      refreshTenantContext,
    }),
    [
      status,
      tenants,
      activeTenant,
      errorCode,
      errorMessage,
      errorRequestId,
      errorSource,
      setActiveTenantCode,
      switchTenant,
      refreshTenantContext,
    ],
  )

  return <TenantContext.Provider value={value}>{children}</TenantContext.Provider>
}

export function useTenant() {
  const context = useContext(TenantContext)

  if (!context) {
    throw new Error('useTenant must be used within TenantProvider')
  }

  return context
}
