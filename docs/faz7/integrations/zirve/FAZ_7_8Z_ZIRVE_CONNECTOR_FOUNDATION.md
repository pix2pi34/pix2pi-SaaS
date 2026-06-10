# FAZ 7-8Z — Zirve Connector Module Foundation

## Amaç

Bu modül, Pix2pi entegrasyon ailesinde Zirve sağlayıcısı için provider identity, capability contract, dry-run sınırı, güvenlik kapıları ve provider live handoff temelini hazırlar.

## Kapsam

- Zirve provider identity
- Zirve capability listesi
- Auth mode işaretleyicileri
- Delivery mode işaretleyicileri
- Sync direction işaretleyicileri
- Dry-run operation decision contract
- Provider live module handoff gate
- Tenant safety policy
- Audit policy
- Secret value policy

## Bilinçli kapalı kalan işler

Aşağıdaki işler bu fazda açılmaz:

- Gerçek Zirve API çağrısı
- Gerçek Zirve dosya gönderimi
- Gerçek ERP write
- Gerçek delivery channel
- Gerçek operator provider action
- Gerçek secret value saklama

## Gate Durumu

- ZIRVE_PROVIDER_LIVE_HANDOFF_GATE=READY_FOR_PROVIDER_LIVE_MODULE
- ZIRVE_PROVIDER_LIVE_MODULE_STATUS=NOT_STARTED
- ZIRVE_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- ZIRVE_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- ZIRVE_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Dosyalar

- Runtime: `internal/platform/integrations/providers/zirve/zirve_foundation.go`
- Test: `internal/platform/integrations/providers/zirve/zirve_foundation_test.go`
- Config: `configs/faz7/integrations/zirve_connector_foundation.json`
- Audit: `scripts/faz7/audit_faz_7_8z_zirve_connector_foundation.sh`
- Evidence: `docs/faz7/evidence/FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_AUDIT.md`

## Sonraki Mantıklı Adım

FAZ 7-8Z.2 — Zirve File Generation Dry-Run Contract / Export Package Builder Readiness.
