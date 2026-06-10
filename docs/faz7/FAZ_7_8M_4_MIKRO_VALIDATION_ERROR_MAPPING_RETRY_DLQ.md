# FAZ 7-8M.4 — Mikro Validation / Error Mapping / Retry-DLQ Readiness

## Amaç

Bu faz, Mikro dry-run import/export paketleri için validation, provider error mapping, retry, DLQ ve manual review karar modelini kurar.

Bu modül gerçek Mikro API çağrısı yapmaz.
Bu modül gerçek Mikro dosya teslimi yapmaz.
Bu modül gerçek Mikro response tüketmez.
Bu modül gerçek ERP write yapmaz.
Bu modül canlı müşteri verisini Mikro'ya göndermez.

Bu modül sadece dry-run validation ve hata sınıflandırma kontratını kurar.

## Faz Bilgisi

- Phase: FAZ_7_8M_4
- Module: MIKRO_VALIDATION_ERROR_MAPPING_RETRY_DLQ
- Provider ID: mikro
- Provider Name: Mikro
- Validation Mode: VALIDATION_RETRY_DLQ_DRY_RUN_ONLY
- Direction: PIX2PI_TO_MIKRO
- Source System: PIX2PI_ERP
- Target System: MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- Validation Gate: READY_AFTER_TEST_AND_AUDIT_PASS

## Ön Koşullar

Aşağıdaki fazların tamamlanmış olması beklenir:

- FAZ_7_8M_MIKRO_CONNECTOR_FOUNDATION_FINAL_STATUS=PASS
- FAZ_7_8M_1_MIKRO_EXPORT_MAPPING_FINAL_STATUS=PASS
- FAZ_7_8M_2_MIKRO_FILE_GENERATION_DRY_RUN_FINAL_STATUS=PASS
- FAZ_7_8M_3_MIKRO_IMPORT_DELIVERY_FINAL_STATUS=PASS

## Kapsam

Bu fazda kurulan readiness kapsamı:

1. Mikro validation retry DLQ contract
2. dry-run package validation
3. checksum validation
4. delivery policy validation
5. provider error mapping
6. retryable / non-retryable classification
7. retry decision
8. retry limit guard
9. DLQ decision
10. manual review decision
11. tenant guard
12. actor guard
13. correlation guard
14. validation id guard
15. secret/token forbidden guard
16. provider live mode closed guard
17. real provider API closed guard
18. real file delivery closed guard
19. real ERP write closed guard
20. real delivery channel closed guard

## Provider Error Mapping

Başlangıç provider hata sınıfları:

- MIKRO_TIMEOUT → RETRYABLE_TEMPORARY
- MIKRO_RATE_LIMIT → RETRYABLE_RATE_LIMIT
- MIKRO_FORMAT_ERROR → NON_RETRYABLE_VALIDATION
- MIKRO_AUTH_FAILED → NON_RETRYABLE_AUTH
- MIKRO_DUPLICATE_RECORD → NON_RETRYABLE_DUPLICATE
- MIKRO_UNKNOWN_ERROR → UNKNOWN_PROVIDER_ERROR

## Retry Politikası

- Max Attempts: 3
- Strategy: EXPONENTIAL_BACKOFF_DRY_RUN
- Initial Backoff Seconds: 30
- Max Backoff Seconds: 300
- Retryable classes: RETRYABLE_TEMPORARY, RETRYABLE_RATE_LIMIT
- Non-retryable validation/auth/duplicate errors retry edilmez

## DLQ Politikası

DLQ kararı şu durumlarda oluşur:

- retryable error max attempt sonrası
- non-retryable validation error
- duplicate record error
- invalid package checksum
- invalid dry-run package manifest
- unsupported package/validation state

## Manual Review Politikası

Manual review kararı şu durumlarda oluşur:

- auth/credential class error
- unknown provider error
- policy uncertainty
- operator intervention required state

## Bilerek Kapalı Tutulanlar

Aşağıdaki gerçek operasyonlar kapalı kalır:

- MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- MIKRO_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Bu Fazda Bilerek Yapılmayanlar

- gerçek Mikro API response parse
- gerçek Mikro retry job enqueue
- gerçek DLQ queue write
- gerçek manual review UI
- gerçek file delivery
- gerçek ERP write
- canlı müşteri verisi aktarımı

Bu işler sonraki runtime/live/ops modüllerde açılacaktır.

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
- phase FAZ_7_8M_4
- provider id mikro
- validation mode VALIDATION_RETRY_DLQ_DRY_RUN_ONLY
- direction PIX2PI_TO_MIKRO
- target system MIKRO_ACCOUNTING_IMPORT_DRY_RUN
- validation contract type var
- validation request type var
- validation decision type var
- provider error mapping type var
- retry policy type var
- DLQ decision var
- manual review decision var
- package checksum validation var
- retry limit guard var
- tenant guard var
- actor guard var
- correlation guard var
- validation id guard var
- provider live mode closed guard var
- secret forbidden guard var
- real provider API closed guard var
- real file delivery closed guard var
- real ERP write closed guard var
- real delivery channel closed guard var
- test çıktısında 7-8M.4, 7-8M.4.x, 7-8M.4.x.x OK görünür

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

