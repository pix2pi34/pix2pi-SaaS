# 203 — FAZ 4-16.2.6 Import Testleri

## Amaç

FAZ 4-R pilot import bloğunda yapılan cari, ürün/stok, fiş/hareket, mapping/transform ve validation raporu adımlarını tek import test suite altında kapatır.

Bu adım 198–202 import zincirinin final test kapısıdır.

## Kapsam

Import testleri aşağıdaki test ailelerini kapsar:

- CUSTOMER_IMPORT_TEST
- PRODUCT_STOCK_IMPORT_TEST
- RECEIPT_MOVEMENT_IMPORT_TEST
- MAPPING_TRANSFORM_TEST
- IMPORT_VALIDATION_REPORT_TEST
- CROSS_IMPORT_REFERENCE_TEST
- DRY_RUN_COMMIT_GUARD_TEST
- CLOSED_EXTERNAL_POLICY_TEST
- COUNTER_BASED_FINAL_STATUS_TEST

## Ana Kural

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Bu adım gerçek DB commit yapmaz.

Bu adım import zincirinin test suite standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Import test suite PASS sayılırsa:

- suite_status = READY olmalıdır.
- test_mode = DRY_RUN olmalıdır.
- commit_requested = false olmalıdır.
- required test case'lerin tamamı PASS olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_test_count gerçek test case sayısıyla eşleşmelidir.
- pass_count gerçek PASS sayısıyla eşleşmelidir.
- fail_count gerçek FAIL sayısıyla eşleşmelidir.
- required_fail_count = 0 olmalıdır.
- optional_warn_count kabul edilebilir sınırda olmalıdır.
- import chain dependencies 198, 199, 200, 201, 202 PASS olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Import testleri dokümanı vardır.
- Master config artifact vardır.
- Import test suite artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid suite fixture PASS döner.
- Invalid suite fixture FAIL döner.
- Required fail guard doğrulanır.
- Missing evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
