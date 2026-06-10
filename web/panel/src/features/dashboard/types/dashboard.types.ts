export type DashboardMetric = {
  id: string
  label: string
  value: string
  delta: string
  tone: 'good' | 'neutral' | 'warn'
}

export type DashboardActivity = {
  id: string
  title: string
  detail: string
  time: string
  state: 'ok' | 'pending' | 'attention'
}

export type DashboardAction = {
  id: string
  title: string
  detail: string
  state: 'ready' | 'next'
}
