# FAZ 7-8M.1 — Mikro Export Mapping / ERP Object Contract Readiness

## Amaç

Bu faz, Pix2pi ERP objelerinin Mikro export kontratına dry-run seviyesinde nasıl eşleneceğini tanımlar.

Bu modül gerçek Mikro API çağrısı yapmaz.
Bu modül gerçek Mikro dosyası üretip göndermez.
Bu modül gerçek ERP write yapmaz.
Bu modül canlı müşteri verisini Mikro'ya taşımaz.

## Faz Bilgisi

- Phase: FAZ_7_8M_1
- Module: MIKRO_EXPORT_MAPPING_ERP_OBJECT_CONTRACT
- Provider ID: mikro
- Provider Name: Mikro
- Mapping Mode: ERP_OBJECT_EXPORT_MAPPING_CONTRACT_ONLY
- Direction: PIX2PI_TO_MIKRO
- Source System: PIX2PI_ERP
- Target System: MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- Mapping Gate: READY_AFTER_TEST_AND_AUDIT_PASS

## Ön Koşul

FAZ 7-8M Mikro Connector Module Foundation tamamlanmış olmalıdır.

Beklenen foundation durumu:

- FAZ_7_8M_MIKRO_CONNECTOR_FOUNDATION_FINAL_STATUS=PASS
- MIKRO_CONNECTOR_FOUNDATION_GATE=READY
- MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE

## Kapsam

Bu fazda kurulan Mikro ERP object mapping kontratı:

1. CUSTOMER → Mikro cari hesap kartı
2. VENDOR → Mikro cari hesap kartı
3. PRODUCT → Mikro stok kartı
4. SERVICE_ITEM → Mikro hizmet kartı
5. SALES_INVOICE → Mikro satış faturası
6. PURCHASE_INVOICE → Mikro alış faturası
7. STOCK_MOVEMENT → Mikro stok hareketi
8. ACCOUNTING_VOUCHER → Mikro muhasebe fişi
9. TAX_LINE → Mikro KDV satırı

## Zorunlu Guardlar

Aşağıdaki gerçek operasyonlar kapalı kalır:

- MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE

Aşağıdaki context alanları zorunludur:

- tenant_id
- actor_user_id
- correlation_id
- erp_object_type

Aşağıdaki hassas alanlar mapping sözleşmesine giremez:

- client_secret
- access_token
- refresh_token
- password
- real_provider_endpoint
- real_delivery_endpoint

## Bu Fazda Bilerek Yapılmayanlar

- Mikro gerçek API bağlantısı
- Mikro gerçek dosya formatı final üretimi
- Mikro gerçek dosya gönderimi
- Mikro canlı endpoint kullanımı
- Mikro credential saklama
- ERP write / sync worker
- import delivery runtime

Bu işler ileride ayrı modüllerde açılacaktır.

## Real Implementation Audit Zorunlulukları

Audit şunları doğrulamalıdır:

- doküman var
- config var
- runtime code var
- test code var
- provider directory var
- phase FAZ_7_8M_1
- provider id mikro
- mapping mode ERP_OBJECT_EXPORT_MAPPING_CONTRACT_ONLY
- direction PIX2PI_TO_MIKRO
- source system PIX2PI_ERP
- target system MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- CUSTOMER mapping var
- VENDOR mapping var
- PRODUCT mapping var
- SERVICE_ITEM mapping var
- SALES_INVOICE mapping var
- PURCHASE_INVOICE mapping var
- STOCK_MOVEMENT mapping var
- ACCOUNTING_VOUCHER mapping var
- TAX_LINE mapping var
- tenant guard var
- actor guard var
- correlation guard var
- unsupported object guard var
- secret forbidden guard var
- real provider API closed guard var
- real file delivery closed guard var
- real ERP write closed guard var
- test çıktısında 7-8M.1, 7-8M.1.x, 7-8M.1.x.x OK görünür

## Çıkış Kapısı

Bu fazın başarılı sayılması için:

- Go test PASS olmalı
- Real implementation audit PASS olmalı
- REQUIRED_FAIL=0 olmalı
- final status sayaçlardan türemeli
- gerçek Mikro API kapalı kalmalı
- gerçek dosya teslimi kapalı kalmalı
- gerçek ERP write kapalı kalmalı
- FAZ 7-9 HOLD durumunda kalmalı

