# FAZ 2-8.7 — Runtime Health / Topology Görünümü

## Amaç

Bu adım WEB-L3 Platform Operations Console içinde Runtime Health / Topology görünümünü kurar.

## Kapsam

- Runtime node modeli
- Runtime edge modeli
- Health snapshot
- Topology snapshot
- Node kind filter
- Node status filter
- Edge visibility toggle
- Stale node detection
- Tenant-safe viewer guard
- Responsive HTML checkpoint

## Node türleri

```text
SERVICE
GATEWAY
DATABASE
QUEUE
CACHE
WORKER
```

## Node health statüleri

```text
HEALTHY
DEGRADED
DOWN
UNKNOWN
```

## Edge statüleri

```text
ACTIVE
DEGRADED
BROKEN
```

## Runtime dosyaları

- Runtime: `internal/platform/ops/console/runtime_health_topology_console.go`
- Test: `internal/platform/ops/console/runtime_health_topology_console_test.go`

## Web checkpoint

- HTML: `web/ops-console/runtime-health-topology/index.html`

## Güvenlik

Tenant dışı görüntüleme varsayılan olarak reddedilir.

Platform viewer sadece internal ops scope için izinli kabul edilir.

## responsive trace

Bu ekran responsive shell, responsive metric grid, responsive topology map ve responsive iki kolon düzeniyle WEB-L3 Ops Console içinde mobil/tablet/desktop görünümüne hazırdır.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Evidence

- Audit: `scripts/audit/faz2/faz_2_8_7_runtime_health_topology_view_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_REAL_IMPLEMENTATION_AUDIT_20260507_075943.md`
