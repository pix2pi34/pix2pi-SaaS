# FAZ 2-7.6.2 — Workflow Definition Loader Runtime

## Amaç

Bu adım Pix2pi workflow runtime ailesinde JSON tabanlı workflow definition loader katmanını kurar.

## Kapsam

- Workflow definition model
- Definition JSON loader
- Step definition loader
- Approval step definition
- Retry / compensation definition izi
- Definition validation
- Tenant-safe definition loading
- Workflow definition loader testleri

## Step tipleri

- TASK
- APPROVAL
- DECISION
- COMPENSATION
- NOTIFY

## Tenant güvenliği

Workflow definition yüklemesi tenant-safe yapılır.

Request tenant ile definition içindeki tenant farklıysa reddedilir:

```text
ErrWorkflowDefinitionCrossTenant
```

Definition içinde tenant_id boşsa request tenant_id otomatik atanır.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/workflow/runtime/workflow_definition_loader.go`
- Test: `internal/platform/workflow/runtime/workflow_definition_loader_test.go`
- Config: `configs/faz2/workflow/workflow_definition_loader_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_6_2_workflow_definition_loader_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260506_234613.md`
