# FAZ 2-7.5.1 — WebSocket Server Runtime

## Amaç

Bu adım Pix2pi realtime altyapısının WebSocket server runtime temelini kurar.

## Kapsam

- WebSocket upgrade endpoint
- Tenant header zorunluluğu
- Channel query parametresi
- Welcome message
- Ping/pong runtime
- Active connection counter
- Health endpoint
- Unit test

## Endpoint

- WebSocket: `/ws?channel=<channel>`
- Health: `/health`

## Tenant güvenliği

Bu fazda bağlantı açmak için `X-Tenant-ID` zorunludur.

Tenant-safe channel auth, detaylı channel permission ve presence lifecycle sonraki adımlarda açılacaktır:

- 2-7.5.3 Tenant-safe channel auth runtime
- 2-7.5.4 Presence / connection lifecycle runtime

## Dosyalar

- Runtime: `internal/platform/realtime/websocket_runtime.go`
- Test: `internal/platform/realtime/websocket_runtime_test.go`
- Main: `cmd/realtime-ws/realtime_ws_main.go`
- Config: `configs/faz2/realtime/websocket_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_5_1_websocket_server_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260506_232112.md`
