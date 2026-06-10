# 202 — FAZ 4-16.2.5 Import Validation Raporu

## Amaç

Pilot import akışlarında oluşan validation sonuçlarını standart rapor formatına bağlar.

Bu adım 198, 199, 200 ve 201 import/mapping adımlarından sonra gelir.

## Kapsam

Import validation raporu aşağıdaki alanları kapsar:

- Tenant guard
- Batch guard
- Import type guard
- Dry-run guard
- Total row count
- Valid row count
- Invalid row count
- Warning count
- Error count
- Severity dağılımı
- Field-level validation error listesi
- Row-level validation result listesi
- Summary status
- Report status
- Evidence reference
- Audit-safe output
- External provider closed policy gate

## Desteklenen Import Tipleri

- CUSTOMER
- PRODUCT_STOCK
- RECEIPT_MOVEMENT

## Ana Kural

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Bu adım gerçek DB commit yapmaz.

Bu adım validation raporu üretim / doğrulama standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Import validation raporu PASS sayılırsa:

- report_status = READY olmalıdır.
- validation_mode = DRY_RUN olmalıdır.
- commit_requested = false olmalıdır.
- tenant_id dolu olmalıdır.
- batch_id dolu olmalıdır.
- import_type desteklenen import tiplerinden biri olmalıdır.
- total_rows = valid_rows + invalid_rows olmalıdır.
- error_count gerçek errors listesi ile eşleşmelidir.
- warning_count gerçek warnings listesi ile eşleşmelidir.
- invalid_rows > 0 ise report_result = FAIL olmalıdır.
- invalid_rows = 0 ise report_result = PASS olmalıdır.
- Her error için row_no, field, code, severity, message dolu olmalıdır.
- Her warning için row_no, field, code, severity, message dolu olmalıdır.
- Severity sadece ERROR veya WARNING olmalıdır.
- Evidence ref dolu olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Import validation raporu dokümanı vardır.
- Master config artifact vardır.
- Report schema artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid PASS fixture geçer.
- Valid FAIL fixture geçer.
- Invalid broken fixture FAIL döner.
- Count reconciliation guard doğrulanır.
- Error detail guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
