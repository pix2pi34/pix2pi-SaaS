# FAZ 2-7.4.3 — SMS / Push Delivery Runtime

## Amaç

Bu adım notification runtime içinde tenant-aware SMS / push delivery temelini kurar.

## Kapsam

- SMS delivery runtime
- Push delivery runtime
- SMS phone validation
- Push device token validation
- Provider model
- Tenant + channel scoped idempotency guard
- Tenant-safe delivery access
- Tenant channel delivery list
- Dry-run/simulation delivery policy
- SMS / push delivery runtime testleri

## Channel modeli

```text
SMS
PUSH
```

## Provider modeli

```text
SIMULATION
SMS_GATEWAY
PUSH_GATEWAY
```

## State modeli

```text
QUEUED
DELIVERED
REJECTED
```

## Güvenlik

SMS / push delivery kayıtları tenant_id ile ayrılır.

Başka tenant delivery okuma isteği reddedilir:

```text
ErrSMSPushDeliveryCrossTenant
```

## Idempotency

Idempotency key tenant + channel scoped tutulur:

```text
tenant_id::channel::idempotency_key
```

Aynı key farklı tenant veya farklı channel içinde kullanılabilir; aynı tenant + aynı channel içinde tekrar kullanılamaz.

## Delivery policy

Bu fazda gerçek SMS / push gönderimi açılmaz.

```text
real_sms_send = DISABLED_IN_THIS_PHASE
real_push_send = DISABLED_IN_THIS_PHASE
simulation_delivery = ENABLED
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/sms_push_delivery_runtime.go`
- Test: `internal/platform/ops/runtime/sms_push_delivery_runtime_test.go`
- Config: `configs/faz2/ops_runtime/sms_push_delivery_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_4_3_sms_push_delivery_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_073402.md`
