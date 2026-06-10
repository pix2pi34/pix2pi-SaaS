# FAZ 2-7.1.5 — Tenant-aware Registry Visibility Runtime

## Amaç

Bu adım Ops Runtime Closure içinde tenant-aware service registry visibility runtime temelini kurar.

## Kapsam

- Tenant-aware service registry visibility
- Service visibility policy runtime
- Tenant-visible / platform-visible / internal-visible filter
- Registry metadata visibility bridge
- Cross-tenant registry visibility guard
- Visibility audit decision fields
- Registry visibility runtime testleri

## Visibility scope modeli

```text
TENANT
PLATFORM
INTERNAL
```

## Metadata visibility matrix

```text
TENANT   -> TENANT metadata
PLATFORM -> TENANT + PLATFORM metadata
INTERNAL -> TENANT + PLATFORM + INTERNAL metadata
```

## Tenant güvenliği

TENANT scope içinde viewer_tenant_id ile tenant_id aynı olmalıdır.

Başka tenant TENANT scope registry visibility reddedilir:

```text
ErrRegistryVisibilityCrossTenantDenied
```

## Leakage guard

Runtime sadece request tenant_id kapsamındaki service instance kayıtlarını döndürür.

Başka tenant instance/metadata kayıtları sonuç setine sızmaz.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/registry_visibility_runtime.go`
- Test: `internal/platform/ops/runtime/registry_visibility_runtime_test.go`
- Config: `configs/faz2/ops_runtime/tenant_aware_registry_visibility_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_1_5_tenant_aware_registry_visibility_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_065918.md`
