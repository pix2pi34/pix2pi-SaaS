# Pix2pi Port Registry (Single Source of Truth)

> Bu dosya: Port çakışması yaşamamak için **tek kaynak**tır.
> Yeni servis eklerken önce buraya yaz, sonra compose/env’e uygula.

## App Ports (Go & Core)
- 9010  API Gateway
- 9011  dev-token (HTTP, only localhost)
- 9012  Identity API
- 9027  Customer Service

## Node.js Services
- 9024, 9036, 9037, 9038, 9039, 9044  Customer Register / Login & Owner Approvals

## Python Services
- 9344, 9345, 9352, 9353, 9357  Document AI / Machine Learning

## Data & Event Bus
- 5432  PostgreSQL (Primary/Replica)
- 6379  Redis
- 4222, 8222  NATS / JetStream

## Observability
- 3000  Grafana
- 3100  Loki
- 3200  Tempo
- 8080  cAdvisor
- 9090  Prometheus
- 9100  Node Exporter

## Kurallar
1) Aynı port iki servise verilmez.  
2) dev-token **sadece 127.0.0.1** bind eder (dışarı açılmaz).  
3) Değişiklik olursa: PORTS.md + deploy/ports.env birlikte güncellenir.
