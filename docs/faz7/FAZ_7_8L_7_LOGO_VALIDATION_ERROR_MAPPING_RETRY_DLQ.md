# FAZ 7-8L.7 — Logo Validation / Error Mapping / Retry-DLQ

## Amaç

Bu adım, Logo dry-run import package ve delivery envelope için doğrulama, hata sınıflandırma, retry kararı, DLQ kararı ve manual review sınırlarını kurar.

Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek Logo dosya teslimi yapmaz.
Bu adım gerçek ERP write yapmaz.

## Bağımlılık

FAZ 7-8L.1 Logo Connector Foundation / Provider Identity tamamlanmış olmalıdır.
FAZ 7-8L.2 Logo Live Contract / API-File Contract Readiness tamamlanmış olmalıdır.
FAZ 7-8L.3 Logo Credential / Secret Reference Readiness tamamlanmış olmalıdır.
FAZ 7-8L.4 Logo Export Mapping Contract tamamlanmış olmalıdır.
FAZ 7-8L.5 Logo File Generation Dry-Run tamamlanmış olmalıdır.
FAZ 7-8L.6 Logo Import Package / Delivery Contract tamamlanmış olmalıdır.

Beklenen dosyalar:

internal/platform/integrations/providers/logo/logo_foundation.go
internal/platform/integrations/providers/logo/logo_live_contract.go
internal/platform/integrations/providers/logo/logo_credential.go
internal/platform/integrations/providers/logo/logo_export_mapping.go
internal/platform/integrations/providers/logo/logo_file_generation.go
internal/platform/integrations/providers/logo/logo_import_delivery.go

## Dizin Standardı

Logo provider-specific dosyaları şu dizinde tutulur:

internal/platform/integrations/providers/logo/

Bu adımın dosyaları:

internal/platform/integrations/providers/logo/logo_validation_retry_dlq.go
internal/platform/integrations/providers/logo/logo_validation_retry_dlq_test.go

## Kapsam

- Logo dry-run validation contract
- Delivery envelope validation
- Checksum validation
- Manifest validation
- Tenant / correlation / idempotency validation
- Logo error mapping
- Retryable / non-retryable error classification
- Retry decision model
- DLQ decision model
- Manual review decision model
- Retry attempt limit guard
- No external call guard
- No real file delivery guard
- No ERP write guard
- Config artifact
- Go runtime model
- Go unit tests
- Real implementation audit

## Modül Kimliği

- Module: FAZ_7_8L
- Step: FAZ_7_8L.7
- Provider code: LOGO
- Provider name: Logo
- Connector code: logo_connector
- Connector family: accounting_export_connector
- Runtime mode: DRY_RUN
- Validation mode: VALIDATION_RETRY_DLQ_DRY_RUN_ONLY
- Target system: LOGO_ACCOUNTING_IMPORT_DRY_RUN

## Error Class Set

- VALIDATION_ERROR
- TENANT_BOUNDARY_ERROR
- CHECKSUM_ERROR
- MANIFEST_ERROR
- TRANSIENT_PROVIDER_ERROR
- PERMANENT_PROVIDER_ERROR
- UNKNOWN_PROVIDER_ERROR

## Error Code Set

- MISSING_TENANT_ID
- MISSING_CORRELATION_ID
- MISSING_IDEMPOTENCY_KEY
- CHECKSUM_MISMATCH
- INVALID_MANIFEST
- TENANT_BOUNDARY_VIOLATION
- PROVIDER_TIMEOUT
- PROVIDER_RATE_LIMIT
- PROVIDER_REJECTED_PACKAGE
- UNKNOWN_PROVIDER_ERROR

## Retry Policy

- Max retry attempts: 3
- Retryable classes:
  - TRANSIENT_PROVIDER_ERROR
- Non-retryable classes:
  - VALIDATION_ERROR
  - TENANT_BOUNDARY_ERROR
  - CHECKSUM_ERROR
  - MANIFEST_ERROR
  - PERMANENT_PROVIDER_ERROR
- Unknown provider error: manual review

## Decision Actions

- PASS
- RETRY
- DLQ
- MANUAL_REVIEW

## DLQ / Manual Review Sınırı

DLQ olur:

- validation required field eksikse
- manifest invalid ise
- permanent provider rejection varsa
- retry limit aşılırsa

Manual review olur:

- tenant boundary violation
- checksum mismatch
- unknown provider error

Retry olur:

- transient provider timeout
- provider rate limit
- retry attempt max limit altında ise

## Kapalı Tutulan Gerçek İşlemler

- LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- LOGO_VALIDATION_RETRY_DLQ_STATUS=READY

## Validation / Retry-DLQ Operation Set

- DECLARE_LOGO_VALIDATION_RETRY_DLQ_CONTRACT
- VALIDATE_LOGO_DELIVERY_ENVELOPE
- VALIDATE_LOGO_CHECKSUM
- VALIDATE_LOGO_MANIFEST
- MAP_LOGO_ERROR_CODE
- DECIDE_LOGO_RETRY_OR_DLQ
- DECIDE_LOGO_MANUAL_REVIEW
- VALIDATE_LOGO_NO_REAL_DELIVERY
- PREPARE_LOGO_ADMIN_OPS_HANDOFF

## Güvenlik Kararı

Bu adım validation / error mapping / retry-DLQ karar modeli üretir.
Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek Logo dosya teslimi yapmaz.
Bu adım Pix2pi ERP tarafına gerçek kayıt yazmaz.

## Bir Sonraki Adım

FAZ 7-8L.8 — Logo Admin / Ops / Manual Review
