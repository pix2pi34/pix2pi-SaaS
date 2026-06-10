import type { PropsWithChildren } from 'react'
import { AppRuntimeProvider } from './AppRuntimeContext'
import { AuthProvider } from '../../features/auth/context/AuthContext'
import { TenantProvider } from '../../features/tenant/context/TenantContext'

export function AppProviders({ children }: PropsWithChildren) {
  return (
    <AppRuntimeProvider>
      <AuthProvider>
        <TenantProvider>{children}</TenantProvider>
      </AuthProvider>
    </AppRuntimeProvider>
  )
}
