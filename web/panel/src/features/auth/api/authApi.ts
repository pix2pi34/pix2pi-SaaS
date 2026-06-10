import { API_ENDPOINT_URLS } from '../../../shared/api/config/endpoints'
import { createMockSuccessEnvelope } from '../../../shared/api/client/mockClient'
import {
  apiGetJson,
  apiParseEnvelope,
  apiPostJson,
  buildTenantHeaders,
  resolveApiTransportMode,
  type ApiRequestOptions,
} from '../../../shared/api/client/httpClient'
import {
  buildApiErrorEnvelope,
  shouldUseMockFallback,
} from '../../../shared/api/client/requestPolicy'
import type { ApiEnvelope } from '../../../shared/api/contracts/api.types'
import type {
  AuthLoginResult,
  AuthMeResult,
  AuthSession,
  AuthSignInInput,
  AuthUser,
} from '../types/auth.types'

function normalizeTenantCode(tenantCode: string) {
  const normalized = tenantCode.trim().toUpperCase()
  return normalized || 'TR01'
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null
    ? (value as Record<string, unknown>)
    : null
}

function asString(value: unknown, fallback: string) {
  return typeof value === 'string' && value.trim() ? value : fallback
}

function buildDisplayName(email: string) {
  const left = email.split('@')[0] ?? 'demo'
  const cleaned = left.replace(/[._-]+/g, ' ').trim()
  return cleaned
    ? cleaned
        .split(' ')
        .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
        .join(' ')
    : 'Demo Kullanici'
}

function buildMockLoginResult(input: AuthSignInInput): AuthLoginResult {
  const tenantCode = normalizeTenantCode(input.tenantCode)
  const email = input.email.trim() || 'demo@pix2pi.local'

  return {
    user: {
      id: 'user-demo-1',
      email,
      displayName: buildDisplayName(email),
      role: 'panel_admin',
    },
    session: {
      accessToken: `mock-access-${Math.random().toString(36).slice(2, 10)}`,
      refreshToken: `mock-refresh-${Math.random().toString(36).slice(2, 10)}`,
      tenantCode,
      remember: input.remember,
      source: 'mock',
    },
  }
}

function adaptAuthUser(input: unknown, fallbackEmail: string): AuthUser {
  const root = asRecord(input) ?? {}

  return {
    id: asString(root.id ?? root.user_id, 'user-unknown'),
    email: asString(root.email ?? root.mail, fallbackEmail || 'demo@pix2pi.local'),
    displayName: asString(
      root.display_name ?? root.displayName ?? root.name ?? root.full_name,
      buildDisplayName(fallbackEmail || 'demo@pix2pi.local'),
    ),
    role: asString(root.role ?? root.role_code, 'panel_user'),
  }
}

function adaptAuthSession(
  input: unknown,
  tenantCode: string,
  remember: boolean,
  source: 'mock' | 'real',
): AuthSession {
  const root = asRecord(input) ?? {}
  const normalizedTenant = normalizeTenantCode(
    asString(root.tenant_code ?? root.tenantCode, tenantCode),
  )

  return {
    accessToken: asString(
      root.access_token ?? root.accessToken ?? root.token,
      `fallback-access-${Math.random().toString(36).slice(2, 10)}`,
    ),
    refreshToken: asString(
      root.refresh_token ?? root.refreshToken,
      `fallback-refresh-${Math.random().toString(36).slice(2, 10)}`,
    ),
    tenantCode: normalizedTenant,
    remember,
    source,
  }
}

function adaptLoginResult(input: unknown, formInput: AuthSignInInput): AuthLoginResult {
  const root = asRecord(input) ?? {}
  const data = asRecord(root.data) ?? root
  const userRoot = asRecord(data.user) ?? asRecord(data.me) ?? data
  const sessionRoot = asRecord(data.session) ?? asRecord(data.tokens) ?? data

  const user = adaptAuthUser(userRoot, formInput.email)
  const session = adaptAuthSession(
    sessionRoot,
    formInput.tenantCode,
    formInput.remember,
    'real',
  )

  return { user, session }
}

