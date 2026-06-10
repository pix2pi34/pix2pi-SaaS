import type { StoredAuthBundle } from '../types/auth.types'

export const LOCAL_STORAGE_KEY = 'pix2pi.auth.local.v1'
export const SESSION_STORAGE_KEY = 'pix2pi.auth.session.v1'

export type StoredBundleSource = 'local' | 'session' | null

export function hasBrowserStorage() {
  return (
    typeof window !== 'undefined' &&
    typeof window.localStorage !== 'undefined' &&
    typeof window.sessionStorage !== 'undefined'
  )
}

export function clearStoredBundle() {
  if (!hasBrowserStorage()) {
    return
  }

  window.localStorage.removeItem(LOCAL_STORAGE_KEY)
  window.sessionStorage.removeItem(SESSION_STORAGE_KEY)
}

export function getStoredBundleSource(): StoredBundleSource {
  if (!hasBrowserStorage()) {
    return null
  }

  if (window.localStorage.getItem(LOCAL_STORAGE_KEY)) {
    return 'local'
  }

  if (window.sessionStorage.getItem(SESSION_STORAGE_KEY)) {
    return 'session'
  }

  return null
}

function isValidStoredBundle(value: unknown): value is StoredAuthBundle {
  if (!value || typeof value !== 'object') {
    return false
  }

  const root = value as Record<string, unknown>
  const user = root.user as Record<string, unknown> | undefined
  const session = root.session as Record<string, unknown> | undefined

  return Boolean(
    user &&
      session &&
      typeof user.email === 'string' &&
      typeof session.accessToken === 'string' &&
      typeof session.tenantCode === 'string',
  )
}

export function readStoredBundle(): StoredAuthBundle | null {
  if (!hasBrowserStorage()) {
    return null
  }

  const candidates = [
    window.localStorage.getItem(LOCAL_STORAGE_KEY),
    window.sessionStorage.getItem(SESSION_STORAGE_KEY),
  ]

  for (const raw of candidates) {
    if (!raw) {
      continue
    }

    try {
      const parsed = JSON.parse(raw) as unknown

      if (isValidStoredBundle(parsed)) {
        return parsed
      }
    } catch {
      // malformed bundle => continue and cleanup below
    }
  }

  clearStoredBundle()
  return null
}

export function persistBundle(bundle: StoredAuthBundle) {
  if (!hasBrowserStorage()) {
    return
  }

  const payload = JSON.stringify(bundle)

  clearStoredBundle()

  if (bundle.session.remember) {
    window.localStorage.setItem(LOCAL_STORAGE_KEY, payload)
    return
  }

  window.sessionStorage.setItem(SESSION_STORAGE_KEY, payload)
}
