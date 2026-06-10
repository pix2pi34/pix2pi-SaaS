export type AuthStatus = 'signed_out' | 'loading' | 'signed_in'

export type AuthSource = 'mock' | 'real'

export type AuthUser = {
  id: string
  email: string
  displayName: string
  role: string
}

export type AuthSession = {
  accessToken: string
  refreshToken: string
  tenantCode: string
  remember: boolean
  source: AuthSource
}

export type StoredAuthBundle = {
  user: AuthUser
  session: AuthSession
}

export type AuthSignInInput = {
  email: string
  password: string
  tenantCode: string
  remember: boolean
}

export type AuthLoginResult = {
  user: AuthUser
  session: AuthSession
}

export type AuthMeResult = {
  user: AuthUser
  session: AuthSession
}
