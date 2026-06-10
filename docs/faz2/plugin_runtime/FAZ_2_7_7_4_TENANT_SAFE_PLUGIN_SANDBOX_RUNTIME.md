# FAZ 2-7.7.4 — Tenant-safe Plugin Sandbox Runtime

## Amaç

Bu adım Pix2pi plugin runtime ailesinde tenant-safe plugin sandbox temelini kurar.

## Kapsam

- Plugin sandbox execution context
- Tenant-safe sandbox boundary
- Permission enforcement bridge
- Plugin lifecycle status bridge
- Plugin environment guard
- Runtime action sandbox deny/allow decision
- Tenant-safe plugin sandbox runtime testleri

## Sandbox namespace

```text
plugin_sandbox:<tenant_id>:<plugin_id>:<install_id>
```

## Runtime guard zinciri

```text
tenant check
-> install check
-> tenant ownership check
-> lifecycle ENABLED check
-> environment SANDBOX check
-> permission enforcement bridge
-> sandbox execution context
```

## Production guard

Bu fazda plugin sandbox production execution kabul etmez:

```text
ErrPluginSandboxProductionDenied
```

## Permission bridge

Sandbox execution için action permission mapping kontrol edilir.

Örnek:

```text
ERP_READ -> erp:read
ERP_WRITE -> erp:write
REPORT_READ -> report:read
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/plugin/runtime/plugin_sandbox_runtime.go`
- Test: `internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go`
- Config: `configs/faz2/plugin_runtime/plugin_sandbox_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_7_4_tenant_safe_plugin_sandbox_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_010804.md`
