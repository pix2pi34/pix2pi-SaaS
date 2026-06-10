# FAZ 7-8L.6 — Logo Import Package / Delivery Contract

## Amaç

Bu adım, FAZ 7-8L.5 Logo File Generation Dry-Run çıktısının Logo tarafına nasıl teslim edileceğini sözleşme seviyesinde tanımlar.

Bu adım gerçek Logo dosya gönderimi yapmaz.
Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek SFTP / API / manuel upload teslimi yapmaz.
Bu adım gerçek ERP write yapmaz.

## Bağımlılık

FAZ 7-8L.1 Logo Connector Foundation / Provider Identity tamamlanmış olmalıdır.
FAZ 7-8L.2 Logo Live Contract / API-File Contract Readiness tamamlanmış olmalıdır.
FAZ 7-8L.3 Logo Credential / Secret Reference Readiness tamamlanmış olmalıdır.
FAZ 7-8L.4 Logo Export Mapping Contract tamamlanmış olmalıdır.
FAZ 7-8L.5 Logo File Generation Dry-Run tamamlanmış olmalıdır.

Beklenen dosyalar:

internal/platform/integrations/providers/logo/logo_foundation.go
internal/platform/integrations/providers/logo/logo_live_contract.go
internal/platform/integrations/providers/logo/logo_credential.go
internal/platform/integrations/providers/logo/logo_export_mapping.go
internal/platform/integrations/providers/logo/logo_file_generation.go

## Dizin Standardı

Logo provider-specific dosyaları şu dizinde tutulur:

internal/platform/integrations/providers/logo/

Bu adımın dosyaları:

internal/platform/integrations/providers/logo/logo_import_delivery.go
internal/platform/integrations/providers/logo/logo_import_delivery_test.go

## Kapsam

- Logo import package delivery contract
- Dry-run delivery envelope
- Delivery channel placeholder contract
- Manual upload placeholder
- SFTP placeholder
- Provider API placeholder
- No real delivery guard
- No external call guard
- No ERP write guard
- Package checksum / manifest carry-forward
- Tenant / correlation / idempotency carry-forward
- Delivery handoff readiness
- Config artifact
- Go runtime model
- Go unit tests
- Real implementation audit

## Modül Kimliği

- Module: FAZ_7_8L
- Step: FAZ_7_8L.6
- Provider code: LOGO
- Provider name: Logo
- Connector code: logo_connector
- Connector family: accounting_export_connector
- Runtime mode: DRY_RUN
- Delivery mode: IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY
- Target system: LOGO_ACCOUNTING_IMPORT_DRY_RUN

## Delivery Channel Placeholder Set

Bu adımda gerçek delivery kanalı açılmaz.

Placeholder kanallar:

- MANUAL_UPLOAD_PLACEHOLDER
- SFTP_PLACEHOLDER
- PROVIDER_API_PLACEHOLDER

Her kanal için:

- dry_run_only=true
- real_delivery_allowed=false
- external_call_allowed=false
- requires_approval=true

## Delivery Envelope Alanları

- delivery_id
- package_id
- tenant_id
- correlation_id
- idempotency_key
- channel
- status
- file_name
- checksum_sha256
- manifest
- dry_run_only=true
- delivery_allowed=false
- external_call_allowed=false
- erp_write_allowed=false

## Kapalı Tutulan Gerçek İşlemler

- LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- LOGO_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Import Delivery Operation Set

- DECLARE_LOGO_IMPORT_DELIVERY_CONTRACT
- DECLARE_LOGO_DELIVERY_CHANNEL_PLACEHOLDERS
- VALIDATE_LOGO_DRY_RUN_PACKAGE_FOR_DELIVERY
- PREPARE_LOGO_DRY_RUN_DELIVERY_ENVELOPE
- VALIDATE_LOGO_NO_REAL_DELIVERY
- VALIDATE_LOGO_DELIVERY_TENANT_BOUNDARY
- PREPARE_LOGO_VALIDATION_RETRY_DLQ_HANDOFF

## Güvenlik Kararı

Bu adım delivery contract üretir.
Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek Logo dosya teslimi yapmaz.
Bu adım Pix2pi ERP tarafına gerçek kayıt yazmaz.

## Bir Sonraki Adım

FAZ 7-8L.7 — Logo Validation / Error Mapping / Retry-DLQ
