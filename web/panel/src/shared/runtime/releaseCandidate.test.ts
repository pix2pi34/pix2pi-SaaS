import { describe, expect, it } from 'vitest'
import { buildRuntimeConfig, evaluateReleaseReadiness, evaluateRuntimeSafetyGate } from './runtimeConfig'
import { evaluateRuntimeSecurityGuard } from './runtimeSecurity'
import {
  evaluateReleaseCandidateClosure,
  evaluateValidationClosure,
} from './releaseCandidate'

function buildInput(environment: string, mode: 'mock' | 'hybrid' | 'live') {
  const config = buildRuntimeConfig({
    environment,
    apiBaseUrl: 'https://api.pix2pi.com.tr',
    apiTransportMode: mode,
    appVersion: '0.9.9',
  })

  const runtimeSafetyGate = evaluateRuntimeSafetyGate(config)
  const releaseReadiness = evaluateReleaseReadiness(config, runtimeSafetyGate)
  const runtimeSecurityGuard = evaluateRuntimeSecurityGuard(config)

  return {
    runtimeSafetyGate,
    runtimeSecurityGuard,
    releaseReadiness,
  }
}

describe('releaseCandidate', () => {
  it('production live durumda validation ready olur', () => {
    const input = buildInput('production', 'live')
    const result = evaluateValidationClosure(input)

    expect(result.status).toBe('ready')
    expect(result.checks.every((item) => item.status === 'pass')).toBe(true)
  })

  it('production hybrid durumda validation warning olur', () => {
    const input = buildInput('production', 'hybrid')
    const result = evaluateValidationClosure(input)

    expect(result.status).toBe('warning')
    expect(result.checks.some((item) => item.status === 'warn')).toBe(true)
  })

  it('production mock durumda rc block olur', () => {
    const input = buildInput('production', 'mock')
    const result = evaluateReleaseCandidateClosure(input)

    expect(result.status).toBe('block')
    expect(result.checks.some((item) => item.status === 'block')).toBe(true)
  })

  it('production live durumda rc ready olur', () => {
    const input = buildInput('production', 'live')
    const result = evaluateReleaseCandidateClosure(input)

    expect(result.status).toBe('ready')
    expect(result.title).toBe('Release candidate ready')
  })
})
