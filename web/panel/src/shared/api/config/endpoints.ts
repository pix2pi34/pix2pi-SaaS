import { joinApiUrl, readRuntimeConfig } from '../../runtime/runtimeConfig'

export const API_ENDPOINTS = {
  authLogin: '/api/v1/auth/login',
  authMe: '/api/v1/auth/me',
  dashboardSummary: '/api/v1/dashboard/summary',
  healthSummary: '/api/v1/health/summary',
  monitoringWarnings: '/api/v1/monitoring/warnings',
  tenantContext: '/api/v1/tenant/context',
} as const

export function buildApiEndpointUrls(baseUrl: string) {
  return {
    authLogin: joinApiUrl(baseUrl, API_ENDPOINTS.authLogin),
    authMe: joinApiUrl(baseUrl, API_ENDPOINTS.authMe),
    dashboardSummary: joinApiUrl(baseUrl, API_ENDPOINTS.dashboardSummary),
    healthSummary: joinApiUrl(baseUrl, API_ENDPOINTS.healthSummary),
    monitoringWarnings: joinApiUrl(baseUrl, API_ENDPOINTS.monitoringWarnings),
    tenantContext: joinApiUrl(baseUrl, API_ENDPOINTS.tenantContext),
  } as const
}

export const API_ENDPOINT_URLS = buildApiEndpointUrls(readRuntimeConfig().apiBaseUrl)
