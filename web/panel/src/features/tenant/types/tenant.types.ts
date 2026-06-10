export type TenantItem = {
  id: string
  code: string
  name: string
  status?: 'active' | 'available' | 'unknown'
  description?: string
}

export type TenantContextStatus = 'idle' | 'loading' | 'ready' | 'error'

export type TenantContextResult = {
  currentTenantCode: string
  tenants: TenantItem[]
}
