# FAZ 2-7.4.5 — Webhook Retry / DLQ Runtime

## Amaç

Bu adım notification runtime içinde webhook retry ve DLQ temelini kurar.

## Kapsam

- Webhook retry runtime
- Exponential backoff policy
- Retry duplicate guard
- Retry completed lifecycle
- Dead-letter queue runtime
- Tenant-safe retry access
- Tenant-safe DLQ access
- Delivery-scoped retry list
- Webhook retry / DLQ runtime testleri

## Retry state modeli

```text
RETRY_SCHEDULED
RETRY_COMPLETED
RETRY_EXHAUSTED
DLQ
```

## Retry policy

```text
base_backoff_seconds = 5
max_backoff_seconds = 300
max_attempts = 5
```

## Tenant güvenliği

Retry ve DLQ kayıtları tenant_id ile ayrılır.

Başka tenant retry / DLQ okuma isteği reddedilir:

```text
ErrWebhookRetryCrossTenant
```

## DLQ policy

Max attempt sonrası olay DLQ tarafına alınır.

```text
EnableDLQ = true
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/webhook_retry_dlq_runtime.go`
- Test: `internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go`
- Config: `configs/faz2/ops_runtime/webhook_retry_dlq_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_4_5_webhook_retry_dlq_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_074230.md`
