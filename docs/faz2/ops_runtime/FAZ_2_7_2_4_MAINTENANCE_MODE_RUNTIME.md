# FAZ 2-7.2.4 — Maintenance Mode Runtime

## Amaç

Bu adım Mission Control runtime içinde maintenance mode temelini kurar.

## Kapsam

- Maintenance mode enable / disable runtime
- Operator action authorization
- Tenant-safe maintenance guard
- Service instance maintenance metadata bridge
- Maintenance audit log bridge
- Maintenance mode runtime testleri

## Operator role modeli

İzinli roller:

```text
PLATFORM_ADMIN
OPS_ADMIN
SRE
```

## Action modeli

```text
ENABLE_MAINTENANCE
DISABLE_MAINTENANCE
```

## State modeli

```text
MAINTENANCE_ENABLED
MAINTENANCE_DISABLED
MAINTENANCE_DENIED
```

## Tenant güvenliği

Maintenance mode sadece request tenant_id kapsamındaki instance için oluşturulur.

Başka tenant instance maintenance isteği reddedilir:

```text
ErrMaintenanceModeCrossTenant
```

## Metadata bridge

Runtime şu metadata kayıtlarını yazar:

```text
maintenance_mode_id
maintenance_mode_action
maintenance_mode_state
maintenance_mode_operator_id
maintenance_mode_updated_at
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/maintenance_mode_runtime.go`
- Test: `internal/platform/ops/runtime/maintenance_mode_runtime_test.go`
- Config: `configs/faz2/ops_runtime/maintenance_mode_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_2_4_maintenance_mode_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_071317.md`
