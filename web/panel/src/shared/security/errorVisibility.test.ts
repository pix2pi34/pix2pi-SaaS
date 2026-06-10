import { describe, expect, it } from 'vitest'
import {
  toSafeErrorMessage,
  toSafeRequestId,
  toSafeRuntimeIssue,
  toSafeSourceLabel,
} from './errorVisibility'

describe('errorVisibility', () => {
  it('401 message guvenli auth metnine doner', () => {
    expect(toSafeErrorMessage('HTTP_401 unauthorized')).toBe(
      'Oturum gecersiz veya suresi dolmus.',
    )
  })

  it('token iceren hata metni gizlenir', () => {
    expect(toSafeErrorMessage('Bearer token invalid')).toBe(
      'Guvenlik nedeniyle teknik hata metni gizlendi.',
    )
  })

  it('runtime issue icindeki url sanitize edilir', () => {
    expect(
      toSafeRuntimeIssue('api base url invalid https://api.example.com'),
    ).toBe('Runtime endpoint konfigurationsunda dikkat gerektiren bir durum var.')
  })

  it('production source etiketi slash varsa runtime.config olur', () => {
    expect(toSafeSourceLabel('https://api.pix2pi.com.tr/auth', 'production')).toBe(
      'runtime.config',
    )
  })

  it('production request id kisaltilir', () => {
    expect(toSafeRequestId('request-id-very-long-123456', 'production')).toBe(
      'request-id-v...'
    )
  })
})
