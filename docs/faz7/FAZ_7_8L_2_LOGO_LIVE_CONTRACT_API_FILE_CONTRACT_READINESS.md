# FAZ 7-8L.2 — Logo Live Contract / API-File Contract Readiness

## Amaç

Bu adım, Logo Connector modülünün gerçek sağlayıcıya geçmeden önce ihtiyaç duyacağı API contract ve file import/export contract sınırlarını tanımlar.

Bu adımda gerçek Logo bağlantısı açılmaz.
Bu adımda gerçek dosya gönderimi yapılmaz.
Bu adımda gerçek ERP write yapılmaz.

## Bağımlılık

FAZ 7-8L.1 Logo Connector Foundation / Provider Identity tamamlanmış olmalıdır.

Beklenen foundation dosyaları:

internal/platform/integrations/providers/logo/logo_foundation.go
internal/platform/integrations/providers/logo/logo_foundation_test.go

## Dizin Standardı

Logo provider-specific dosyaları şu dizinde tutulur:

internal/platform/integrations/providers/logo/

Bu adımın dosyaları:

internal/platform/integrations/providers/logo/logo_live_contract.go
internal/platform/integrations/providers/logo/logo_live_contract_test.go

## Kapsam

- Logo live contract readiness
- Logo API contract declaration
- Logo file import/export contract declaration
- Dry-run only contract mode
- External call deny guard
- File delivery deny guard
- ERP write deny guard
- Provider live handoff ön şartları
- Config artifact
- Go runtime model
- Go unit tests
- Real implementation audit

## Modül Kimliği

- Module: FAZ_7_8L
- Step: FAZ_7_8L.2
- Provider code: LOGO
- Provider name: Logo
- Connector code: logo_connector
- Connector family: accounting_export_connector
- Runtime mode: DRY_RUN
- Contract mode: DRY_RUN_CONTRACT_ONLY

## API Contract

API contract bu adımda sadece deklarasyon seviyesindedir.

- API contract declared: true
- Real API call allowed: false
- Auth reference required: true
- Base URL required for live module: true
- Tenant scope required: true
- Idempotency key required: true
- Correlation id required: true

## File Contract

Logo tarafı dosya/import paketi tabanlı akışa hazır olacak şekilde sözleşme oluşturulur.

- File contract declared: true
- Real file delivery allowed: false
- Import package validation required: true
- Tenant scope required: true
- Idempotency key required: true
- Correlation id required: true
- File checksum required: true

## Kapalı Tutulan Gerçek İşlemler

- LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE

## Dry-Run Contract Operation Set

- DECLARE_LOGO_API_CONTRACT
- DECLARE_LOGO_FILE_CONTRACT
- VALIDATE_LOGO_LIVE_CONTRACT
- PREPARE_LOGO_AUTH_REFERENCE_REQUIREMENTS
- PREPARE_LOGO_IMPORT_PACKAGE_CONTRACT
- PREPARE_LOGO_LIVE_HANDOFF_REQUIREMENTS

## Provider Live Handoff Ön Şartları

Gerçek provider/live modülüne geçmeden önce ayrıca açılması gereken kapılar:

- Logo provider dokümantasyonu doğrulandı
- Logo API veya file import yöntemi netleşti
- Legal/finance/security onayı alındı
- Secret reference / credential vault hazırlandı
- Dry-run mapping tamamlandı
- File generation dry-run tamamlandı
- Import package delivery contract tamamlandı
- Validation / retry / DLQ tamamlandı
- Admin / ops / manual review tamamlandı
- E2E dry-run tamamlandı

## Güvenlik Kararı

Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek Logo dosya teslimi yapmaz.
Bu adım Pix2pi ERP tarafına gerçek kayıt yazmaz.

## Bir Sonraki Adım

FAZ 7-8L.3 — Logo Credential / Secret Reference Readiness
