# FAZ 2-7.6.3 — Manual Approval Runtime

## Amaç

Bu adım Pix2pi workflow runtime ailesinde manual approval runtime katmanını kurar.

## Kapsam

- Manual approval request runtime
- Approval decision model
- Approve / reject lifecycle
- Role / approver guard
- Approval wait state bridge
- Tenant-safe approval runtime
- Manual approval runtime testleri

## Workflow bridge

Approval sonucu workflow state machine üzerine şu şekilde yansır:

```text
APPROVED -> WAITING_APPROVAL -> RUNNING
REJECTED -> WAITING_APPROVAL -> APPROVAL_REJECTED
```

## Tenant güvenliği

Approval request ve decision tenant-safe yapılır.

Başka tenant ile approval erişimi reddedilir:

```text
ErrApprovalCrossTenant
```

## Role guard

Approval policy role isterse approver role listesinde bu rol bulunmalıdır.

Örnek:

```text
RequiredRole=MANAGER
ApproverRoles=[MANAGER]
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/workflow/runtime/manual_approval_runtime.go`
- Test: `internal/platform/workflow/runtime/manual_approval_runtime_test.go`
- Config: `configs/faz2/workflow/manual_approval_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_6_3_manual_approval_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260506_235254.md`
