import type {
  DashboardAction,
  DashboardActivity,
  DashboardMetric,
} from '../types/dashboard.types'

export type DashboardSummaryCard = {
  id: string
  label: string
  value: string
  detail: string
}

export type DashboardContractData = {
  metrics: DashboardMetric[]
  activities: DashboardActivity[]
  actions: DashboardAction[]
  summaryCards: DashboardSummaryCard[]
}
