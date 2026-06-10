# FAZ 7-8L.4 — Logo Export Mapping Contract

## Amaç

Bu adım, Pix2pi muhasebe/export modelinin Logo tarafına nasıl eşleneceğini tanımlar.

Bu adımda gerçek Logo bağlantısı açılmaz.
Bu adımda gerçek dosya üretilmez.
Bu adımda gerçek dosya gönderimi yapılmaz.
Bu adımda gerçek ERP write yapılmaz.

## Bağımlılık

FAZ 7-8L.1 Logo Connector Foundation / Provider Identity tamamlanmış olmalıdır.
FAZ 7-8L.2 Logo Live Contract / API-File Contract Readiness tamamlanmış olmalıdır.
FAZ 7-8L.3 Logo Credential / Secret Reference Readiness tamamlanmış olmalıdır.

Beklenen dosyalar:

internal/platform/integrations/providers/logo/logo_foundation.go
internal/platform/integrations/providers/logo/logo_live_contract.go
internal/platform/integrations/providers/logo/logo_credential.go

## Dizin Standardı

Logo provider-specific dosyaları şu dizinde tutulur:

internal/platform/integrations/providers/logo/

Bu adımın dosyaları:

internal/platform/integrations/providers/logo/logo_export_mapping.go
internal/platform/integrations/providers/logo/logo_export_mapping_test.go

## Kapsam

- Logo export mapping contract
- Pix2pi journal header mapping
- Pix2pi journal line mapping
- Cari / müşteri / tedarikçi mapping
- Vergi / KDV mapping
- Fatura özet mapping
- TDHP hesap mapping
- Tenant / correlation / idempotency mapping
- Mapping validation
- File generation handoff readiness
- Real provider/file/ERP write closed guards
- Config artifact
- Go runtime model
- Go unit tests
- Real implementation audit

## Modül Kimliği

- Module: FAZ_7_8L
- Step: FAZ_7_8L.4
- Provider code: LOGO
- Provider name: Logo
- Connector code: logo_connector
- Connector family: accounting_export_connector
- Runtime mode: DRY_RUN
- Mapping mode: EXPORT_MAPPING_CONTRACT_ONLY
- Mapping direction: PIX2PI_TO_LOGO
- Target system: LOGO_ACCOUNTING_IMPORT_DRY_RUN

## Mapping Entity Set

- PIX2PI_JOURNAL_HEADER -> LOGO_FICHE_HEADER
- PIX2PI_JOURNAL_LINE -> LOGO_FICHE_LINE
- PIX2PI_PARTY_ACCOUNT -> LOGO_CARI_CARD
- PIX2PI_TAX_DETAIL -> LOGO_TAX_LINE
- PIX2PI_INVOICE_SUMMARY -> LOGO_INVOICE_REFERENCE

## Zorunlu Mapping Alanları

- tenant_id
- correlation_id
- idempotency_key
- document_no
- document_date
- account_code
- debit_amount
- credit_amount
- currency_code
- tax_rate
- tax_amount
- party_tax_no

## TDHP / Muhasebe Kural Mapping

Bu adımda TDHP hesap kodu eşleştirme sözleşmesi dry-run seviyede tanımlanır.

Örnek dry-run kurallar:

- SATIS_FATURASI -> debit 120, credit 600, tax 391
- ALIS_FATURASI -> debit 153, credit 320, tax 191
- TAHSILAT -> debit 100, credit 120
- ODEME -> debit 320, credit 100

Bu kurallar gerçek Logo dosyasına yazılmaz. Sadece mapping contract olarak hazır tutulur.

## Kapalı Tutulan Gerçek İşlemler

- LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- LOGO_REAL_FILE_GENERATION_STATUS=CLOSED_UNTIL_FILE_GENERATION_DRY_RUN_MODULE
- LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE

## Export Mapping Operation Set

- DECLARE_LOGO_EXPORT_MAPPING
- VALIDATE_LOGO_REQUIRED_FIELDS
- VALIDATE_LOGO_TDHP_ACCOUNT_MAPPING
- VALIDATE_LOGO_TAX_MAPPING
- VALIDATE_LOGO_TENANT_MAPPING_BOUNDARY
- PREPARE_LOGO_FILE_GENERATION_HANDOFF
- PREPARE_LOGO_IMPORT_PACKAGE_MAPPING_HANDOFF

## Güvenlik Kararı

Bu adım mapping contract üretir.
Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek Logo dosyası üretmez.
Bu adım gerçek Logo dosya teslimi yapmaz.
Bu adım Pix2pi ERP tarafına gerçek kayıt yazmaz.

## Bir Sonraki Adım

FAZ 7-8L.5 — Logo File Generation Dry-Run
