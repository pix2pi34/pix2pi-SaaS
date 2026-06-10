# LVL7 UI Surface Manifest

## V1 sabit endpoint seti
- GET /api/v1/auth/me
- GET /api/v1/tenant/current
- GET /api/v1/dashboard/summary
- GET /api/v1/monitoring/warnings
- GET /api/v1/monitoring/alerts
- GET /api/v1/erp/event-summary
- GET /api/v1/health/summary

---

## Endpoint listesi

### GET /api/v1/auth/me
Amaç:
- aktif kullanıcı ve claim bilgisi

Auth:
- zorunlu

Tenant:
- token/context üzerinden gelir

Response alanları:
- user_id
- email
- tenant_id
- tenant_uuid
- roles
- permissions

### GET /api/v1/tenant/current
Amaç:
- aktif tenant bağlamı

Auth:
- zorunlu

Tenant:
- zorunlu

Response alanları:
- tenant_id
- tenant_uuid
- tenant_name
- plan_code
- status

### GET /api/v1/dashboard/summary
Amaç:
- ilk panel üst kart özetleri

Auth:
- zorunlu

Tenant:
- zorunlu

Response alanları:
- cards[]:
  - key
  - label
  - value

### GET /api/v1/monitoring/warnings
Amaç:
- early warning listesi

Auth:
- zorunlu

Tenant:
- zorunlu

Response alanları:
- items[]:
  - signal_type
  - source
  - severity
  - metric_key
  - metric_value
  - message
  - observed_at

### GET /api/v1/monitoring/alerts
Amaç:
- observability/security/ops alert listesi

Auth:
- zorunlu

Tenant:
- zorunlu

Response alanları:
- items[]:
  - kind
  - signal_type
  - source
  - severity
  - metric_key
  - message
  - observed_at

### GET /api/v1/erp/event-summary
Amaç:
- ERP/event hattı kısa sağlık özeti

Auth:
- zorunlu

Tenant:
- zorunlu

Response alanları:
- event_store_status
- replay_status
- dlq_depth
- retry_pressure
- last_event_at

### GET /api/v1/health/summary
Amaç:
- servis sağlık kısa özeti

Auth:
- zorunlu

Tenant:
- zorunlu

Response alanları:
- services[]:
  - name
  - status
  - latency_ms

---

## Kararlar
- tum endpointler GET
- tum endpointler /api/v1 altinda
- ilk UI icin read-only yuzey
- tenant bagli endpointlerde tenant context zorunlu
- write endpointler bu fazda yok
