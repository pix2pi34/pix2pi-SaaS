# FAZ 7-8M.2 — Mikro File Generation Dry-Run Contract / Export Package Builder Readiness

## Amaç

Bu faz, Pix2pi ERP objelerinden Mikro için export package builder dry-run kontratını kurar.

Bu modül gerçek Mikro API çağrısı yapmaz.
Bu modül gerçek Mikro dosya teslimi yapmaz.
Bu modül gerçek ERP write yapmaz.
Bu modül canlı müşteri verisini Mikro'ya göndermez.

Bu modül sadece dry-run export package üretim kontratını ve paket manifest modelini doğrular.

## Faz Bilgisi

- Phase: FAZ_7_8M_2
- Module: MIKRO_FILE_GENERATION_DRY_RUN_CONTRACT
- Provider ID: mikro
- Provider Name: Mikro
- Builder Mode: EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY
- Direction: PIX2PI_TO_MIKRO
- Source System: PIX2PI_ERP
- Target System: MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- Package Gate: READY_AFTER_TEST_AND_AUDIT_PASS

## Ön Koşullar

Aşağıdaki fazların tamamlanmış olması beklenir:

- FAZ_7_8M_MIKRO_CONNECTOR_FOUNDATION_FINAL_STATUS=PASS
- FAZ_7_8M_1_MIKRO_EXPORT_MAPPING_FINAL_STATUS=PASS
- MIKRO_CONNECTOR_FOUNDATION_GATE=READY
- MIKRO_EXPORT_MAPPING_GATE=READY_AFTER_TEST_AND_AUDIT_PASS

## Kapsam

Bu fazda kurulan dry-run package builder:

1. Mikro dry-run package contract
2. Mikro virtual file naming contract
3. Mikro manifest generation contract
4. Mikro package checksum contract
5. Mikro ERP object mapping bridge
6. tenant guard
7. actor guard
8. correlation guard
9. package id guard
10. empty record guard
11. unsupported ERP object guard
12. secret field forbidden guard
13. real provider API closed guard
14. real file delivery closed guard
15. real ERP write closed guard

## Desteklenen Paket Tipleri

- CUSTOMER package
- VENDOR package
- PRODUCT package
- SERVICE_ITEM package
- SALES_INVOICE package
- PURCHASE_INVOICE package
- STOCK_MOVEMENT package
- ACCOUNTING_VOUCHER package
- TAX_LINE package

## Bilerek Kapalı Tutulanlar

Aşağıdaki gerçek operasyonlar kapalı kalır:

- MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE

## Bu Fazda Bilerek Yapılmayanlar

- gerçek Mikro dosya formatı final sertifikasyonu
- gerçek Mikro API bağlantısı
- gerçek dosya teslimi
- FTP / SFTP / API delivery
- gerçek provider endpoint
- gerçek credential / token / secret kullanımı
- ERP sync worker
- canlı müşteri verisi aktarımı

## Real Implementation Audit Zorunlulukları

Audit şunları doğrulamalıdır:

- doküman var
- config var
- runtime code var
- test code var
- provider directory var
- previous foundation runtime var
- previous mapping runtime var
- phase FAZ_7_8M_2
- provider id mikro
- builder mode EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY
- direction PIX2PI_TO_MIKRO
- target system MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- package builder type var
- dry-run package type var
- manifest type var
- checksum üretimi var
- virtual filename üretimi var
- mapping contract bridge var
- tenant guard var
- actor guard var
- correlation guard var
- package id guard var
- empty record guard var
- unsupported object guard var
- secret forbidden guard var
- real provider API closed guard var
- real file delivery closed guard var
- real ERP write closed guard var
- test çıktısında 7-8M.2, 7-8M.2.x, 7-8M.2.x.x OK görünür

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

