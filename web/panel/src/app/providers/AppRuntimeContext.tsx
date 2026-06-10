import { createContext, useContext, type PropsWithChildren } from 'react'
import type { ApiTransportMode } from '../../shared/api/client/httpClient'
import {
  evaluateReleaseReadiness,
  evaluateRuntimeSafetyGate,
  readRuntimeConfig,
  type ReleaseReadiness,
  type RuntimeSafetyGate,
} from '../../shared/runtime/runtimeConfig'
import {
  evaluateRuntimeSecurityGuard,
  type RuntimeSecurityGuard,
} from '../../shared/runtime/runtimeSecurity'
import {
  evaluateReleaseCandidateClosure,
  evaluateValidationClosure,
  type ReleaseCandidateClosure,
  type ValidationClosure,
} from '../../shared/runtime/releaseCandidate'

export type AppRuntime = {
  appName: string
  appVersion: string
  environment: string
  apiBaseUrl: string
  authMode: 'ui_ready' | 'pending'
  tenantMode: 'ui_ready' | 'pending'
  monitoringMode: 'ui_ready' | 'pending'
  contractMode: 'ui_ready' | 'pending'
  sharedStateMode: 'ui_ready' | 'pending'
  designMode: 'ui_ready' | 'pending'
  apiTransportMode: ApiTransportMode
  configStatus: 'ready' | 'warning'
  configIssues: string[]
  runtimeSafetyGate: RuntimeSafetyGate
  releaseReadiness: ReleaseReadiness
  runtimeSecurityGuard: RuntimeSecurityGuard
  validationClosure: ValidationClosure
  releaseCandidateClosure: ReleaseCandidateClosure
}

const runtimeConfig = readRuntimeConfig()
const runtimeSafetyGate = evaluateRuntimeSafetyGate(runtimeConfig)
const releaseReadiness = evaluateReleaseReadiness(runtimeConfig, runtimeSafetyGate)
const runtimeSecurityGuard = evaluateRuntimeSecurityGuard(runtimeConfig)
const validationClosure = evaluateValidationClosure({
  runtimeSafetyGate,
  runtimeSecurityGuard,
  releaseReadiness,
})
const releaseCandidateClosure = evaluateReleaseCandidateClosure({
  runtimeSafetyGate,
  runtimeSecurityGuard,
  releaseReadiness,
})

const defaultRuntime: AppRuntime = {
  appName: runtimeConfig.appName,
  appVersion: runtimeConfig.appVersion,
  environment: runtimeConfig.environment,
  apiBaseUrl: runtimeConfig.apiBaseUrl,
  authMode: 'ui_ready',
  tenantMode: 'ui_ready',
  monitoringMode: 'ui_ready',
  contractMode: 'ui_ready',
  sharedStateMode: 'ui_ready',
  designMode: 'ui_ready',
  apiTransportMode: runtimeConfig.apiTransportMode,
  configStatus: runtimeConfig.configStatus,
  configIssues: runtimeConfig.configIssues,
  runtimeSafetyGate,
  releaseReadiness,
  runtimeSecurityGuard,
  validationClosure,
  releaseCandidateClosure,
}

const AppRuntimeContext = createContext<AppRuntime>(defaultRuntime)

export function AppRuntimeProvider({ children }: PropsWithChildren) {
  return (
    <AppRuntimeContext.Provider value={defaultRuntime}>
      {children}
    </AppRuntimeContext.Provider>
  )
}

export function useAppRuntime() {
  return useContext(AppRuntimeContext)
}
