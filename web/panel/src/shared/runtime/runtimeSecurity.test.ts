import { describe, expect, it } from 'vitest'
import { buildRuntimeConfig } from './runtimeConfig'
import { evaluateRuntimeSecurityGuard } from './runtimeSecurity'

describe('runtimeSecurity', () => {
  it('production + mock block verir', () => {
    const config = buildRuntimeConfig({
      environment: 'production',
      apiBaseUrl: 'https://api.pix2pi.com.tr',
      apiTransportMode: 'mock',
      appVersion: '0.9.8',
    })

    const guard = evaluateRuntimeSecurityGuard(config)

    expect(guard.status).toBe('block')
  })

  it('production + hybrid warning verir', () => {
    const config = buildRuntimeConfig({
      environment: 'production',
      apiBaseUrl: 'https://api.pix2pi.com.tr',
      apiTransportMode: 'hybrid',
      appVersion: '0.9.8',
    })

    const guard = evaluateRuntimeSecurityGuard(config)

    expect(guard.status).toBe('warning')
  })

  it('production + live pass verir', () => {
    const config = buildRuntimeConfig({
      environment: 'production',
      apiBaseUrl: 'https://api.pix2pi.com.tr',
      apiTransportMode: 'live',
      appVersion: '0.9.8',
    })

    const guard = evaluateRuntimeSecurityGuard(config)

    expect(guard.status).toBe('pass')
  })
})
