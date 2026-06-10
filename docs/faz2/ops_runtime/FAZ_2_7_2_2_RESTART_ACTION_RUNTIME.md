# FAZ 2-7.2.2 — Restart Action Runtime

## Amaç

Bu adım Mission Control runtime içinde restart action request temelini kurar.

## Kapsam

- Restart action request runtime
- Operator action authorization model
- Service instance restart decision model
- Tenant-safe restart guard
- Restart action audit log bridge
- Mission control action state bridge
- Restart action runtime testleri

## Operator role modeli

Restart action için izinli roller:

```text
PLATFORM_ADMIN
OPS_ADMIN
SRE
```

## Restartable status modeli

Restart action kabul edilen instance status değerleri:

```text
HEALTHY
UNHEALTHY
STALE
```

## Action state

Restart request oluşturulduğunda action state:

```text
RESTART_REQUESTED
```

## Tenant güvenliği

Restart sadece request tenant_id kapsamındaki instance için oluşturulur.

Başka tenant instance restart isteği reddedilir:

```text
ErrRestartActionCrossTenant
```

## Audit / metadata bridge

Runtime şu metadata kayıtlarını yazar:

```text
restart_action_id
restart_requested_at
restart_operator_id
restart_action_state
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/restart_action_runtime.go`
- Test: `internal/platform/ops/runtime/restart_action_runtime_test.go`
- Config: `configs/faz2/ops_runtime/restart_action_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_2_2_restart_action_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_070744.md`
