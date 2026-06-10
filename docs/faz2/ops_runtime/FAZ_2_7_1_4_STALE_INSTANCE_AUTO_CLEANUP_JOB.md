# FAZ 2-7.1.4 — Stale Instance Auto-Cleanup Job

## Amaç

Bu adım Ops Runtime Closure içinde stale service instance detection ve cleanup runtime temelini kurar.

## Kapsam

- Stale instance detection runtime
- Heartbeat age threshold modeli
- Auto-cleanup / stale marker runtime
- Tenant-safe stale cleanup
- Cleanup audit decision fields
- Registry metadata bridge
- Stale instance cleanup testleri

## Stale threshold

Varsayılan eşik:

```text
STALE_AFTER_SECONDS=90
```

## Cleanup davranışı

Runtime şu işlemleri yapar:

```text
tenant scoped instance scan
-> stale candidate detection
-> status = STALE marker
-> INTERNAL visibility metadata cleanup
```

## Tenant güvenliği

Cleanup sadece request tenant_id kapsamındaki instance kayıtlarını işler.

Başka tenant instance kayıtları etkilenmez.

## Metadata cleanup

Varsayılan olarak sadece INTERNAL metadata temizlenir:

```text
cleanup_metadata_visibilities = ["INTERNAL"]
```

TENANT görünür metadata silinmez.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/stale_instance_cleanup_runtime.go`
- Test: `internal/platform/ops/runtime/stale_instance_cleanup_runtime_test.go`
- Config: `configs/faz2/ops_runtime/stale_instance_auto_cleanup_job.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_1_4_stale_instance_auto_cleanup_job_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_REAL_IMPLEMENTATION_AUDIT_20260507_065651.md`
