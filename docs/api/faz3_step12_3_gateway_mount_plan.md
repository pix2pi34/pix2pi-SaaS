# FAZ 3 / STEP 12.3A — ERP Runtime API Gateway Mount Plan

## Amaç

ERP Runtime API endpoint'lerinin Gateway içine hangi mount planı ile bağlanacağını sözleşmeye bağlamak.

## Mount Plan

- Mount name: `erp.runtime.api.mount`
- Service name: `erp-runtime-api`
- Mount path: `/api/v1/erp/runtime`
- Upstream mode: `in_process_handler`

## Bağlanacak Route

POST `/api/v1/erp/runtime/flows`

Route name:

`erp.runtime.flows.create`

## Güvenlik

Gateway mount planı şu kuralları zorunlu kabul eder:

- Auth zorunlu
- Tenant header zorunlu
- Request ID zorunlu
- Idempotency key zorunlu

## Bağlantı Akışı

Gateway mount planı → Route manifest → Route binding → HTTP handler → API service → E2E Flow orchestrator → PostgreSQL runtime flow store

## Not

Bu adım gerçek gateway binary dosyasını değiştirmez. Gateway entegrasyonuna geçmeden önce mount plan contract'ını doğrular.
