# 199 — FAZ 4-16.2.2 Ürün / Stok Import

## Amaç

Pilot tenant için ürün ve stok import akışını controlled pilot seviyesinde standartlaştırır.

Bu adım ürün kartları ile ilk stok bakiyelerinin import edilmeden önce dry-run doğrulamasını yapar.

## Kapsam

Ürün / stok import aşağıdaki alanları kapsar:

- Tenant guard
- Import batch guard
- Dry-run zorunluluğu
- Product code
- Product name
- Product type
- Unit code
- Barcode / SKU opsiyonel alanları
- Tax rate
- Sales price
- Purchase price
- Track stock flag
- Warehouse code
- Stock quantity
- Reserved quantity
- Minimum stock quantity
- Duplicate product code guard
- Duplicate barcode guard
- Duplicate SKU guard
- Negative stock quantity guard
- Import limit guard
- External provider closed policy gate

## Zorunlu Ürün Alanları

- product_code
- product_name
- product_type
- unit_code
- tax_rate

## Zorunlu Stok Alanları

Stock tracking açık ürünlerde:

- warehouse_code
- quantity
- reserved_quantity
- min_stock_quantity

## Ana Kural

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Bu adım gerçek DB commit yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Ürün / stok import PASS sayılırsa:

- import_mode = DRY_RUN olmalıdır.
- commit_requested = false olmalıdır.
- tenant_id dolu olmalıdır.
- batch_id dolu olmalıdır.
- total_product_rows gerçek ürün satır sayısıyla eşleşmelidir.
- total_stock_rows gerçek stok satır sayısıyla eşleşmelidir.
- total_product_rows pilot sınırları içinde kalmalıdır.
- total_stock_rows pilot sınırları içinde kalmalıdır.
- Her üründe product_code, product_name, product_type, unit_code ve tax_rate dolu olmalıdır.
- Duplicate product_code olmamalıdır.
- Barcode varsa duplicate olmamalıdır.
- SKU varsa duplicate olmamalıdır.
- Tax rate negatif olmamalıdır.
- Sales / purchase price negatif olmamalıdır.
- Stok miktarları negatif olmamalıdır.
- Stock row product_code, ürün listesinde tanımlı olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Ürün / stok import dokümanı vardır.
- Master config artifact vardır.
- Mapping artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Duplicate product code guard doğrulanır.
- Duplicate barcode guard doğrulanır.
- Negative stock quantity guard doğrulanır.
- Unknown stock product guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
