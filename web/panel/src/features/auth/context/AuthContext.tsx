import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type PropsWithChildren,
} from 'react'
import { authLogin, authMe } from '../api/authApi'
import type {
  AuthSession,
  AuthSignInInput,
  AuthStatus,
  AuthUser,
} from '../types/auth.types'
import {
  clearStoredBundle,
  persistBundle,
  readStoredBundle,
} from '../utils/authStorage'

type AuthContextValue = {
  status: AuthStatus
  user: AuthUser | null
  session: AuthSession | null
  errorCode: string
  errorMessage: string
  errorRequestId: string
  errorSource: string
  canRetryAuthMe: boolean
  signIn: (input: AuthSignInInput) => Promise<boolean>
  signOut: () => void
  refreshSession: () => Promise<void>
  retryAuthMe: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

function shouldKeepRecoverableSession(errorCode: string) {
  return errorCode === 'AUTH_UNAUTHORIZED'
}

export function AuthProvider({ children }: PropsWithChildren) {
  const [status, setStatus] = useState<AuthStatus>('signed_out')
  const [user, setUser] = useState<AuthUser | null>(null)
  const [session, setSession] = useState<AuthSession | null>(null)
  const [recoverableSession, setRecoverableSession] = useState<AuthSession | null>(null)
  const [errorCode, setErrorCode] = useState('')
  const [errorMessage, setErrorMessage] = useState('')
  const [errorRequestId, setErrorRequestId] = useState('')
  const [errorSource, setErrorSource] = useState('')
  const requestSequenceRef = useRef(0)

  function resetSensitiveSessionState() {
    setUser(null)
    setSession(null)
  }

  function resetErrorState() {
    setErrorCode('')
    setErrorMessage('')
    setErrorRequestId('')
    setErrorSource('')
  }

  function applyAuthFailure(input: {
    code: string
    message: string
    requestId: string
    source: string
    recoverableSession: AuthSession | null
    clearStorage: boolean
  }) {
    setStatus('signed_out')
    resetSensitiveSessionState()
    setRecoverableSession(input.recoverableSession)
    setErrorCode(input.code)
    setErrorMessage(input.message)
    setErrorRequestId(input.requestId)
    setErrorSource(input.source)

    if (input.clearStorage) {
      clearStoredBundle()
    }
  }

  useEffect(() => {
    let isMounted = true

    const stored = readStoredBundle()

    if (!stored) {
      return () => {
        isMounted = false
      }
    }

    const requestSequence = ++requestSequenceRef.current

    setUser(stored.user)
    setSession(stored.session)
    setRecoverableSession(null)
    setStatus('signed_in')
    resetErrorState()

    void authMe(stored.session)
      .then((response) => {
        if (!isMounted || requestSequence !== requestSequenceRef.current) {
          return
        }

        if (!response.success) {
          applyAuthFailure({
            code: response.error.code,
            message: response.error.message,
            requestId: response.meta.requestId,
            source: response.meta.source,
            recoverableSession: shouldKeepRecoverableSession(response.error.code)
              ? stored.session
              : null,
            clearStorage: true,
          })
          return
        }

        setUser(response.data.user)
        setSession(response.data.session)
        setRecoverableSession(null)
        setStatus('signed_in')
        resetErrorState()
        persistBundle({
          user: response.data.user,
          session: response.data.session,
        })
      })
      .catch(() => {
        if (!isMounted || requestSequence !== requestSequenceRef.current) {
          return
        }

        applyAuthFailure({
          code: 'AUTH_CONTEXT_ERROR',
          message: 'Session restore basarisiz.',
          requestId: '',
          source: 'auth.context.provider',
          recoverableSession: stored.session,
          clearStorage: true,
        })
      })

    return () => {
      isMounted = false
    }
  }, [])

  async function signIn(input: AuthSignInInput) {
    const requestSequence = ++requestSequenceRef.current

    setStatus('loading')
    resetErrorState()
    setRecoverableSession(null)

    const response = await authLogin(input)

    if (requestSequence !== requestSequenceRef.current) {
      return false
    }

    if (!response.success) {
      applyAuthFailure({
        code: response.error.code,
        message: response.error.message,
        requestId: response.meta.requestId,
        source: response.meta.source,
        recoverableSession: null,
        clearStorage: true,
      })
      return false
    }

    setUser(response.data.user)
    setSession(response.data.session)
    setRecoverableSession(null)
    setStatus('signed_in')
    resetErrorState()
    persistBundle({
      user: response.data.user,
      session: response.data.session,
    })

    return true
  }

  async function refreshSession() {
    if (!session) {
      return
    }

    const requestSequence = ++requestSequenceRef.current

    setStatus('loading')
    resetErrorState()

    const response = await authMe(session)

    if (requestSequence !== requestSequenceRef.current) {
      return
    }

    if (!response.success) {
      applyAuthFailure({
        code: response.error.code,
        message: response.error.message,
        requestId: response.meta.requestId,
        source: response.meta.source,
        recoverableSession: shouldKeepRecoverableSession(response.error.code)
          ? session
          : null,
        clearStorage: true,
      })
      return
    }

    setUser(response.data.user)
    setSession(response.data.session)
    setRecoverableSession(null)
    setStatus('signed_in')
    resetErrorState()
    persistBundle({
      user: response.data.user,
      session: response.data.session,
    })
  }

  async function retryAuthMe() {
    const targetSession = session ?? recoverableSession

    if (!targetSession) {
      return
    }

    const requestSequence = ++requestSequenceRef.current

    setStatus('loading')
    resetErrorState()

    const response = await authMe(targetSession)

    if (requestSequence !== requestSequenceRef.current) {
      return
    }

    if (!response.success) {
      applyAuthFailure({
        code: response.error.code,
        message: response.error.message,
        requestId: response.meta.requestId,
        source: response.meta.source,
        recoverableSession: shouldKeepRecoverableSession(response.error.code)
          ? targetSession
          : null,
        clearStorage: true,
      })
      return
    }

    setUser(response.data.user)
    setSession(response.data.session)
    setRecoverableSession(null)
    setStatus('signed_in')
    resetErrorState()
    persistBundle({
      user: response.data.user,
      session: response.data.session,
    })
  }

  function signOut() {
    requestSequenceRef.current += 1
    setStatus('signed_out')
    resetSensitiveSessionState()
    setRecoverableSession(null)
    resetErrorState()
    clearStoredBundle()
  }

  const value = useMemo<AuthContextValue>(
    () => ({
      status,
      user,
      session,
      errorCode,
      errorMessage,
      errorRequestId,
      errorSource,
      canRetryAuthMe: Boolean(recoverableSession || session),
      signIn,
      signOut,
      refreshSession,
      retryAuthMe,
    }),
    [
      status,
      user,
      session,
      recoverableSession,
      errorCode,
      errorMessage,
      errorRequestId,
      errorSource,
    ],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)

  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }

  return context
}
