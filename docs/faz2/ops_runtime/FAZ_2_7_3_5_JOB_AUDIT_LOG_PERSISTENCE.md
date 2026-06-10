# FAZ 2-7.3.5 — Job Audit Log Persistence

## Amaç

Bu adım job engine runtime içinde tenant-aware job audit log persistence temelini kurar.

## Kapsam

- Job audit log persistence runtime
- Job event type modeli
- Severity modeli
- Tenant-safe audit access
- Job-scoped audit listing
- Tenant-scoped audit listing
- Tenant-aware job dispatch bridge
- Job audit log persistence testleri

## Event type modeli

```text
JOB_QUEUED
JOB_DISPATCHED
JOB_FAILED
JOB_RETRIED
JOB_CANCELED
```

## Severity modeli

```text
INFO
WARNING
ERROR
```

## Tenant güvenliği

Audit kayıtları tenant_id ile ayrılır.

Başka tenant audit log okuma isteği reddedilir:

```text
ErrJobAuditCrossTenant
```

## Dispatch bridge

TenantAwareJobRecord üzerinden audit kaydı üretilebilir:

```text
RecordFromJob(job, eventType, message)
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/job_audit_log_persistence_runtime.go`
- Test: `internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go`
- Config: `configs/faz2/ops_runtime/job_audit_log_persistence.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_3_5_job_audit_log_persistence_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT_20260507_072135.md`
