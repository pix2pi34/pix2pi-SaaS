export function toSafeErrorMessage(message: string) {
  const raw = (message ?? '').trim()

  if (!raw) {
    return 'Beklenmeyen bir hata olustu.'
  }

  const lower = raw.toLowerCase()

  if (lower.includes('unauthorized') || lower.includes('401')) {
    return 'Oturum gecersiz veya suresi dolmus.'
  }

  if (lower.includes('forbidden') || lower.includes('403')) {
    return 'Bu islem icin yetkiniz yok.'
  }

  if (lower.includes('timeout')) {
    return 'Istek zaman asimina ugradi. Lutfen tekrar deneyin.'
  }

  if (lower.includes('network') || lower.includes('fetch')) {
    return 'Baglanti hatasi olustu. Lutfen tekrar deneyin.'
  }

  if (lower.includes('token') || lower.includes('bearer') || lower.includes('authorization')) {
    return 'Guvenlik nedeniyle teknik hata metni gizlendi.'
  }

  if (lower.includes('invalid json') || lower.includes('parse')) {
    return 'Sunucudan beklenmeyen cevap alindi.'
  }

  return raw
}

export function toSafeRuntimeIssue(issue: string) {
  const raw = (issue ?? '').trim()

  if (!raw) {
    return 'Guvenlik uyarisi bulunamadi.'
  }

  const lower = raw.toLowerCase()

  if (lower.includes('token') || lower.includes('bearer') || lower.includes('authorization')) {
    return 'Guvenlik nedeniyle hassas runtime detayi gizlendi.'
  }

  if (lower.includes('http://') || lower.includes('https://')) {
    return 'Runtime endpoint konfigurationsunda dikkat gerektiren bir durum var.'
  }

  return raw
}

export function toSafeSourceLabel(source: string, environment: string) {
  const raw = (source ?? '').trim()

  if (!raw) {
    return 'unknown'
  }

  if (environment === 'production' && raw.includes('/')) {
    return 'runtime.config'
  }

  return raw
}

export function toSafeRequestId(requestId: string, environment: string) {
  const raw = (requestId ?? '').trim()

  if (!raw) {
    return ''
  }

  if (environment === 'production' && raw.length > 12) {
    return `${raw.slice(0, 12)}...`
  }

  return raw
}
