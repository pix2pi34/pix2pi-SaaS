# FAZ 2-7.5.3 — Tenant-safe Channel Auth Runtime

## Amaç

Bu adım Pix2pi realtime altyapısında WebSocket ve SSE bağlantıları için tenant-safe channel authorization temelini kurar.

## Kapsam

- Tenant-safe channel authorization
- Channel naming policy
- User/channel permission başlangıç zemini
- WebSocket channel auth bridge
- SSE channel auth bridge
- Deny reason / audit decision
- Channel auth runtime testleri

## Karar

Basit channel isimleri otomatik olarak tenant scoped kabul edilir:

```text
orders => tenant:<tenant_id>:orders
stock  => tenant:<tenant_id>:stock
```

Explicit tenant prefix kullanılırsa tenant eşleşmesi zorunludur:

```text
tenant:tenant_7:orders
tenant/tenant_7/orders
tenant.tenant_7.orders
```

Başka tenant prefix’i reddedilir.

## Deny reason değerleri

- CHANNEL_AUTH_MISSING_TENANT
- CHANNEL_AUTH_MISSING_CHANNEL
- CHANNEL_AUTH_INVALID_CHANNEL_NAME
- CHANNEL_AUTH_CROSS_TENANT_CHANNEL
- CHANNEL_AUTH_FORBIDDEN_SYSTEM_ZONE
- CHANNEL_AUTH_USER_DENIED

## Dosyalar

- Runtime: `internal/platform/realtime/channel_auth_runtime.go`
- Tests: `internal/platform/realtime/channel_auth_runtime_test.go`
- WebSocket bridge: `internal/platform/realtime/websocket_runtime.go`
- SSE bridge: `internal/platform/realtime/sse_runtime.go`
- Config: `configs/faz2/realtime/channel_auth_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_5_3_tenant_safe_channel_auth_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260506_233129.md`
