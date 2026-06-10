# FAZ 2-7.8.6 — Developer Docs Publish Pipeline

## Amaç

Bu adım Pix2pi Public API ailesinde developer documentation publish pipeline temelini kurar.

## Kapsam

- Public API docs model
- Endpoint documentation registry
- OpenAPI / markdown publish izi
- Sandbox docs section
- API key / quota / app auth docs
- Developer docs publish validation
- Developer docs pipeline testleri

## Publish formatları

- MARKDOWN
- OPENAPI_TRACE

## Zorunlu sectionlar

- Sandbox
- API Key
- Quota
- App Auth

## Endpoint doc zorunlu alanları

- method
- path
- description
- required_scopes
- environment

## Yayın artifact izleri

- `docs/public_api/PIX2PI_PUBLIC_API_DEVELOPER_DOCS.md`
- `docs/public_api/PIX2PI_PUBLIC_API_OPENAPI_TRACE.json`

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/publicapi/runtime/developer_docs_publish_runtime.go`
- Test: `internal/platform/publicapi/runtime/developer_docs_publish_runtime_test.go`
- Config: `configs/faz2/public_api/developer_docs_publish_pipeline.v1.json`
- Published markdown trace: `docs/public_api/PIX2PI_PUBLIC_API_DEVELOPER_DOCS.md`
- Published OpenAPI trace: `docs/public_api/PIX2PI_PUBLIC_API_OPENAPI_TRACE.json`
- Audit: `scripts/audit/faz2/faz_2_7_8_6_developer_docs_publish_pipeline_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_REAL_IMPLEMENTATION_AUDIT_20260507_002534.md`
