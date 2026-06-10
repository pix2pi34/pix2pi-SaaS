# FAZ 2-7.3.4 — Tenant-aware Job Dispatch Runtime

## Amaç

Bu adım job engine runtime içinde tenant-aware dispatch temelini kurar.

## Kapsam

- Tenant-aware job dispatch runtime
- Job type modeli
- Queue / priority modeli
- Tenant-scoped dedupe guard
- Tenant-safe job access
- Tenant-safe queue access
- Dispatch / mark dispatched lifecycle
- Job dispatch runtime testleri

## Job type modeli

```text
WEBHOOK_DELIVERY
EMAIL_DELIVERY
REPORT_BUILD
CLEANUP
```

## Priority modeli

```text
LOW
NORMAL
HIGH
CRITICAL
```

## State modeli

```text
QUEUED
DISPATCHED
REJECTED
```

## Tenant güvenliği

Job kayıtları tenant_id ile ayrılır.

Başka tenant job okuma veya dispatch state değiştirme isteği reddedilir:

```text
ErrJobDispatchCrossTenant
```

## Dedupe guard

Dedupe key tenant scoped tutulur:

```text
tenant_id::dedupe_key
```

Aynı dedupe key başka tenant içinde tekrar kullanılabilir; aynı tenant içinde tekrar kullanılamaz.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go`
- Test: `internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go`
- Config: `configs/faz2/ops_runtime/tenant_aware_job_dispatch_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_3_4_tenant_aware_job_dispatch_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_072004.md`
