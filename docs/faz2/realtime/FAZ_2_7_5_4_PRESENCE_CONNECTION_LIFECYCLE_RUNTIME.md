# FAZ 2-7.5.4 — Presence / Connection Lifecycle Runtime

## Amaç

Bu adım Pix2pi realtime altyapısında WebSocket ve SSE bağlantıları için presence / connection lifecycle runtime temelini kurar.

## Kapsam

- Connection ID üretimi
- Tenant-safe active connection registry
- Presence state
- Connect lifecycle
- Heartbeat / last seen lifecycle
- Disconnect lifecycle
- WebSocket lifecycle bridge
- SSE lifecycle bridge
- Presence runtime testleri

## Karar

Bu fazda presence registry process-local memory olarak kurulur.

Dağıtık presence store, Redis/cluster presence ve multi-node fanout sonraki ölçek adımlarında açılacaktır.

## Tenant güvenliği

Presence runtime içinde connection lookup tenant-safe yapılır.

Başka tenant ile connection erişimi reddedilir:

```text
ErrPresenceCrossTenant
```

## Dosyalar

- Runtime: `internal/platform/realtime/presence_runtime.go`
- Tests: `internal/platform/realtime/presence_runtime_test.go`
- WebSocket bridge: `internal/platform/realtime/websocket_runtime.go`
- SSE bridge: `internal/platform/realtime/sse_runtime.go`
- Config: `configs/faz2/realtime/presence_connection_lifecycle_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_5_4_presence_connection_lifecycle_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260506_233335.md`
