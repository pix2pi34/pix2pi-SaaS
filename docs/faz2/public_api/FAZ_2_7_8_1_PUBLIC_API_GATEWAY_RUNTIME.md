# FAZ 2-7.8.1 — Public API Gateway Runtime

## Amaç

Bu adım Pix2pi Public API runtime ailesini gateway runtime altında birleştirir.

## Kapsam

- Public API gateway runtime
- API key extraction
- App auth bridge
- Quota / rate limit bridge
- Sandbox request bridge
- Developer docs endpoint bridge
- Tenant-safe gateway guard
- Public API gateway runtime testleri

## Gateway request zinciri

```text
HTTP headers
-> API key extraction
-> API key hash lookup
-> app auth validation
-> sandbox boundary
-> quota bridge
-> request allow/deny decision
```

## API key extraction

Desteklenen headerlar:

```text
Authorization: Bearer <api_key>
X-API-Key: <api_key>
```

## Developer docs endpoint bridge

```text
/developer/docs
/developer/openapi-trace
```

## Production guard

Bu fazda sandbox runtime üzerinden production request kapalıdır.

Production public API live modülü ayrı fazda açılacaktır.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/publicapi/runtime/public_api_gateway_runtime.go`
- Test: `internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go`
- Config: `configs/faz2/public_api/public_api_gateway_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_8_1_public_api_gateway_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_002954.md`
