# FAZ 3 / STEP 12.3B — ERP Runtime API Gateway Mount Binding

## Amaç

Gateway mount planını route binding ile birleştirmek.

Bu adımda:

- Mount plan doğrulanır.
- Route binding üretilir.
- Handler hazırlanır.
- Registrar üzerinden route kaydedilir.

## Mount

- Mount name: `erp.runtime.api.mount`
- Service name: `erp-runtime-api`
- Mount path: `/api/v1/erp/runtime`
- Upstream mode: `in_process_handler`

## Route

POST `/api/v1/erp/runtime/flows`

## Binding Fonksiyonları

- `BuildRuntimeFlowGatewayMountBinding`
- `MountRuntimeFlowGatewayRoutes`

## Güvenlik

Mount binding şu route güvenlik şartlarını taşır:

- Auth zorunlu
- Tenant header zorunlu
- Request ID zorunlu
- Idempotency key zorunlu

## Sonuç

Gateway mount planı route binding ile birleştirildi. Gerçek gateway entegrasyonuna geçmeden önce mount seviyesinde contract doğrulanmış oldu.