function adaptMeResult(input: unknown, currentSession: AuthSession): AuthMeResult {
  const root = asRecord(input) ?? {}
  const data = asRecord(root.data) ?? root
  const userRoot = asRecord(data.user) ?? asRecord(data.me) ?? data
  const sessionRoot = asRecord(data.session) ?? asRecord(data.tokens) ?? data

  const user = adaptAuthUser(userRoot, 'demo@pix2pi.local')
  const session = adaptAuthSession(
    sessionRoot,
    currentSession.tenantCode,
    currentSession.remember,
    'real',
  )

  return { user, session }
}

async function createMockLoginEnvelope(input: AuthSignInInput) {
  const data = buildMockLoginResult(input)

  return createMockSuccessEnvelope({
    data,
    source: 'auth.contract.mock',
    requestPrefix: 'auth-login',
  })
}

export async function authLogin(
  input: AuthSignInInput,
  options: ApiRequestOptions = {},
): Promise<ApiEnvelope<AuthLoginResult>> {
  const mode = resolveApiTransportMode(options.transportMode)

  if (mode === 'mock') {
    return createMockLoginEnvelope(input)
  }

  try {
    const raw = await apiPostJson<unknown, Record<string, unknown>>(
      API_ENDPOINT_URLS.authLogin,
      {
        email: input.email.trim(),
        password: input.password,
        tenant_code: normalizeTenantCode(input.tenantCode),
        remember: input.remember,
      },
      {
        ...options,
        headers: {
          ...buildTenantHeaders(input.tenantCode),
          ...(options.headers ?? {}),
        },
      },
    )

    const envelope = apiParseEnvelope<unknown>(raw, 'auth.contract.real')

    if (!envelope.success) {
      return envelope
    }

    return {
      success: true,
      data: adaptLoginResult(envelope.data, input),
      meta: envelope.meta,
    }
  } catch (error) {
    if (shouldUseMockFallback(mode, error)) {
      return createMockLoginEnvelope(input)
    }

    return buildApiErrorEnvelope(
      `auth.contract.${mode}`,
      error,
      'auth-login-error',
      'AUTH',
    )
  }
}

export async function authMe(
  session: AuthSession,
  options: ApiRequestOptions = {},
): Promise<ApiEnvelope<AuthMeResult>> {
  const mode = resolveApiTransportMode(options.transportMode)

  if (mode === 'mock') {
    const data: AuthMeResult = {
      user: {
        id: 'user-demo-1',
        email: 'demo@pix2pi.local',
        displayName: 'Demo Kullanici',
        role: 'panel_admin',
      },
      session,
    }

    return createMockSuccessEnvelope({
      data,
      source: 'auth.me.mock',
      requestPrefix: 'auth-me',
    })
  }

  try {
    const raw = await apiGetJson<unknown>(API_ENDPOINT_URLS.authMe, {
      ...options,
      headers: {
        Authorization: `Bearer ${session.accessToken}`,
        ...buildTenantHeaders(session.tenantCode),
        ...(options.headers ?? {}),
      },
    })

    const envelope = apiParseEnvelope<unknown>(raw, 'auth.me.real')

    if (!envelope.success) {
      return envelope
    }

    return {
      success: true,
      data: adaptMeResult(envelope.data, session),
      meta: envelope.meta,
    }
  } catch (error) {
    if (shouldUseMockFallback(mode, error)) {
      const data: AuthMeResult = {
        user: {
          id: 'user-demo-1',
          email: 'demo@pix2pi.local',
          displayName: 'Demo Kullanici',
          role: 'panel_admin',
        },
        session: {
          ...session,
          source: 'mock',
        },
      }

      return createMockSuccessEnvelope({
        data,
        source: 'auth.me.mock',
        requestPrefix: 'auth-me',
      })
    }

    return buildApiErrorEnvelope(
      `auth.me.${mode}`,
      error,
      'auth-me-error',
      'AUTH',
    )
  }
}
