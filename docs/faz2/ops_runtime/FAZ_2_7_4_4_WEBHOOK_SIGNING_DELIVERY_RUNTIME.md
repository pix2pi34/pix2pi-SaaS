# FAZ 2-7.4.4 — Webhook Signing + Delivery Runtime

## Amaç

Bu adım notification runtime içinde tenant-aware webhook signing + delivery temelini kurar.

## Kapsam

- Webhook delivery runtime
- HMAC SHA256 signing
- Signature verify runtime
- Webhook header bridge
- Provider model
- Method validation
- URL validation
- Tenant-scoped idempotency guard
- Tenant-safe delivery access
- Tenant event delivery list
- Dry-run/simulation delivery policy
- Webhook signing + delivery runtime testleri

## Provider modeli

```text
SIMULATION
HTTP
```

## Method modeli

```text
POST
PUT
```

## State modeli

```text
QUEUED
DELIVERED
REJECTED
```

## Signing modeli

```text
Algorithm: HMAC_SHA256
Header: X-Pix2pi-Signature
Format: sha256=<hex>
```

## Güvenlik

Webhook delivery kayıtları tenant_id ile ayrılır.

Başka tenant delivery okuma isteği reddedilir:

```text
ErrWebhookDeliveryCrossTenant
```

## Idempotency

Idempotency key tenant scoped tutulur:

```text
tenant_id::idempotency_key
```

## Delivery policy

Bu fazda gerçek webhook gönderimi açılmaz.

```text
real_webhook_send = DISABLED_IN_THIS_PHASE
simulation_delivery = ENABLED
http_delivery = QUEUED_ONLY_WHEN_DRY_RUN_FALSE
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/webhook_signing_delivery_runtime.go`
- Test: `internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go`
- Config: `configs/faz2/ops_runtime/webhook_signing_delivery_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_4_4_webhook_signing_delivery_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_073935.md`
