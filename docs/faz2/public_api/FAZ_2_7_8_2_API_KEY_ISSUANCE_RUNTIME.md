# FAZ 2-7.8.2 — API Key Issuance Runtime

## Amaç

Bu adım Pix2pi Public API ailesinde API key issuance runtime temelini kurar.

## Kapsam

- API key üretimi
- Secret hashleme
- Key prefix
- Tenant-safe API key ownership
- Scope / environment modeli
- Revoke / rotate başlangıç zemini
- API key issuance runtime testleri

## Secret güvenliği

Raw secret sadece issuance sonucunda tek seferlik döner.

Kalıcı record içinde yalnızca hash tutulur:

```text
SecretHash=sha256:<hash>
```

## Tenant güvenliği

API key okuma, listeleme, revoke ve rotate işlemleri tenant-safe yapılır.

Başka tenant key erişimi reddedilir:

```text
ErrAPIKeyCrossTenant
```

## Environment

- SANDBOX
- PRODUCTION

## Allowed scopes

- read
- write
- webhook:read
- webhook:write
- report:read
- admin:limited

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/publicapi/runtime/api_key_issuance_runtime.go`
- Test: `internal/platform/publicapi/runtime/api_key_issuance_runtime_test.go`
- Config: `configs/faz2/public_api/api_key_issuance_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_8_2_api_key_issuance_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_000442.md`
