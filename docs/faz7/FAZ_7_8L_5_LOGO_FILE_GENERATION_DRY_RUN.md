# FAZ 7-8L.5 — Logo File Generation Dry-Run

## Amaç

Bu adım, FAZ 7-8L.4 Logo Export Mapping Contract üzerinden Logo import/export dry-run dosya içeriği üretimini simüle eder.

Bu adımda gerçek Logo bağlantısı açılmaz.
Bu adımda gerçek dosya teslimi yapılmaz.
Bu adımda gerçek ERP write yapılmaz.
Bu adımda dry-run dosya içeriği sadece runtime model içinde üretilir.

## Bağımlılık

FAZ 7-8L.1 Logo Connector Foundation / Provider Identity tamamlanmış olmalıdır.
FAZ 7-8L.2 Logo Live Contract / API-File Contract Readiness tamamlanmış olmalıdır.
FAZ 7-8L.3 Logo Credential / Secret Reference Readiness tamamlanmış olmalıdır.
FAZ 7-8L.4 Logo Export Mapping Contract tamamlanmış olmalıdır.

Beklenen dosyalar:

internal/platform/integrations/providers/logo/logo_foundation.go
internal/platform/integrations/providers/logo/logo_live_contract.go
internal/platform/integrations/providers/logo/logo_credential.go
internal/platform/integrations/providers/logo/logo_export_mapping.go

## Dizin Standardı

Logo provider-specific dosyaları şu dizinde tutulur:

internal/platform/integrations/providers/logo/

Bu adımın dosyaları:

internal/platform/integrations/providers/logo/logo_file_generation.go
internal/platform/integrations/providers/logo/logo_file_generation_test.go

## Kapsam

- Logo file generation dry-run contract
- Mapping contract dependency validation
- Dry-run export input model
- Dry-run Logo file content generation
- Dry-run import package manifest
- Checksum calculation
- Tenant / correlation / idempotency guard
- No external call guard
- No real file delivery guard
- No ERP write guard
- Config artifact
- Go runtime model
- Go unit tests
- Real implementation audit

## Modül Kimliği

- Module: FAZ_7_8L
- Step: FAZ_7_8L.5
- Provider code: LOGO
- Provider name: Logo
- Connector code: logo_connector
- Connector family: accounting_export_connector
- Runtime mode: DRY_RUN
- File generation mode: FILE_GENERATION_DRY_RUN_ONLY
- Target system: LOGO_ACCOUNTING_IMPORT_DRY_RUN

## Dry-Run Dosya İçeriği

Dry-run dosya formatı gerçek Logo formatı değildir.
Bu format, mapping ve import package hazırlığını doğrulamak için kullanılır.

Dry-run satır tipleri:

- HEADER
- LINE
- PARTY
- TAX
- INVOICE
- MANIFEST

## Zorunlu Input Alanları

- tenant_id
- correlation_id
- idempotency_key
- document_no
- document_date
- journal_lines
- party_account
- invoice_summary

## Üretilen Dry-Run Package Alanları

- package_id
- tenant_id
- correlation_id
- idempotency_key
- file_name
- file_format
- checksum_sha256
- byte_size
- dry_run_only
- delivery_allowed=false

## Kapalı Tutulan Gerçek İşlemler

- LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- LOGO_DRY_RUN_FILE_GENERATION_STATUS=READY
- LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE

## File Generation Operation Set

- PREPARE_LOGO_DRY_RUN_EXPORT_INPUT
- GENERATE_LOGO_DRY_RUN_FILE
- VALIDATE_LOGO_DRY_RUN_FILE_SCHEMA
- CALCULATE_LOGO_DRY_RUN_CHECKSUM
- PREPARE_LOGO_IMPORT_PACKAGE_DRY_RUN
- VALIDATE_LOGO_NO_REAL_DELIVERY
- PREPARE_LOGO_IMPORT_DELIVERY_HANDOFF

## Güvenlik Kararı

Bu adım dry-run dosya içeriği üretir.
Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek Logo dosya teslimi yapmaz.
Bu adım Pix2pi ERP tarafına gerçek kayıt yazmaz.

## Bir Sonraki Adım

FAZ 7-8L.6 — Logo Import Package / Delivery Contract
