import type { ServiceStatus } from '../types/monitoring.types'

type MonitoringServiceStatusTableProps = {
  services: ServiceStatus[]
}

export function MonitoringServiceStatusTable({
  services,
}: MonitoringServiceStatusTableProps) {
  return (
    <section className="surface monitoring-section">
      <div className="section-head-row">
        <div>
          <p className="meta-label">servis durumu</p>
          <h2 className="section-title">Service status table</h2>
        </div>
      </div>

      <div className="service-status-table">
        <div className="service-status-head">
          <span>Servis</span>
          <span>Durum</span>
          <span>Latency</span>
          <span>Son kontrol</span>
        </div>

        {services.map((service) => (
          <div key={service.id} className="service-status-row">
            <strong>{service.service}</strong>
            <span className={`service-status-pill service-status-pill-${service.status.toLowerCase()}`}>
              {service.status}
            </span>
            <span>{service.latency}</span>
            <span>{service.lastCheck}</span>
          </div>
        ))}
      </div>
    </section>
  )
}
