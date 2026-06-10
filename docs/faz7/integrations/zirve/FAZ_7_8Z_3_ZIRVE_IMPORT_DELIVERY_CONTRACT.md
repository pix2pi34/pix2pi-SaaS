# FAZ 7-8Z.3 — Zirve Import Package / Delivery Contract Readiness

## Amaç

Bu adım, FAZ 7-8Z.2 içinde üretilen Zirve dry-run export paketini gerçek sisteme göndermeden teslim edilebilir import package delivery contract haline getirir.

Bu fazda gerçek dosya gönderimi yapılmaz. Delivery channel sadece placeholder olarak tanımlanır.

## Kapsam

- 7-8Z.2 dry-run export package doğrulaması
- Import delivery contract oluşturma
- Delivery manifest artifact
- Delivery handoff artifact
- Delivery audit decision artifact
- Package artifact fingerprint SHA256
- Tenant/export run/correlation/delivery run zorunlu alan doğrulaması
- Delivery channel placeholder guard
- Real provider API deny guard
- Real file delivery deny guard
- Real delivery channel deny guard
- Real ERP write deny guard
- Real operator provider action deny guard

## Upstream Paket Şartı

Bu modül sadece şu upstream paketi kabul eder:

- module_code: `FAZ_7_8Z_2`
- file_generation_mode: `EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY`
- target_system: `ZIRVE_ACCOUNTING_IMPORT_DRY_RUN`
- required_artifacts:
  - `manifest.json`
  - `objects.ndjson`
  - `validation_report.json`
  - `audit_decision.json`

## Delivery Contract Artifact Seti

- `delivery_manifest.json`
- `delivery_handoff.json`
- `delivery_audit_decision.json`

## Bilinçli Kapalı Kalan Gerçek İşlemler

Aşağıdaki gerçek işlemler bu fazda açılmaz:

- Gerçek Zirve API çağrısı
- Gerçek Zirve dosya gönderimi
- Gerçek delivery channel
- Gerçek ERP write
- Gerçek operator provider action
- Gerçek external delivery attempt
- Gerçek secret value kullanımı

## Gate Durumu

- ZIRVE_IMPORT_DELIVERY_CONTRACT_MODE=IMPORT_PACKAGE_DELIVERY_CONTRACT_DRY_RUN_ONLY
- ZIRVE_IMPORT_DELIVERY_CONTRACT_STATUS=READY_DRY_RUN_ONLY
- ZIRVE_DELIVERY_CHANNEL_STATUS=PLACEHOLDER_ONLY
- ZIRVE_DRY_RUN_DELIVERY_POLICY=NO_EXTERNAL_DELIVERY_IN_THIS_PHASE
- ZIRVE_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- ZIRVE_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- ZIRVE_REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Dosyalar

- Runtime: `internal/platform/integrations/providers/zirve/zirve_import_delivery.go`
- Test: `internal/platform/integrations/providers/zirve/zirve_import_delivery_test.go`
- Config: `configs/faz7/integrations/zirve_import_delivery_contract.json`
- Audit: `scripts/faz7/audit_faz_7_8z_3_zirve_import_delivery_contract.sh`
- Evidence: `docs/faz7/evidence/FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT_REAL_IMPLEMENTATION_AUDIT.md`

## Sonraki Mantıklı Adım

FAZ 7-8Z.4 — Zirve Validation / Error Mapping / Retry-DLQ.
