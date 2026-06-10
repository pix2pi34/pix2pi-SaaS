import { describe, expect, it } from 'vitest'
import {
  buildRuntimeConfig,
  evaluateReleaseReadiness,
  evaluateRuntimeSafetyGate,
} from './runtimeConfig'

describe('runtime safety gate', () => {
  it('production + mock durumunda block verir', () => {
    const config = buildRuntimeConfig({
      environment: 'production',
      apiBaseUrl: 'https://api.pix2pi.com.tr',
      apiTransportMode: 'mock',
      appVersion: '0.9.7',
    })

    const gate = evaluateRuntimeSafetyGate(config)

    expect(gate.status).toBe('block')
    expect(gate.shouldBlockApp).toBe(true)
    expect(gate.issues.join(' ')).toContain('production modda mock transport bloklandi')
  })

  it('development fallback durumunda warning verir ama block vermez', () => {
    const config = buildRuntimeConfig({})
    const gate = evaluateRuntimeSafetyGate(config)

    expect(gate.status).toBe('warning')
    expect(gate.shouldBlockApp).toBe(false)
  })

  it('temiz production live config pass verir', () => {
    const config = buildRuntimeConfig({
      environment: 'production',
      apiBaseUrl: 'https://api.pix2pi.com.tr',
      apiTransportMode: 'live',
      appVersion: '0.9.7',
    })

    const gate = evaluateRuntimeSafetyGate(config)

    expect(gate.status).toBe('pass')
    expect(gate.shouldBlockApp).toBe(false)
  })

  it('release readiness warning durumunu hesaplar', () => {
    const config = buildRuntimeConfig({
      environment: 'production',
      apiBaseUrl: 'https://api.pix2pi.com.tr',
      apiTransportMode: 'mock',
      appVersion: '0.9.7',
    })

    const gate = evaluateRuntimeSafetyGate(config)
    const readiness = evaluateReleaseReadiness(config, gate)

    expect(readiness.status).toBe('warning')
    expect(readiness.checks.some((item) => item.status === 'warn')).toBe(true)
  })

  it('release readiness temiz configte ready verir', () => {
    const config = buildRuntimeConfig({
      environment: 'production',
      apiBaseUrl: 'https://api.pix2pi.com.tr',
      apiTransportMode: 'live',
      appVersion: '0.9.7',
    })

    const gate = evaluateRuntimeSafetyGate(config)
    const readiness = evaluateReleaseReadiness(config, gate)

    expect(readiness.status).toBe('ready')
    expect(readiness.checks.every((item) => item.status === 'pass')).toBe(true)
  })
})
