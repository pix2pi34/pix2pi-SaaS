# FAZ 3 / STEP 13.1F — Gateway ERP Runtime Service Factory

## Amaç

Gerçek Gateway wiring öncesinde ERP Runtime API service üretimini gateway paketi içinde hazır hale getirmek.

## Eklenen Dosyalar

- `cmd/api-gateway/erp_runtime_service_factory.go`
- `cmd/api-gateway/erp_runtime_service_factory_test.go`

## Sağlanan Kabiliyet

- DB DSN env okuma
- PostgreSQL pool oluşturma
- E2E Flow PostgreSQL store oluşturma
- Runtime bridge handlers üretimi
- Default Runtime E2E Orchestrator oluşturma
- API Surface service oluşturma
- API request → E2E Flow → DB smoke doğrulaması

## Not

Bu adımda `api_gateway_main.go` içine canlı mount yapılmadı. Service factory testli şekilde hazırlandı.
