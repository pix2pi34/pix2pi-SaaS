import { describe, expect, it } from 'vitest'
import {
  buildRuntimeConfig,
  joinApiUrl,
  sanitizeApiBaseUrl,
} from './runtimeConfig'

describe('runtimeConfig', () => {
  it('bos env durumunda fallback config uretir', () => {
    const config = buildRuntimeConfig({})

    expect(config.environment).toBe('development')
    expect(config.apiBaseUrl).toBe('/api')
    expect(config.apiTransportMode).toBe('hybrid')
    expect(config.configStatus).toBe('warning')
    expect(config.configIssues.length).toBeGreaterThan(0)
  })

  it('invalid transport mode hybrid fallbacke duser', () => {
    const config = buildRuntimeConfig({
      apiTransportMode: 'broken-mode',
    })

    expect(config.apiTransportMode).toBe('hybrid')
    expect(config.configIssues.join(' ')).toContain('transport mode invalid')
  })

  it('invalid api base url /api fallbacke duser', () => {
    const result = sanitizeApiBaseUrl('pix2pi-api')

    expect(result.value).toBe('/api')
    expect(result.issue).toContain('api base url invalid')
  })

  it('absolute base url ve endpoint dogru birlesir', () => {
    expect(joinApiUrl('https://api.pix2pi.com.tr/', '/api/v1/auth/me')).toBe(
      'https://api.pix2pi.com.tr/api/v1/auth/me',
    )
  })

  it('relative base url ve endpoint double slash olusturmaz', () => {
    expect(joinApiUrl('/api/', '/v1/dashboard/summary')).toBe(
      '/api/v1/dashboard/summary',
    )
  })

  it('production ortaminda mock transport warning verir', () => {
    const config = buildRuntimeConfig({
      environment: 'production',
      apiTransportMode: 'mock',
      apiBaseUrl: 'https://api.pix2pi.com.tr',
    })

    expect(config.configStatus).toBe('warning')
    expect(config.configIssues.join(' ')).toContain('production ortaminda mock transport kullaniliyor')
  })
})
