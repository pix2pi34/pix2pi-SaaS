# FAZ 7-8M.5 — Mikro Admin / Ops / Manual Review Readiness

## Amaç

Bu faz, Mikro dry-run connector ailesi için admin/ops/manual review karar kontratını kurar.

Bu modül gerçek Mikro API çağrısı yapmaz.
Bu modül gerçek Mikro dosya teslimi yapmaz.
Bu modül gerçek Mikro provider action çalıştırmaz.
Bu modül gerçek ERP write yapmaz.
Bu modül gerçek manual review queue write yapmaz.
Bu modül canlı müşteri verisini Mikro'ya göndermez.

Bu modül sadece dry-run admin/ops görünümü, manual review item kontratı, operator action contract ve tenant-safe review boundary modelini kurar.

## Faz Bilgisi

- Phase: FAZ_7_8M_5
- Module: MIKRO_ADMIN_OPS_MANUAL_REVIEW
- Provider ID: mikro
- Provider Name: Mikro
- Admin Ops Mode: ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY
- Direction: PIX2PI_TO_MIKRO
- Source System: PIX2PI_ERP
- Target System: MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- Admin Ops Gate: READY_AFTER_TEST_AND_AUDIT_PASS

## Ön Koşullar

Aşağıdaki fazların tamamlanmış olması beklenir:

- FAZ_7_8M_MIKRO_CONNECTOR_FOUNDATION_FINAL_STATUS=PASS
- FAZ_7_8M_1_MIKRO_EXPORT_MAPPING_FINAL_STATUS=PASS
- FAZ_7_8M_2_MIKRO_FILE_GENERATION_DRY_RUN_FINAL_STATUS=PASS
- FAZ_7_8M_3_MIKRO_IMPORT_DELIVERY_FINAL_STATUS=PASS
- FAZ_7_8M_4_MIKRO_VALIDATION_RETRY_DLQ_FINAL_STATUS=PASS

## Kapsam

Bu fazda kurulan readiness kapsamı:

1. Mikro admin/ops contract
2. manual review item model
3. manual review queue status model
4. tenant-safe review boundary
5. operator action contract
6. action allowlist
7. action status transition guard
8. validation decision → review item bridge
9. DLQ decision → review item bridge
10. manual review decision → review item bridge
11. tenant guard
12. actor guard
13. correlation guard
14. review id guard
15. package id guard
16. operator note guard
17. secret/token forbidden guard
18. provider live mode closed guard
19. real provider API closed guard
20. real file delivery closed guard
21. real ERP write closed guard
22. real delivery channel closed guard
23. real operator provider action closed guard

## Supported Dry-Run Operator Actions

- VIEW
- ASSIGN
- MARK_RETRY_DRY_RUN
- MARK_DLQ_DRY_RUN
- RESOLVE_DRY_RUN
- ESCALATE_MANUAL_REVIEW

Bu actionlar sadece kontrat ve dry-run karar üretimi içindir.
Bu fazda gerçek provider action, gerçek dosya gönderimi, gerçek queue write veya gerçek ERP write yapılmaz.

## Manual Review Status Modeli

- OPEN
- ASSIGNED
- RETRY_DRY_RUN
- DLQ_DRY_RUN
- RESOLVED_DRY_RUN
- ESCALATED_MANUAL_REVIEW

## Bilerek Kapalı Tutulanlar

Aşağıdaki gerçek operasyonlar kapalı kalır:

- MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- MIKRO_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- MIKRO_REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- MIKRO_REAL_MANUAL_REVIEW_QUEUE_WRITE_POLICY=NO_REAL_QUEUE_WRITE_IN_THIS_PHASE

## Bu Fazda Bilerek Yapılmayanlar

- gerçek admin UI
- gerçek manual review queue persistence
- gerçek operator action execution
- gerçek Mikro provider action
- gerçek Mikro API retry
- gerçek DLQ queue write
- gerçek ERP write
- canlı müşteri verisi aktarımı

Bunlar ileride admin UI / ops runtime / provider live modüllerinde açılacaktır.

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
- previous import delivery runtime var
- previous validation retry-dlq runtime var
- phase FAZ_7_8M_5
- provider id mikro
- admin ops mode ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY
- direction PIX2PI_TO_MIKRO
- target system MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- admin ops contract type var
- manual review item type var
- manual review request type var
- operator action request type var
- operator action decision type var
- review item creation var
- operator action evaluation var
- tenant-safe boundary var
- action allowlist var
- status transition guard var
- tenant guard var
- actor guard var
- correlation guard var
- review id guard var
- package id guard var
- operator note guard var
- provider live mode closed guard var
- secret forbidden guard var
- real provider API closed guard var
- real file delivery closed guard var
- real ERP write closed guard var
- real delivery channel closed guard var
- real operator provider action closed guard var
- test çıktısında 7-8M.5, 7-8M.5.x, 7-8M.5.x.x OK görünür

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
- gerçek operator provider action kapalı kalmalı
- FAZ 7-9 HOLD durumunda kalmalı

