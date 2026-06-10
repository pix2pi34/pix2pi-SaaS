# 201 — FAZ 4-16.2.4 Mapping / Transform Kuralları

## Amaç

Pilot import akışlarında kullanılan cari, ürün/stok ve fiş/hareket mapping kurallarını tek standart altında toplar.

Bu adım 198, 199 ve 200 import akışlarının üstüne transform standardı koyar.

## Kapsam

Mapping / transform kuralları aşağıdaki alanları kapsar:

- Ortak import transform sözleşmesi
- Source field -> target field mapping
- String trim
- Code uppercase normalization
- Enum mapping
- Date normalization
- Decimal parse / rounding
- Currency normalization
- Boolean normalization
- Required field guard
- Unknown field guard
- Duplicate mapping guard
- Transform preview
- Dry-run zorunluluğu
- Commit yasağı
- Audit-safe output
- External provider closed policy gate

## Desteklenen Import Tipleri

- CUSTOMER
- PRODUCT_STOCK
- RECEIPT_MOVEMENT

## Ana Kural

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Bu adım gerçek DB commit yapmaz.

Bu adım sadece mapping / transform standardını doğrular.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Mapping / transform PASS sayılırsa:

- transform_mode = DRY_RUN olmalıdır.
- commit_requested = false olmalıdır.
- mapping_rule_set_status = READY olmalıdır.
- import_type desteklenen import tiplerinden biri olmalıdır.
- required transforms eksiksiz olmalıdır.
- target field duplicate olmamalıdır.
- unknown source field varsa FAIL dönmelidir.
- expected transformed preview ile runtime output eşleşmelidir.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Mapping / transform dokümanı vardır.
- Master config artifact vardır.
- Transform rules artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Unknown field guard doğrulanır.
- Duplicate target guard doğrulanır.
- Required transform guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
