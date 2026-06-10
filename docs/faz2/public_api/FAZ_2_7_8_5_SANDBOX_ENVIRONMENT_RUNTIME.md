# FAZ 2-7.8.5 — Sandbox Environment Runtime

## Amaç

Bu adım Pix2pi Public API ailesinde sandbox environment runtime temelini kurar.

## Kapsam

- Sandbox app/API key environment isolation
- Sandbox request context
- Sandbox data boundary
- Production deny guard
- Sandbox quota bridge
- Tenant-safe sandbox runtime
- Sandbox environment runtime testleri

## Production deny guard

Bu fazda sandbox runtime production request kabul etmez:

```text
ErrSandboxProductionDenied
```

## Data boundary

Sandbox data namespace:

```text
sandbox:<tenant_id>:<app_id>
```

Örnek:

```text
sandbox:tenant_7:app_7
```

## App auth bridge

Sandbox context ile app auth decision aynı tenant/app/key/environment/scope içinde olmalıdır.

## Quota bridge

Sandbox request quota runtime üzerinden geçirilir.

Limit aşılırsa:

```text
ErrSandboxQuotaDenied
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/publicapi/runtime/sandbox_environment_runtime.go`
- Test: `internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go`
- Config: `configs/faz2/public_api/sandbox_environment_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_8_5_sandbox_environment_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_002234.md`
