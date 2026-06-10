# FAZ 2-7.4.2 — Email Delivery Runtime

## Amaç

Bu adım notification runtime içinde tenant-aware email delivery temelini kurar.

## Kapsam

- Email delivery runtime
- Recipient validation
- Provider model
- Tenant-scoped idempotency guard
- Tenant-safe delivery access
- Recipient-scoped delivery list
- Dry-run/simulation delivery policy
- Email delivery runtime testleri

## Provider modeli

```text
SIMULATION
SMTP
```

## State modeli

```text
QUEUED
DELIVERED
REJECTED
```

## Güvenlik

Email delivery kayıtları tenant_id ile ayrılır.

Başka tenant delivery okuma isteği reddedilir:

```text
ErrEmailDeliveryCrossTenant
```

## Idempotency

Idempotency key tenant scoped tutulur:

```text
tenant_id::idempotency_key
```

Aynı key başka tenant içinde kullanılabilir; aynı tenant içinde tekrar kullanılamaz.

## Delivery policy

Bu fazda gerçek email gönderimi açılmaz.

```text
real_email_send = DISABLED_IN_THIS_PHASE
simulation_delivery = ENABLED
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/email_delivery_runtime.go`
- Test: `internal/platform/ops/runtime/email_delivery_runtime_test.go`
- Config: `configs/faz2/ops_runtime/email_delivery_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_4_2_email_delivery_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_072531.md`
