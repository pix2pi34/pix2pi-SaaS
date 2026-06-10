import type { PropsWithChildren, ReactNode } from 'react'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAppRuntime } from '../../providers/AppRuntimeContext'
import { UiErrorState } from '../../../shared/ui-states/components/UiErrorState'
import { UiLoadingState } from '../../../shared/ui-states/components/UiLoadingState'
import { useAuth } from '../../../features/auth/context/AuthContext'

function renderGuardContent(children?: ReactNode) {
  return children ?? <Outlet />
}

export function AuthGuard({ children }: PropsWithChildren) {
  const runtime = useAppRuntime()
  const location = useLocation()
  const {
    status,
    errorCode,
    errorMessage,
    errorRequestId,
    errorSource,
  } = useAuth()

  if (status === 'loading') {
    return (
      <UiLoadingState
        label="auth guard"
        title="Auth guard kontrol ediyor"
        description="Protected route icin session kontrolu yapiliyor."
      />
    )
  }

  if (status === 'signed_out' && errorCode === 'AUTH_FORBIDDEN') {
    return (
      <UiErrorState
        label="auth guard"
        title="Authentication access blocked"
        description={errorMessage || 'Bu alana erisiminiz yok.'}
        requestId={errorRequestId}
        source={errorSource}
        mode={runtime.apiTransportMode}
      />
    )
  }

  if (status !== 'signed_in') {
    return (
      <Navigate
        to="/login"
        replace
        state={{ from: location.pathname }}
      />
    )
  }

  return renderGuardContent(children)
}
