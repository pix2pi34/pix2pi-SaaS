# FAZ 7-8Z.2 — Zirve File Generation Dry-Run Contract / Export Package Builder Readiness

## Amaç

Bu adım, Zirve connector ailesinde Pix2pi verilerinin Zirve muhasebe/import hedefi için dry-run export package olarak hazırlanmasını sağlar.

Bu fazda üretilen paket gerçek sisteme gönderilmez. Sadece in-memory/auditable package contract hazırlanır ve test edilir.

## Kapsam

- Pix2pi → Zirve dry-run export package builder
- Tenant/correlation/export run zorunlu alan doğrulaması
- Desteklenen object type sözleşmesi
- Desteklenen operation sözleşmesi
- Manifest artifact
- Objects NDJSON artifact
- Validation report artifact
- Audit decision artifact
- SHA256 artifact bütünlük izi
- Dry-run-only guard
- Real file delivery deny guard
- Real ERP write deny guard
- Real delivery channel deny guard

## Dry-run Artifact Seti

- `manifest.json`
- `objects.ndjson`
- `validation_report.json`
- `audit_decision.json`

## Bilinçli Kapalı Kalan Gerçek İşlemler

Aşağıdaki gerçek işlemler bu fazda açılmaz:

- Gerçek Zirve API çağrısı
- Gerçek Zirve dosya gönderimi
- Gerçek delivery channel
- Gerçek ERP write
- Gerçek operator provider action
- Gerçek secret value kullanımı

## Gate Durumu

- ZIRVE_FILE_GENERATION_MODE=EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY
- ZIRVE_DRY_RUN_DELIVERY_POLICY=NO_EXTERNAL_DELIVERY_IN_THIS_PHASE
- ZIRVE_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- ZIRVE_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- ZIRVE_REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Dosyalar

- Runtime: `internal/platform/integrations/providers/zirve/zirve_file_generation.go`
- Test: `internal/platform/integrations/providers/zirve/zirve_file_generation_test.go`
- Config: `configs/faz7/integrations/zirve_file_generation_dry_run.json`
- Audit: `scripts/faz7/audit_faz_7_8z_2_zirve_file_generation_dry_run.sh`
- Evidence: `docs/faz7/evidence/FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_AUDIT.md`

## Sonraki Mantıklı Adım

FAZ 7-8Z.3 — Zirve Import Package / Delivery Contract Readiness.
