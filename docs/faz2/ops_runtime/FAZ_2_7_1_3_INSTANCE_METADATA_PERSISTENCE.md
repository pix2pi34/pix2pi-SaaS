# FAZ 2-7.1.3 — Instance Metadata Persistence

## Amaç

Bu adım Ops Runtime Closure içinde service instance metadata persistence temelini kurar.

## Kapsam

- Service instance metadata runtime
- Instance identity / service identity modeli
- Metadata key/value persistence
- Tenant-safe metadata ownership
- Metadata visibility modeli
- Metadata audit decision fields
- Instance metadata persistence testleri

## Instance status modeli

```text
REGISTERED
HEALTHY
UNHEALTHY
STALE
```

## Metadata visibility modeli

```text
TENANT
PLATFORM
INTERNAL
```

## Tenant güvenliği

Metadata, instance tenant_id ile request tenant_id eşleşmeden yazılamaz/okunamaz.

Başka tenant instance metadata erişimi reddedilir:

```text
ErrInstanceMetadataCrossTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/instance_metadata_runtime.go`
- Test: `internal/platform/ops/runtime/instance_metadata_runtime_test.go`
- Config: `configs/faz2/ops_runtime/instance_metadata_persistence.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_1_3_instance_metadata_persistence_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT_20260507_012004.md`
