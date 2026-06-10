# FAZ 2-7.8.3 — App Auth Runtime

## Amaç

Bu adım Pix2pi Public API ailesinde app registration ve API key ↔ app auth relation runtime temelini kurar.

## Kapsam

- App registration/auth relation runtime
- API key ↔ app relation
- Tenant-safe app ownership
- App environment guard
- Scope inheritance / app allowed scopes
- App auth validation
- App auth runtime testleri

## Scope inheritance kararı

API key scope listesi app allowed scopes içinde olmalıdır.

Örnek:

```text
App scopes: read, write, report:read
Key scopes: read, report:read
Result: ALLOW
```

Key app scope dışına çıkarsa reddedilir:

```text
ErrAppAuthScopeNotAllowed
```

## Tenant güvenliği

App ve API key aynı tenant altında olmalıdır.

Başka tenant app/key ilişkisi reddedilir:

```text
ErrAppAuthCrossTenant
```

## Environment guard

App ve API key environment aynı olmalıdır:

```text
SANDBOX app -> SANDBOX key
PRODUCTION app -> PRODUCTION key
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/publicapi/runtime/app_auth_runtime.go`
- Test: `internal/platform/publicapi/runtime/app_auth_runtime_test.go`
- Config: `configs/faz2/public_api/app_auth_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_8_3_app_auth_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_8_3_APP_AUTH_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_001754.md`
