# FAZ 2-7.7.1 — Plugin Loader Runtime

## Amaç

Bu adım Pix2pi plugin runtime ailesinde plugin loader temelini kurar.

## Kapsam

- Plugin manifest loader
- Plugin metadata model
- Plugin permission/scope validation
- Tenant-safe plugin load guard
- Runtime version compatibility başlangıç izi
- Loaded plugin registry
- Plugin loader runtime testleri

## Manifest zorunlu alanları

- tenant_id
- plugin_id
- name
- version
- runtime_version
- entrypoint
- permissions

## Tenant güvenliği

Plugin manifest tenant_id ile load request tenant_id aynı olmalıdır.

Başka tenant manifest yükleme denemesi reddedilir:

```text
ErrPluginLoaderCrossTenant
```

## Permission guard

Plugin permissions allowlist içinde olmalıdır.

Örnek izinler:

```text
erp:read
erp:write
webhook:emit
public_api:read
public_api:write
workflow:trigger
notification:send
report:read
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/plugin/runtime/plugin_loader_runtime.go`
- Test: `internal/platform/plugin/runtime/plugin_loader_runtime_test.go`
- Config: `configs/faz2/plugin_runtime/plugin_loader_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_7_1_plugin_loader_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_005617.md`
