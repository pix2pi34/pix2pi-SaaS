export type ApiSuccessEnvelope<T> = {
  success: true
  data: T
  meta: {
    requestId: string
    timestamp: string
    source: string
  }
}

export type ApiErrorEnvelope = {
  success: false
  error: {
    code: string
    message: string
  }
  meta: {
    requestId: string
    timestamp: string
    source: string
  }
}

export type ApiEnvelope<T> = ApiSuccessEnvelope<T> | ApiErrorEnvelope

export type ContractStateStatus = 'idle' | 'loading' | 'success' | 'error'

export type ContractState<T> = {
  status: ContractStateStatus
  data: T | null
  errorMessage: string
  requestId: string
  source: string
}
