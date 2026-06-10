# FAZ 2-7.6.1 — Workflow State Machine Runtime

## Amaç

Bu adım Pix2pi workflow runtime ailesinin state machine temelini kurar.

## Kapsam

- Workflow state machine
- State transition guard
- Step transition
- Approval wait state
- Failed / compensated state
- Tenant-safe workflow runtime
- Workflow state machine testleri

## State listesi

- DRAFT
- READY
- RUNNING
- WAITING_APPROVAL
- COMPLETED
- FAILED
- COMPENSATING
- COMPENSATED
- CANCELED
- APPROVAL_REJECTED

## Terminal state

- COMPLETED
- COMPENSATED
- CANCELED

## Tenant güvenliği

Workflow transition çalışması için tenant_id zorunludur.

Başka tenant ile workflow instance geçişi reddedilir:

```text
ErrWorkflowCrossTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/workflow/runtime/workflow_state_machine.go`
- Test: `internal/platform/workflow/runtime/workflow_state_machine_test.go`
- Config: `configs/faz2/workflow/workflow_state_machine_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_6_1_workflow_state_machine_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260506_234250.md`
