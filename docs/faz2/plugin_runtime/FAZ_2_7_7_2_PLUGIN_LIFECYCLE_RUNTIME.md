# FAZ 2-7.7.2 — Plugin Lifecycle Runtime

## Amaç

Bu adım Pix2pi plugin runtime ailesinde plugin lifecycle runtime temelini kurar.

## Kapsam

- Plugin install lifecycle
- Plugin enable / disable runtime
- Plugin suspend / uninstall runtime
- Tenant plugin install state
- Lifecycle transition guard
- Tenant-safe lifecycle ownership
- Plugin lifecycle runtime testleri

## Lifecycle state modeli

```text
INSTALLED
ENABLED
DISABLED
SUSPENDED
UNINSTALLED
```

## Geçerli geçişler

```text
INSTALLED -> ENABLED | UNINSTALLED
ENABLED -> DISABLED | SUSPENDED | UNINSTALLED
DISABLED -> ENABLED | UNINSTALLED
SUSPENDED -> ENABLED | UNINSTALLED
UNINSTALLED -> terminal
```

## Tenant güvenliği

Install kaydı tenant-safe okunur ve yönetilir.

Başka tenant install erişimi reddedilir:

```text
ErrPluginLifecycleCrossTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/plugin/runtime/plugin_lifecycle_runtime.go`
- Test: `internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go`
- Config: `configs/faz2/plugin_runtime/plugin_lifecycle_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_7_2_plugin_lifecycle_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_010312.md`
