import { API_ENDPOINT_URLS } from '../../../shared/api/config/endpoints'
import { createMockSuccessEnvelope } from '../../../shared/api/client/mockClient'
import {
  apiGetJson,
  apiParseEnvelope,
  buildTenantHeaders,
  resolveApiTransportMode,
  type ApiRequestOptions,
} from '../../../shared/api/client/httpClient'
import {
  buildApiErrorEnvelope,
  executeRequestWithRetry,
  shouldUseMockFallback,
} from '../../../shared/api/client/requestPolicy'
import type { ApiEnvelope } from '../../../shared/api/contracts/api.types'
import type { AuthSession } from '../../auth/types/auth.types'
import type { TenantContextResult, TenantItem } from '../types/tenant.types'

function normalizeTenantCode(code: string | undefined) {
  const normalized = typeof code === 'string' ? code.trim().toUpperCase() : ''
  return normalized || 'TR01'
}

function isValidTenantCode(code: string) {
  return /^TR[0-9]{2}(?:-[A-Z0-9]+)*$/.test(code)
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null
    ? (value as Record<string, unknown>)
    : null
}

function asString(value: unknown, fallback: string) {
  return typeof value === 'string' && value.trim() ? value : fallback
}

function toRecordArray(value: unknown): Record<string, unknown>[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value.filter(
    (item): item is Record<string, unknown> =>
      typeof item === 'object' && item !== null,
  )
}

function buildDefaultTenantName(code: string) {
  if (code === 'TR01') {
    return 'TR01 Merkez'
  }

  if (code === 'TR01-FIN') {
    return 'TR01 Finans'
  }

  if (code === 'TR01-OPS') {
    return 'TR01 Operasyon'
  }

  return `${code} Tenant`
}

function buildTenantItem(code: string, name?: string, status?: TenantItem['status']): TenantItem {
  const normalized = normalizeTenantCode(code)

  return {
    id: normalized.toLowerCase(),
    code: normalized,
    name: name?.trim() || buildDefaultTenantName(normalized),
    status: status ?? 'available',
  }
}

function buildMockTenantContext(tenantCode: string): TenantContextResult {
  const requested = normalizeTenantCode(tenantCode)
  const base: TenantItem[] = [
    buildTenantItem('TR01', 'TR01 Merkez', requested === 'TR01' ? 'active' : 'available'),
    buildTenantItem('TR01-FIN', 'TR01 Finans', requested === 'TR01-FIN' ? 'active' : 'available'),
    buildTenantItem('TR01-OPS', 'TR01 Operasyon', requested === 'TR01-OPS' ? 'active' : 'available'),
  ]

  const exists = base.some((item) => item.code === requested)

  if (!exists) {
    base.unshift(buildTenantItem(requested, buildDefaultTenantName(requested), 'active'))
  }

  return {
    currentTenantCode: requested,
    tenants: base.map((item) => ({
      ...item,
      status: item.code === requested ? 'active' : 'available',
    })),
  }
}

function mapTenantItem(input: Record<string, unknown>, fallbackCode: string): TenantItem {
  const code = normalizeTenantCode(
    asString(input.code ?? input.tenant_code ?? input.slug, fallbackCode),
  )

  return {
    id: asString(input.id, code.toLowerCase()),
    code,
    name: asString(
      input.name ?? input.display_name ?? input.title,
      buildDefaultTenantName(code),
    ),
    status: (asString(input.status ?? input.state, 'available') as TenantItem['status']) ?? 'available',
    description: asString(input.description ?? input.detail, ''),
  }
}

function pickTenantArray(
  root: Record<string, unknown>,
): { items: Record<string, unknown>[]; explicit: boolean } {
  for (const key of ['tenants', 'items', 'available_tenants', 'tenant_list']) {
    if (key in root) {
      return {
        items: toRecordArray(root[key]),
        explicit: true,
      }
    }
  }

  return {
    items: [],
    explicit: false,
  }
}

function mapTenantContext(
  input: unknown,
  requestedTenantCode: string,
): TenantContextResult {
  const requested = normalizeTenantCode(requestedTenantCode)
  const root = asRecord(input) ?? {}
  const data = asRecord(root.data) ?? root
  const explicitEmpty = data.empty === true || data.no_data === true

  if (explicitEmpty) {
    return {
      currentTenantCode: '',
      tenants: [],
    }
  }

  const currentRoot =
    asRecord(data.current_tenant) ??
    asRecord(data.currentTenant) ??
    asRecord(data.active_tenant) ??
    asRecord(data.tenant)

  const currentCode = normalizeTenantCode(
    asString(
      currentRoot?.code ??
        currentRoot?.tenant_code ??
        data.current_tenant_code ??
        data.currentTenantCode,
      requested,
    ),
  )

  const picked = pickTenantArray(data)

  if (picked.explicit && picked.items.length === 0) {
    return {
      currentTenantCode: currentCode,
      tenants: [buildTenantItem(currentCode, buildDefaultTenantName(currentCode), 'active')],
    }
  }

  const mapped =
    picked.items.length > 0
      ? picked.items.map((item) => mapTenantItem(item, requested))
      : buildMockTenantContext(currentCode).tenants

  const exists = mapped.some((item) => item.code === currentCode)
  const tenants = exists
    ? mapped
    : [buildTenantItem(currentCode, buildDefaultTenantName(currentCode), 'active'), ...mapped]

  return {
    currentTenantCode: currentCode,
    tenants: tenants.map((item) => ({
      ...item,
      status: item.code === currentCode ? 'active' : 'available',
    })),
  }
}

