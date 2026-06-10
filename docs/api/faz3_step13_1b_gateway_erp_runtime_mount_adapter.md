# FAZ 3 / STEP 13.1B — Gateway ERP Runtime Mount Adapter

## Amaç

ERP Runtime API Surface tarafında hazırlanan route/mount binding contract'ını gerçek `cmd/api-gateway` paketi içinde kullanılabilir hale getirmek.

## Eklenen Dosyalar

- `cmd/api-gateway/erp_runtime_mount.go`
- `cmd/api-gateway/erp_runtime_mount_test.go`

## Sağlanan Fonksiyon

`mountERPRuntimeGatewayRoutes(mux, service)`

Bu fonksiyon:

- `http.ServeMux` alır.
- `RuntimeFlowAPIService` alır.
- `apisurface.MountRuntimeFlowGatewayRoutes` üzerinden route'u mux'a kaydeder.

## Endpoint

POST `/api/v1/erp/runtime/flows`

## Not

Bu adımda `api_gateway_main.go` dosyasına dokunulmadı. Sadece gateway package içinde güvenli mount adapter hazırlandı.
