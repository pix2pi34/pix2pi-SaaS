# FAZ 2-7.2.1 — Gerçek Servis Durum Paneli Bağlantısı

## Amaç

Bu adım Mission Control servis durum paneli için gerçek runtime snapshot bağlantısını kurar.

## Kapsam

- Service status panel snapshot runtime
- Registry visibility bridge
- Stale instance cleanup bridge
- Runtime heartbeat metadata bridge
- Restart / quarantine / maintenance / incident metadata bridge
- Tenant-safe panel visibility guard
- Service status panel connection testleri

## Panel snapshot kaynakları

```text
InstanceMetadataRuntime
RegistryVisibilityRuntime
StaleInstanceCleanupRuntime
```

## Mission Control tag kaynakları

```text
restart_action_id
isolate_quarantine_action_state
maintenance_mode_state
incident_action_log_id
```

## Tenant güvenliği

TENANT scope içinde cross-tenant viewer reddedilir:

```text
ErrServiceStatusPanelCrossTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/service_status_panel_connection_runtime.go`
- Test: `internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go`
- Config: `configs/faz2/ops_runtime/service_status_panel_connection.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_2_1_service_status_panel_connection_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_REAL_IMPLEMENTATION_AUDIT_20260507_071819.md`
