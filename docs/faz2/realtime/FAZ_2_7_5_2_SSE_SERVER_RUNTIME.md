# FAZ 2-7.5.2 — SSE Server Runtime

## Amaç

Bu adım Pix2pi realtime altyapısının SSE server runtime temelini kurar.

## Kapsam

- SSE stream endpoint
- Tenant header zorunluluğu
- Channel query parametresi
- Welcome event
- Heartbeat event
- Active connection counter
- Health endpoint
- Unit test

## Endpoint

- SSE: `/events?channel=<channel>`
- Health: `/health`

## Tenant güvenliği

Bu fazda SSE stream açmak için `X-Tenant-ID` zorunludur.

Tenant-safe channel auth, detaylı channel permission ve presence lifecycle sonraki adımlarda açılacaktır:

- 2-7.5.3 Tenant-safe channel auth runtime
- 2-7.5.4 Presence / connection lifecycle runtime

## Dosyalar

- Runtime: `internal/platform/realtime/sse_runtime.go`
- Test: `internal/platform/realtime/sse_runtime_test.go`
- Main: `cmd/realtime-sse/realtime_sse_main.go`
- Config: `configs/faz2/realtime/sse_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_5_2_sse_server_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_5_2_SSE_SERVER_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260506_232613.md`
