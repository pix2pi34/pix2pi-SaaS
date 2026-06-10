# FAZ 2-7.6.4 — Retry / Compensation Runtime

## Amaç

Bu adım Pix2pi workflow runtime ailesinde retry ve compensation runtime katmanını kurar.

## Kapsam

- Workflow retry runtime
- Retry attempt model
- Backoff policy
- Compensation runtime
- Failed step → retry / compensation decision
- Tenant-safe retry/compensation guard
- Retry / compensation runtime testleri

## Retry karar modeli

Retry policy max attempt dolmadıysa:

```text
Action=RETRY
Status=SCHEDULED
```

Retry max attempt dolduysa:

```text
Action=COMPENSATE
Status=EXHAUSTED
```

## Backoff stratejileri

- FIXED
- LINEAR
- EXPONENTIAL

## Compensation workflow bridge

```text
FAILED -> COMPENSATING
COMPENSATING -> COMPENSATED
```

## Tenant güvenliği

Compensation kayıtları tenant-safe okunur ve değiştirilir.

Başka tenant ile compensation erişimi reddedilir:

```text
ErrWorkflowCompensationCrossTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/workflow/runtime/retry_compensation_runtime.go`
- Test: `internal/platform/workflow/runtime/retry_compensation_runtime_test.go`
- Config: `configs/faz2/workflow/retry_compensation_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_6_4_retry_compensation_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260506_235629.md`
