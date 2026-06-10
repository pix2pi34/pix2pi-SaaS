# FAZ 2-7.8.4 — Quota / Rate Limit Runtime

## Amaç

Bu adım Pix2pi Public API ailesinde quota / rate limit runtime temelini kurar.

## Kapsam

- Tenant/app/API key quota policy runtime
- Usage counter runtime
- Rate limit decision model
- Window-based limit
- Scope/environment bazlı quota
- Tenant-safe usage meter
- Quota / rate limit runtime testleri

## Karar modeli

Limit altında:

```text
Decision=ALLOW
Reason=QUOTA_ALLOWED
```

Limit aşılırsa:

```text
Decision=DENY
Reason=QUOTA_LIMIT_EXCEEDED
```

## Dimension modeli

Quota şu boyutlarla takip edilir:

```text
tenant_id + app_id + key_id + environment + scope + window
```

## Tenant güvenliği

Policy ve usage meter tenant-safe yapılır.

Başka tenant policy erişimi reddedilir:

```text
ErrQuotaCrossTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/publicapi/runtime/quota_rate_limit_runtime.go`
- Test: `internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go`
- Config: `configs/faz2/public_api/quota_rate_limit_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_8_4_quota_rate_limit_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_002000.md`
