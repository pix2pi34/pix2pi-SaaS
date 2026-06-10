import type {
  HealthCard,
  ServiceStatus,
  TimelineItem,
  WarningItem,
} from '../types/monitoring.types'

export type MonitoringContractData = {
  cards: HealthCard[]
  services: ServiceStatus[]
  warnings: WarningItem[]
  timeline: TimelineItem[]
}
