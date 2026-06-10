# FAZ 2-7.1.2 — Runtime Heartbeat / Health Push-Pull Akışı

## Amaç

Bu adım Ops Runtime Closure içinde runtime heartbeat push ve health pull snapshot akışını kurar.

## Kapsam

- Runtime heartbeat push endpoint / runtime
- Health pull snapshot runtime
- Instance status update bridge
- Last heartbeat / last seen modeli
- Tenant-safe heartbeat guard
- Registry stale cleanup bridge
- Heartbeat / health push-pull testleri

## Heartbeat endpoint

```text
POST /ops/registry/heartbeat
X-Tenant-ID: <tenant_id>
```

## Health snapshot endpoint

```text
GET /ops/registry/health?scope=INTERNAL&viewer_tenant_id=platform
X-Tenant-ID: <tenant_id>
```

## Tenant güvenliği

Header tenant zorunludur:

```text
X-Tenant-ID
```

Body tenant_id header tenant ile eşleşmezse reddedilir:

```text
ErrRuntimeHealthCrossTenant
```

## Registry bridge

Heartbeat push şu runtime'lara bağlanır:

```text
InstanceMetadataRuntime.RegisterOrUpdateInstance
InstanceMetadataRuntime.UpsertMetadata
```

Health pull şu runtime'lara bağlanır:

```text
RegistryVisibilityRuntime.ListVisibleRegistry
StaleInstanceCleanupRuntime.DetectStaleInstances
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go`
- Test: `internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go`
- Config: `configs/faz2/ops_runtime/runtime_heartbeat_health_push_pull.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_1_2_runtime_heartbeat_health_push_pull_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_REAL_IMPLEMENTATION_AUDIT_20260507_070522.md`
