# FAZ 7-8L.1 — Logo Connector Foundation / Provider Identity

## Amaç

Bu adım, FAZ 7-8 entegrasyon ailesi içinde Logo Connector modülünün temel provider kimliğini ve dry-run güvenlik sınırlarını kurar.

Bu adımda gerçek Logo bağlantısı açılmaz. Gerçek dosya gönderimi yapılmaz. Gerçek ERP write yapılmaz.

## Dizin Standardı

Logo provider-specific dosyaları runtime içine yazılmaz.

Doğru dizin:

internal/platform/integrations/providers/logo/

Doğru dosyalar:

internal/platform/integrations/providers/logo/logo_foundation.go
internal/platform/integrations/providers/logo/logo_foundation_test.go

## Kapsam

- Logo provider identity
- Logo connector family identity
- Dry-run runtime mode
- Capability declaration
- Operation declaration
- Provider live handoff sınırları
- Gerçek bağlantı kapalı statüleri
- Config artifact
- Go runtime model
- Go unit tests
- Real implementation audit

## Modül Kimliği

- Module: FAZ_7_8L
- Step: FAZ_7_8L.1
- Provider code: LOGO
- Provider name: Logo
- Connector code: logo_connector
- Connector family: accounting_export_connector
- Runtime mode: DRY_RUN

## Kapalı Tutulan Gerçek İşlemler

- LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE

## Capability Set

- EXPORT_MAPPING_CONTRACT
- FILE_GENERATION_DRY_RUN
- IMPORT_PACKAGE_PREPARATION
- VALIDATION_ERROR_MAPPING
- RETRY_DLQ_READINESS
- ADMIN_OPS_MANUAL_REVIEW
- E2E_DRY_RUN_FLOW
- PROVIDER_LIVE_HANDOFF_GATE

## Dry-Run Operation Set

- BUILD_EXPORT_MODEL
- GENERATE_LOGO_DRY_RUN_FILE
- PREPARE_IMPORT_PACKAGE
- VALIDATE_IMPORT_PACKAGE
- MAP_LOGO_ERROR
- CREATE_MANUAL_REVIEW_ITEM
- RUN_E2E_DRY_RUN
- PREPARE_PROVIDER_LIVE_HANDOFF

## Güvenlik Kararı

Bu foundation adımı sadece provider identity ve dry-run sözleşmesini kurar.

Gerçek Logo API, gerçek Logo dosya transferi, gerçek Logo import teslimi ve gerçek Pix2pi ERP write bu adımda kapalıdır.

## Bir Sonraki Adım

FAZ 7-8L.2 — Logo Live Contract / API-File Contract Readiness
