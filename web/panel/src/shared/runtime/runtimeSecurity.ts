import type { RuntimeConfig } from './runtimeConfig'

export type RuntimeSecurityCheck = {
  id: string
  label: string
  status: 'pass' | 'warn' | 'block'
}

export type RuntimeSecurityGuard = {
  status: 'pass' | 'warning' | 'block'
  title: string
  description: string
  checks: RuntimeSecurityCheck[]
}

export function evaluateRuntimeSecurityGuard(
  config: RuntimeConfig,
): RuntimeSecurityGuard {
  const checks: RuntimeSecurityCheck[] = [
    {
      id: 'production-mock-block',
      label: 'Production + mock blok',
      status:
        config.environment === 'production' && config.apiTransportMode === 'mock'
          ? 'block'
          : 'pass',
    },
    {
      id: 'production-hybrid-warning',
      label: 'Production + hybrid warning',
      status:
        config.environment === 'production' && config.apiTransportMode === 'hybrid'
          ? 'warn'
          : 'pass',
    },
    {
      id: 'live-mode-visibility',
      label: 'Live mode gorunurluk',
      status: config.apiTransportMode === 'live' ? 'pass' : 'warn',
    },
    {
      id: 'runtime-config-status',
      label: 'Runtime config status',
      status: config.configStatus === 'ready' ? 'pass' : 'warn',
    },
  ]

  const hasBlock = checks.some((item) => item.status === 'block')
  const hasWarn = checks.some((item) => item.status === 'warn')

  if (hasBlock) {
    return {
      status: 'block',
      title: 'Runtime security guard blocked',
      description:
        'Bu ortam konfigurasyonu guvenli kabul edilmedigi icin runtime security guard block veriyor.',
      checks,
    }
  }

  if (hasWarn) {
    return {
      status: 'warning',
      title: 'Runtime security guard warning',
      description:
        'Runtime security guard warning modunda. Release oncesi kontrol onerilir.',
      checks,
    }
  }

  return {
    status: 'pass',
    title: 'Runtime security guard passed',
    description: 'Runtime security guard tum kontrolleri gecti.',
    checks,
  }
}
