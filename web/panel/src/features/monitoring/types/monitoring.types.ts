export type HealthTone = 'healthy' | 'degraded' | 'warning'

export type HealthCard = {
  id: string
  label: string
  value: string
  detail: string
  tone: HealthTone
}

export type ServiceStatus = {
  id: string
  service: string
  status: 'UP' | 'DEGRADED' | 'PENDING'
  latency: string
  lastCheck: string
}

export type WarningItem = {
  id: string
  title: string
  detail: string
  level: 'medium' | 'high'
}

export type TimelineItem = {
  id: string
  title: string
  detail: string
  time: string
}