function validateTenantContextSecurity(
  requestedTenantCode: string,
  mapped: TenantContextResult,
): { ok: true } | { ok: false; code: string; message: string } {
  const requested = normalizeTenantCode(requestedTenantCode)

  if (!isValidTenantCode(requested)) {
    return {
      ok: false,
      code: 'TENANT_CONTEXT_INVALID_TENANT',
      message: 'Gecersiz tenant kodu.',
    }
  }

  if (!mapped.currentTenantCode && mapped.tenants.length === 0) {
    return { ok: true }
  }

  if (mapped.currentTenantCode !== requested) {
    return {
      ok: false,
      code: 'TENANT_CONTEXT_MISMATCH',
      message: 'Backend tenant baglami istenen tenant ile eslesmiyor.',
    }
  }

  const leakedTenant = mapped.tenants.find((item) => item.code !== requested)

  if (leakedTenant) {
    return {
      ok: false,
      code: 'TENANT_CONTEXT_CROSS_TENANT_LEAK',
      message: 'Cevap icinde istenmeyen tenant verisi bulundu.',
    }
  }

  return { ok: true }
}

function buildTenantApiErrorEnvelope(error: unknown) {
  if (error instanceof Error && error.message === 'HTTP_401') {
    return {
      success: false as const,
      error: {
        code: 'TENANT_CONTEXT_UNAUTHORIZED',
        message: 'Tenant context istegi icin oturum gecersiz.',
      },
      meta: {
        requestId: `tenant-context-error-${Math.random().toString(36).slice(2, 10)}`,
        timestamp: new Date().toISOString(),
        source: 'tenant.context.live',
      },
    }
  }

  if (error instanceof Error && error.message === 'HTTP_403') {
    return {
      success: false as const,
      error: {
        code: 'TENANT_CONTEXT_FORBIDDEN',
        message: 'Bu tenant baglamina erisiminiz yok.',
      },
      meta: {
        requestId: `tenant-context-error-${Math.random().toString(36).slice(2, 10)}`,
        timestamp: new Date().toISOString(),
        source: 'tenant.context.live',
      },
    }
  }

  return buildApiErrorEnvelope(
    'tenant.context.live',
    error,
    'tenant-context-error',
    'TENANT_CONTEXT',
  )
}

async function createMockTenantEnvelope(tenantCode: string) {
  const data = buildMockTenantContext(tenantCode)

  return createMockSuccessEnvelope({
    data,
    source: 'tenant.context.mock',
    requestPrefix: 'tenant-context',
  })
}

export async function fetchTenantContext(
  session: AuthSession,
  options: ApiRequestOptions = {},
): Promise<ApiEnvelope<TenantContextResult>> {
  const mode = resolveApiTransportMode(options.transportMode)
  const normalizedTenantCode = normalizeTenantCode(session.tenantCode)

  if (mode === 'live' && !isValidTenantCode(normalizedTenantCode)) {
    return {
      success: false,
      error: {
        code: 'TENANT_CONTEXT_INVALID_TENANT',
        message: 'Gecersiz tenant kodu.',
      },
      meta: {
        requestId: `tenant-invalid-${Math.random().toString(36).slice(2, 10)}`,
        timestamp: new Date().toISOString(),
        source: 'tenant.context.live',
      },
    }
  }

  if (mode === 'mock') {
    return createMockTenantEnvelope(normalizedTenantCode)
  }

  try {
    const raw = await executeRequestWithRetry(
      () =>
        apiGetJson<unknown>(API_ENDPOINT_URLS.tenantContext, {
          ...options,
          headers: {
            Authorization: `Bearer ${session.accessToken}`,
            ...buildTenantHeaders(normalizedTenantCode),
            ...(options.headers ?? {}),
          },
        }),
      {
        method: 'GET',
        maxRetries: options.maxRetries,
        retryDelayMs: options.retryDelayMs,
      },
    )

    const envelope = apiParseEnvelope<unknown>(raw, 'tenant.context.real')

    if (!envelope.success) {
      return envelope
    }

    const mapped = mapTenantContext(envelope.data, normalizedTenantCode)

    if (mode === 'live') {
      const security = validateTenantContextSecurity(normalizedTenantCode, mapped)

      if (!security.ok) {
        return {
          success: false,
          error: {
            code: security.code,
            message: security.message,
          },
          meta: envelope.meta,
        }
      }
    }

    return {
      success: true,
      data: mapped,
      meta: envelope.meta,
    }
  } catch (error) {
    if (shouldUseMockFallback(mode, error)) {
      return createMockTenantEnvelope(normalizedTenantCode)
    }

    return buildTenantApiErrorEnvelope(error)
  }
}
