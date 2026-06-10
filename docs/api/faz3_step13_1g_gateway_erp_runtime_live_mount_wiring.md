# FAZ 3 / STEP 13.1G — Gateway ERP Runtime Live Mount Wiring

## Amaç

ERP Runtime endpoint'ini gerçek API Gateway `protectedMux` içine bağlamak.

## Gerçek Gateway Dosyası

- `cmd/api-gateway/api_gateway_main.go`

## Bağlanan Endpoint

POST `/api/v1/erp/runtime/flows`

## Wiring Noktası

`newGatewayHandler` içinde:

- `protectedMux := http.NewServeMux()`
- `registerProtectedRoutes(protectedMux)`
- `registerERPRuntimeProtectedRoutes(protectedMux, service)`

## Güvenlik Zinciri

Endpoint `/api/` altında olduğu için Gateway protected chain içinden geçer:

- JWT auth
- Tenant middleware
- Rate limit
- Quota

## Fallback Davranışı

ERP Runtime service DB/env sebebiyle hazırlanamazsa route boş kalmaz. Aynı path'e `503 Service Unavailable` dönen fallback handler bağlanır.

## Sonuç

ERP Runtime API artık gerçek gateway protected mux içine bağlanacak wiring noktasına sahiptir.
