import { beforeEach, describe, expect, it } from 'vitest'
import {
  LOCAL_STORAGE_KEY,
  SESSION_STORAGE_KEY,
  clearStoredBundle,
  getStoredBundleSource,
  persistBundle,
  readStoredBundle,
} from './authStorage'
import type { StoredAuthBundle } from '../types/auth.types'

function buildBundle(remember: boolean): StoredAuthBundle {
  return {
    user: {
      id: 'user-1',
      email: 'demo@pix2pi.local',
      displayName: 'Demo Kullanici',
      role: 'panel_admin',
    },
    session: {
      accessToken: 'token-1',
      refreshToken: 'token-2',
      tenantCode: 'TR01',
      remember,
      source: 'real',
    },
  }
}

describe('authStorage', () => {
  beforeEach(() => {
    window.localStorage.clear()
    window.sessionStorage.clear()
  })

  it('remember true ise localStorage kullanir', () => {
    persistBundle(buildBundle(true))

    expect(getStoredBundleSource()).toBe('local')
    expect(window.localStorage.getItem(LOCAL_STORAGE_KEY)).not.toBeNull()
    expect(window.sessionStorage.getItem(SESSION_STORAGE_KEY)).toBeNull()
  })

  it('remember false ise sessionStorage kullanir', () => {
    persistBundle(buildBundle(false))

    expect(getStoredBundleSource()).toBe('session')
    expect(window.sessionStorage.getItem(SESSION_STORAGE_KEY)).not.toBeNull()
    expect(window.localStorage.getItem(LOCAL_STORAGE_KEY)).toBeNull()
  })

  it('malformed bundle varsa temizler', () => {
    window.localStorage.setItem(LOCAL_STORAGE_KEY, '{broken-json')

    expect(readStoredBundle()).toBeNull()
    expect(window.localStorage.getItem(LOCAL_STORAGE_KEY)).toBeNull()
  })

  it('clearStoredBundle iki storage alanini da temizler', () => {
    window.localStorage.setItem(LOCAL_STORAGE_KEY, 'x')
    window.sessionStorage.setItem(SESSION_STORAGE_KEY, 'y')

    clearStoredBundle()

    expect(window.localStorage.getItem(LOCAL_STORAGE_KEY)).toBeNull()
    expect(window.sessionStorage.getItem(SESSION_STORAGE_KEY)).toBeNull()
  })
})
