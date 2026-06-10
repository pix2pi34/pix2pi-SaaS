# FAZ 3 / STEP 12.2B — ERP Runtime API Gateway Route Binding

## Amaç

ERP Runtime API endpoint'inin gateway/router katmanına güvenli şekilde bağlanması için route binding contract oluşturuldu.

## Endpoint

POST `/api/v1/erp/runtime/flows`

## Route Name

`erp.runtime.flows.create`

## Binding Contract

- `RuntimeFlowRouteRegistrar`
- `RuntimeFlowRouteBinding`
- `BuildRuntimeFlowRouteBinding`
- `BindRuntimeFlowRoutes`

## Güvenlik Beklentisi

Gateway bu route için şu zorunlulukları uygulamalıdır:

- Auth zorunlu
- Tenant header zorunlu
- Request ID zorunlu
- Idempotency key zorunlu

## Not

Bu adım gerçek gateway binary dosyasına dokunmaz. Önce contract hazırlanır, sonra gateway entegrasyonunda bu binding kullanılır.
