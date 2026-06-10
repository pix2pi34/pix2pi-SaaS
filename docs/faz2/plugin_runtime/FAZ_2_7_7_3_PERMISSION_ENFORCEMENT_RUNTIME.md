# FAZ 2-7.7.3 — Permission Enforcement Runtime

## Amaç

Bu adım Pix2pi plugin runtime ailesinde permission enforcement runtime temelini kurar.

## Kapsam

- Plugin permission enforcement
- Permission decision model
- Runtime action permission check
- Tenant-safe permission ownership
- Plugin status guard
- Permission audit decision fields
- Permission enforcement runtime testleri

## Runtime action → permission map

```text
ERP_READ -> erp:read
ERP_WRITE -> erp:write
WEBHOOK_EMIT -> webhook:emit
PUBLIC_API_READ -> public_api:read
PUBLIC_API_WRITE -> public_api:write
WORKFLOW_TRIGGER -> workflow:trigger
NOTIFICATION_SEND -> notification:send
REPORT_READ -> report:read
```

## Status guard

Permission check için plugin install status  olmalıdır.

## Tenant güvenliği

Install tenant_id ile request tenant_id aynı olmalıdır.

Başka tenant install permission kontrolü reddedilir:

```text
ErrPluginPermissionCrossTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/plugin/runtime/permission_enforcement_runtime.go`
- Test: `internal/platform/plugin/runtime/permission_enforcement_runtime_test.go`
- Config: `configs/faz2/plugin_runtime/permission_enforcement_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_7_3_permission_enforcement_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_010526.md`
