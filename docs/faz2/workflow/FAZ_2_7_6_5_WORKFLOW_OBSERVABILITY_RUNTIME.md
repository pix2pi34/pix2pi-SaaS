# FAZ 2-7.6.5 — Workflow Observability Runtime

## Amaç

Bu adım Pix2pi workflow runtime ailesinde observability / metric snapshot katmanını kurar.

## Kapsam

- Workflow metric snapshot
- State transition counters
- Approval counters
- Retry counters
- Compensation counters
- Failed workflow counters
- Tenant-safe observability
- Workflow observability runtime testleri

## Metric grupları

- State transition counters
- Approval counters
- Retry counters
- Compensation counters
- Failed workflow counters

## Tenant güvenliği

Metric kayıt ve snapshot okuma tenant_id zorunlu olacak şekilde tasarlanmıştır.

Tenant boşsa reddedilir:

```text
ErrWorkflowObservabilityMissingTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/workflow/runtime/workflow_observability_runtime.go`
- Test: `internal/platform/workflow/runtime/workflow_observability_runtime_test.go`
- Config: `configs/faz2/workflow/workflow_observability_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_6_5_workflow_observability_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260506_235816.md`
