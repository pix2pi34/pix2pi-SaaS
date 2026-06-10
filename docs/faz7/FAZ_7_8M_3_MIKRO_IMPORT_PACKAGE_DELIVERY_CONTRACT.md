# FAZ 7-8M.3 — Mikro Import Package / Delivery Contract Readiness

## Amaç

Bu faz, Mikro için üretilen dry-run export paketinin import package / delivery contract seviyesinde doğrulanmasını sağlar.

Bu modül gerçek Mikro API çağrısı yapmaz.
Bu modül gerçek Mikro dosya teslimi yapmaz.
Bu modül gerçek SFTP / FTP / API delivery çalıştırmaz.
Bu modül gerçek ERP write yapmaz.
Bu modül canlı müşteri verisini Mikro'ya göndermez.

Bu modül sadece dry-run paket teslimat kontratını, receipt modelini, channel placeholderlarını ve güvenlik guardlarını kurar.

## Faz Bilgisi

- Phase: FAZ_7_8M_3
- Module: MIKRO_IMPORT_PACKAGE_DELIVERY_CONTRACT
- Provider ID: mikro
- Provider Name: Mikro
- Delivery Contract Mode: IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY
- Delivery Runtime Mode: DRY_RUN_DELIVERY_PLACEHOLDER_ONLY
- Direction: PIX2PI_TO_MIKRO
- Source System: PIX2PI_ERP
- Target System: MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- Delivery Gate: READY_AFTER_TEST_AND_AUDIT_PASS

## Ön Koşullar

Aşağıdaki fazların tamamlanmış olması beklenir:

- FAZ_7_8M_MIKRO_CONNECTOR_FOUNDATION_FINAL_STATUS=PASS
- FAZ_7_8M_1_MIKRO_EXPORT_MAPPING_FINAL_STATUS=PASS
- FAZ_7_8M_2_MIKRO_FILE_GENERATION_DRY_RUN_FINAL_STATUS=PASS
- MIKRO_CONNECTOR_FOUNDATION_GATE=READY
- MIKRO_EXPORT_MAPPING_GATE=READY_AFTER_TEST_AND_AUDIT_PASS
- MIKRO_FILE_GENERATION_GATE=READY_AFTER_TEST_AND_AUDIT_PASS

## Kapsam

Bu fazda kurulan teslimat kontratı:

1. Mikro dry-run import package delivery contract
2. delivery request model
3. delivery receipt model
4. delivery channel placeholder modeli
5. package manifest checksum verification
6. virtual content verification
7. tenant guard
8. actor guard
9. correlation guard
10. delivery id guard
11. package id guard
12. empty package guard
13. unsupported channel guard
14. provider live mode closed guard
15. secret/token forbidden guard
16. real provider API closed guard
17. real file delivery closed guard
18. real ERP write closed guard

## Desteklenen Dry-Run Delivery Channel Placeholderları

- DRY_RUN_MANIFEST_ONLY
- MANUAL_REVIEW_PLACEHOLDER
- SFTP_PLACEHOLDER
- API_PLACEHOLDER

Bu channel değerleri sadece kontrat/placeholder olarak tanımlıdır.
Bu fazda hiçbir gerçek dış teslimat yapılmaz.

## Bilerek Kapalı Tutulanlar

Aşağıdaki gerçek operasyonlar kapalı kalır:

- MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- MIKRO_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Bu Fazda Bilerek Yapılmayanlar

- gerçek Mikro import dosyası gönderimi
- gerçek Mikro API upload
- gerçek SFTP / FTP delivery
- gerçek provider endpoint kullanımı
- gerçek credential / token / secret kullanımı
- ERP write / sync worker
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
- previous file generation runtime var
- phase FAZ_7_8M_3
- provider id mikro
- delivery contract mode IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY
- runtime mode DRY_RUN_DELIVERY_PLACEHOLDER_ONLY
- direction PIX2PI_TO_MIKRO
- target system MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- delivery request type var
- delivery receipt type var
- delivery decision type var
- package checksum verification var
- virtual content verification var
- delivery channel validation var
- tenant guard var
- actor guard var
- correlation guard var
- delivery id guard var
- package id guard var
- unsupported channel guard var
- provider live mode closed guard var
- secret forbidden guard var
- real provider API closed guard var
- real file delivery closed guard var
- real ERP write closed guard var
- test çıktısında 7-8M.3, 7-8M.3.x, 7-8M.3.x.x OK görünür

## Çıkış Kapısı

Bu fazın başarılı sayılması için:

- Go test PASS olmalı
- Real implementation audit PASS olmalı
- REQUIRED_FAIL=0 olmalı
- final status sayaçlardan türemeli
- gerçek Mikro API kapalı kalmalı
- gerçek dosya teslimi kapalı kalmalı
- gerçek ERP write kapalı kalmalı
- gerçek delivery channel kapalı kalmalı
- FAZ 7-9 HOLD durumunda kalmalı

