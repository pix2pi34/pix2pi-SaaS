# FAZ 2-7.7.5 — Version Compatibility Runtime Check

## Amaç

Bu adım Pix2pi plugin runtime ailesinde version compatibility check temelini kurar.

## Kapsam

- Plugin runtime version compatibility check
- Host runtime version model
- Minimum / maximum supported runtime guard
- Plugin version compatibility state
- Tenant-safe compatibility decision
- Compatibility audit decision fields
- Version compatibility runtime testleri

## Runtime version modeli

Örnek runtime version:

```text
pix2pi-plugin-runtime/v1.2.0
```

## Host support guard

```text
minimum_supported_runtime_version = pix2pi-plugin-runtime/v1.0.0
maximum_supported_runtime_version = pix2pi-plugin-runtime/v1.9.9
```

## Decision modeli

Uyumluysa:

```text
PLUGIN_COMPATIBILITY_ALLOWED
COMPATIBLE
```

Minimum altındaysa:

```text
ErrPluginCompatibilityBelowMinimum
```

Maximum üstündeyse:

```text
ErrPluginCompatibilityAboveMaximum
```

## Tenant güvenliği

Manifest tenant_id ile request tenant_id aynı olmalıdır.

Başka tenant compatibility check reddedilir:

```text
ErrPluginCompatibilityCrossTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/plugin/runtime/version_compatibility_runtime.go`
- Test: `internal/platform/plugin/runtime/version_compatibility_runtime_test.go`
- Config: `configs/faz2/plugin_runtime/version_compatibility_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_7_5_version_compatibility_runtime_check_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_REAL_IMPLEMENTATION_AUDIT_20260507_011111.md`
