import type { ApiTransportMode } from '../api/client/httpClient'

export type RuntimeEnvironment = 'development' | 'test' | 'production'

export type RuntimeConfig = {
  appName: string
  appVersion: string
  environment: RuntimeEnvironment
  apiBaseUrl: string
  apiTransportMode: ApiTransportMode
  configStatus: 'ready' | 'warning'
  configIssues: string[]
}

export type RuntimeSafetyGate = {
  status: 'pass' | 'warning' | 'block'
  shouldBlockApp: boolean
  title: string
  description: string
  issues: string[]
}

export type ReleaseReadinessCheck = {
  id: string
  label: string
  status: 'pass' | 'warn'
}

export type ReleaseReadiness = {
  status: 'ready' | 'warning'
  checks: ReleaseReadinessCheck[]
}

type RuntimeConfigInput = {
  appName?: string
  appVersion?: string
  environment?: string
  apiBaseUrl?: string
  apiTransportMode?: string
}

function normalizeEnvironment(input?: string): {
  value: RuntimeEnvironment
  issue?: string
} {
  const normalized = (input ?? '').trim().toLowerCase()

  if (normalized === 'production') {
    return { value: 'production' }
  }

  if (normalized === 'test') {
    return { value: 'test' }
  }

  if (normalized === 'development' || normalized === 'dev') {
    return { value: 'development' }
  }

  if (!normalized) {
    return {
      value: 'development',
      issue: 'environment missing, development fallback aktif',
    }
  }

  return {
    value: 'development',
    issue: `environment invalid (${input}), development fallback aktif`,
  }
}

function normalizeTransportMode(input?: string): {
  value: ApiTransportMode
  issue?: string
} {
  const normalized = (input ?? '').trim().toLowerCase()

  if (normalized === 'mock' || normalized === 'hybrid' || normalized === 'live') {
    return { value: normalized }
  }

  if (!normalized) {
    return {
      value: 'hybrid',
      issue: 'transport mode missing, hybrid fallback aktif',
    }
  }

  return {
    value: 'hybrid',
    issue: `transport mode invalid (${input}), hybrid fallback aktif`,
  }
}

function isAbsoluteUrl(value: string) {
  return /^https?:\/\//i.test(value)
}

export function sanitizeApiBaseUrl(input?: string): {
  value: string
  issue?: string
} {
  const raw = (input ?? '').trim()

  if (!raw) {
    return {
      value: '/api',
      issue: 'api base url missing, /api fallback aktif',
    }
  }

  if (isAbsoluteUrl(raw)) {
    return {
      value: raw.replace(/\/+$/, ''),
    }
  }

  if (raw.startsWith('/')) {
    return {
      value: raw.replace(/\/+$/, '') || '/api',
    }
  }

  return {
    value: '/api',
    issue: `api base url invalid (${input}), /api fallback aktif`,
  }
}

export function joinApiUrl(baseUrl: string, path: string) {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`

  if (isAbsoluteUrl(normalizedPath)) {
    return normalizedPath
  }

  const normalizedBase = baseUrl.replace(/\/+$/, '')

  if (!normalizedBase) {
    return normalizedPath
  }

  return `${normalizedBase}${normalizedPath}`
}

export function buildRuntimeConfig(input: RuntimeConfigInput = {}): RuntimeConfig {
  const issues: string[] = []

  const environmentResult = normalizeEnvironment(input.environment)
  const transportModeResult = normalizeTransportMode(input.apiTransportMode)
  const apiBaseUrlResult = sanitizeApiBaseUrl(input.apiBaseUrl)

  if (environmentResult.issue) {
    issues.push(environmentResult.issue)
  }

  if (transportModeResult.issue) {
    issues.push(transportModeResult.issue)
  }

  if (apiBaseUrlResult.issue) {
    issues.push(apiBaseUrlResult.issue)
  }

  if (environmentResult.value === 'production' && transportModeResult.value === 'mock') {
    issues.push('production ortaminda mock transport kullaniliyor')
  }

  return {
    appName: input.appName?.trim() || 'Pix2pi Panel',
    appVersion: input.appVersion?.trim() || '0.9.7-dev',
    environment: environmentResult.value,
    apiBaseUrl: apiBaseUrlResult.value,
    apiTransportMode: transportModeResult.value,
    configStatus: issues.length > 0 ? 'warning' : 'ready',
    configIssues: issues,
  }
}

export function evaluateRuntimeSafetyGate(config: RuntimeConfig): RuntimeSafetyGate {
  const issues: string[] = []
  let shouldBlockApp = false

  for (const issue of config.configIssues) {
    issues.push(issue)
  }

  if (config.environment === 'production' && config.apiTransportMode === 'mock') {
    shouldBlockApp = true
    issues.push('production modda mock transport bloklandi')
  }

  if (
    config.environment === 'production' &&
    config.apiTransportMode === 'live' &&
    config.apiBaseUrl === '/api'
  ) {
    issues.push('production live modda relative /api base url kullaniliyor')
  }

  if (shouldBlockApp) {
    return {
      status: 'block',
      shouldBlockApp: true,
      title: 'Runtime safety gate bloklandi',
      description:
        'Runtime config production guvenlik kosullarini saglamadigi icin uygulama bu ekranda bloklandi.',
      issues,
    }
  }

  if (issues.length > 0) {
    return {
      status: 'warning',
      shouldBlockApp: false,
      title: 'Runtime safety gate warning',
      description:
        'Runtime config warning modunda calisiyor. Uygulama acilir ancak release oncesi duzeltme onerilir.',
      issues,
    }
  }

  return {
    status: 'pass',
    shouldBlockApp: false,
    title: 'Runtime safety gate passed',
    description: 'Runtime config guvenlik kapisindan gecti.',
    issues: [],
  }
}

export function evaluateReleaseReadiness(
  config: RuntimeConfig,
  safetyGate: RuntimeSafetyGate,
): ReleaseReadiness {
  const checks: ReleaseReadinessCheck[] = [
    {
      id: 'build-time-config',
      label: 'Build-time config check',
      status: config.configStatus === 'ready' ? 'pass' : 'warn',
    },
    {
      id: 'runtime-smoke',
      label: 'Runtime smoke check',
      status: safetyGate.shouldBlockApp ? 'warn' : 'pass',
    },
    {
      id: 'endpoint-wiring',
      label: 'Endpoint wiring standardi',
      status: config.apiBaseUrl ? 'pass' : 'warn',
    },
    {
      id: 'transport-guard',
      label: 'Transport safety guard',
      status:
        config.environment === 'production' && config.apiTransportMode === 'mock'
          ? 'warn'
          : 'pass',
    },
    {
      id: 'env-matrix',
      label: 'Env matrix kontrolu',
      status: config.environment ? 'pass' : 'warn',
    },
    {
      id: 'final-pass-gate',
      label: 'Final release gate',
      status: safetyGate.status === 'pass' ? 'pass' : 'warn',
    },
  ]

  const hasWarn = checks.some((item) => item.status === 'warn')

  return {
    status: hasWarn ? 'warning' : 'ready',
    checks,
  }
}

export function readRuntimeConfig(): RuntimeConfig {
  return buildRuntimeConfig({
    appName: import.meta.env.VITE_APP_NAME,
    appVersion: import.meta.env.VITE_APP_VERSION,
    environment: import.meta.env.MODE,
    apiBaseUrl: import.meta.env.VITE_API_BASE_URL,
    apiTransportMode: import.meta.env.VITE_API_TRANSPORT_MODE,
  })
}
