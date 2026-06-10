# FAZ 3 / STEP 13.1D — Gateway ERP Runtime Route Policy Helper

## Amaç

ERP Runtime endpoint'ini gerçek gateway içine bağlamadan önce route policy helper ve protected mount helper hazırlamak.

## Eklenen Dosyalar

- `cmd/api-gateway/erp_runtime_route_policy.go`
- `cmd/api-gateway/erp_runtime_route_policy_test.go`

## Endpoint

POST `/api/v1/erp/runtime/flows`

## Route Contract

- Route name: `erp.runtime.flows.create`
- Scope: protected
- Auth required: true
- Tenant required: true
- Prefix: false
- Method: POST

## Helper Fonksiyonları

- `erpRuntimeGatewayRouteRule`
- `appendERPRuntimeGatewayRouteRule`
- `registerERPRuntimeProtectedRoutes`

## Not

Bu adımda `api_gateway_main.go` dosyasına dokunulmadı. Gateway route policy ve protected mount helper testli şekilde hazırlandı.
