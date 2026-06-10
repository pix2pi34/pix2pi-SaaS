# FAZ 2-7.2.3 — Isolate / Quarantine Action Runtime

## Amaç

Bu adım Mission Control runtime içinde isolate / quarantine action request temelini kurar.

## Kapsam

- Isolate action request runtime
- Quarantine action state model
- Operator action authorization
- Tenant-safe quarantine guard
- Service instance quarantine metadata bridge
- Quarantine audit log bridge
- Isolate / quarantine action runtime testleri

## Operator role modeli

İzinli roller:

```text
PLATFORM_ADMIN
OPS_ADMIN
SRE
```

## Action type modeli

```text
ISOLATE
QUARANTINE
```

## Action state modeli

```text
ISOLATE_REQUESTED
QUARANTINE_REQUESTED
ISOLATE_QUARANTINE_DENIED
```

## Tenant güvenliği

Action sadece request tenant_id kapsamındaki instance için oluşturulur.

Başka tenant instance isolate/quarantine isteği reddedilir:

```text
ErrIsolateQuarantineCrossTenant
```

## Metadata bridge

Runtime şu metadata kayıtlarını yazar:

```text
isolate_quarantine_action_id
isolate_quarantine_action_type
isolate_quarantine_action_state
isolate_quarantine_operator_id
isolate_quarantine_requested_at
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/isolate_quarantine_action_runtime.go`
- Test: `internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go`
- Config: `configs/faz2/ops_runtime/isolate_quarantine_action_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_2_3_isolate_quarantine_action_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_071150.md`
