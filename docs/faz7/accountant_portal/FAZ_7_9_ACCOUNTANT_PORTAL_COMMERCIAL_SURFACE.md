# FAZ 7-9 — Accountant Portal Commercial Surface

## Amaç

Bu modül, muhasebeci portalının ilk ticari yüzeyini kurar.

Kapsam:
- Muhasebeci paketleri
- Firma slot / firma erişim ticari modeli
- Muhasebeci tenant → firma tenant ilişki sınırı
- Paket bazlı export preview yetkisi
- Paraşüt / Logo / Mikro / Zirve dry-run ailelerinin muhasebeci portal yüzeyinde görünmesi
- Billing draft üretimi
- Audit trail

## Bu fazda açık olan şey

Bu faz sadece commercial surface / dry-run readiness fazıdır.

Açık olanlar:
- Paket tanımı
- Firma slot modeli
- Firma erişim ataması
- Export preview metadata
- Billing draft metadata
- Audit event üretimi
- Provider dry-run entitlement görünümü

## Bu fazda kapalı kalan şey

Aşağıdaki tüm live işlemler kapalıdır:

- Gerçek muhasebeci billing
- Gerçek ödeme alma
- Gerçek provider API çağrısı
- Gerçek dosya teslimi
- Gerçek delivery channel
- Gerçek ERP write
- Gerçek müşteri verisi export
- Gerçek operator provider action

## Live gate değerleri

- REAL_ACCOUNTANT_BILLING_STATUS=CLOSED_UNTIL_BILLING_LIVE_MODULE
- REAL_PAYMENT_CAPTURE_STATUS=CLOSED_UNTIL_BILLING_LIVE_MODULE
- REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- REAL_CUSTOMER_DATA_EXPORT_LIVE_STATUS=CLOSED_UNTIL_EXPORT_LIVE_MODULE
- REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Provider aile bağlamı

FAZ 7-8 entegrasyon dry-run ailesi mühürlüdür:

- PARASUT_CONNECTOR_MODULE_FINAL_SEAL_STATUS=SEALED
- LOGO_CONNECTOR_MODULE_FINAL_SEAL_STATUS=SEALED
- MIKRO_CONNECTOR_MODULE_FINAL_SEAL_STATUS=SEALED
- ZIRVE_CONNECTOR_MODULE_FINAL_SEAL_STATUS=SEALED

Bu modül bu provider ailelerini sadece dry-run commercial entitlement olarak yüzeye taşır.

## Acceptance criteria

- Runtime kodu var
- Paket modeli var
- Firma slot ataması var
- Tenant-safe listeleme var
- Billing draft gerçek invoice/payment üretmiyor
- Export preview gerçek müşteri verisi taşımıyor
- Provider API / ERP write / file delivery canlı çağrısı kapalı
- Go test PASS
- Real implementation audit PASS
