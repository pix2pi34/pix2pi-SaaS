import type { PropsWithChildren, ReactNode } from 'react'
import { Outlet } from 'react-router-dom'
import { useAppRuntime } from '../../providers/AppRuntimeContext'
import { UiErrorState } from '../../../shared/ui-states/components/UiErrorState'
import { UiLoadingState } from '../../../shared/ui-states/components/UiLoadingState'
import { useTenant } from '../../../features/tenant/context/TenantContext'

const BLOCKING_TENANT_CODES = new Set([
  'TENANT_CONTEXT_FORBIDDEN',
  'TENANT_CONTEXT_MISMATCH',
  'TENANT_CONTEXT_CROSS_TENANT_LEAK',
  'TENANT_CONTEXT_INVALID_TENANT',
  'TENANT_CONTEXT_EMPTY_TENANT',
])

function renderGuardContent(children?: ReactNode) {
  return children ?? <Outlet />
}

export function TenantGuard({ children }: PropsWithChildren) {
  const runtime = useAppRuntime()
  const {
    status,
    errorCode,
    errorMessage,
    errorRequestId,
    errorSource,
  } = useTenant()

  if (status === 'idle') {
    return (
      <UiLoadingState
        label="tenant guard"
        title="Tenant guard kontrol ediyor"
        description="Tenant baglami dogrulaniyor."
      />
    )
  }

  if (BLOCKING_TENANT_CODES.has(errorCode)) {
    return (
      <UiErrorState
        label="tenant guard"
        title="Tenant guard blocked"
        description={errorMessage || 'Tenant baglami gerekli veya erisiminiz yok.'}
        requestId={errorRequestId}
        source={errorSource}
        mode={runtime.apiTransportMode}
      />
    )
  }

  return renderGuardContent(children)
}
