# 200 — FAZ 4-16.2.3 Fiş / Hareket Import

## Amaç

Pilot tenant için fiş ve hareket import akışını controlled pilot seviyesinde standartlaştırır.

Bu adım satış, alış, iade, ödeme, tahsilat ve stok hareketlerinin import edilmeden önce dry-run doğrulamasını yapar.

## Kapsam

Fiş / hareket import aşağıdaki alanları kapsar:

- Tenant guard
- Import batch guard
- Dry-run zorunluluğu
- Receipt header doğrulama
- Receipt line doğrulama
- Movement type doğrulama
- Cari referansı doğrulama
- Ürün referansı doğrulama
- Quantity / unit price / tax rate doğrulama
- Header total / line total reconciliation
- Payment movement doğrulama
- Stock movement doğrulama
- Duplicate receipt no guard
- Duplicate movement id guard
- Unknown customer guard
- Unknown product guard
- Negative amount guard
- External provider closed policy gate

## Zorunlu Fiş Header Alanları

- receipt_no
- receipt_type
- receipt_date
- customer_code
- currency_code
- gross_total
- net_total
- tax_total

## Zorunlu Fiş Line Alanları

- line_no
- product_code
- quantity
- unit_price
- tax_rate
- net_amount
- tax_amount
- gross_amount

## Ana Kural

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Bu adım gerçek DB commit yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Fiş / hareket import PASS sayılırsa:

- import_mode = DRY_RUN olmalıdır.
- commit_requested = false olmalıdır.
- tenant_id dolu olmalıdır.
- batch_id dolu olmalıdır.
- total_receipt_rows gerçek fiş sayısıyla eşleşmelidir.
- total_movement_rows gerçek hareket sayısıyla eşleşmelidir.
- duplicate receipt_no olmamalıdır.
- duplicate movement_id olmamalıdır.
- receipt line product_code ürün referansında bulunmalıdır.
- receipt header customer_code cari referansında bulunmalıdır.
- line gross toplamı header gross_total ile uyumlu olmalıdır.
- line net toplamı header net_total ile uyumlu olmalıdır.
- line tax toplamı header tax_total ile uyumlu olmalıdır.
- negative quantity / amount olmamalıdır.
- payment amount negatif olmamalıdır.
- stock movement quantity 0 olmamalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Fiş / hareket import dokümanı vardır.
- Master config artifact vardır.
- Mapping artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Duplicate receipt guard doğrulanır.
- Unknown customer/product guard doğrulanır.
- Total reconciliation guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
