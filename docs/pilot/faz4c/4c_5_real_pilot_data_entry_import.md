# FAZ 4C — 4C-5 Real Pilot Data Entry / Import

## Blok

4C-5 — Real Pilot Data Entry / Import

## Amaç

Bu blokta uzmanparcaci pilot işletmesi için gerçek veri giriş / import hazırlığı yapılacaktır.

Bu aşamada hedef:

- Ürün/stok import kapsamını dondurmak
- Oto yedek parça minimum alanlarını belirlemek
- CSV/import template üretmek
- Import öncesi veri kalite kapısı kurmak
- DB apply öncesi dry-run / validation yapmak
- Sonrasında kontrollü gerçek pilot veri girişine geçmek

---

## 1. Ön koşul

4C-4 Real User / Role Assignment kapanmış olmalıdır.

Beklenen önceki durum:

4C_4_FINAL_STATUS=PASS
4C_4_REAL_USER_ROLE_ASSIGNMENT_STATUS=PASS
4C_4_USER_CREATED=YES
4C_4_ROLE_CREATED=YES
4C_4_ASSIGNMENT_CREATED=YES
4C_5_READY=YES

---

## 2. Pilot işletme

PILOT_BUSINESS_NAME=uzmanparcaci
PILOT_SECTOR=OTO_YEDEK_PARCA
PILOT_CITY=istanbul
PILOT_DISTRICT=bahcelievler
PILOT_WEBSITE=https://uzmanparcaci.com/

---

## 3. Tenant

TENANT_BUSINESS_CODE=UZMANPARCACI
TENANT_SLUG=uzmanparcaci
TENANT_SCHEMA=tenant_uzmanparcaci
TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439

---

## 4. Import kapsam kararı

DATA_ENTRY_MODE=IMPORT_TEMPLATE_FIRST
IMPORT_SOURCE_TYPE=MANUAL_CSV_TEMPLATE
IMPORT_TARGET_ENTITY=PRODUCT_STOCK
INITIAL_PRODUCT_SAMPLE_TARGET=200
FULL_STOCK_ESTIMATE=1000

Bu adımda ürün/stok DB apply yapılmayacaktır.

---

## 5. Ürün minimum alanları

Zorunlu temel alanlar:

- product_name
- sku
- category
- unit
- initial_stock_qty
- sale_price
- purchase_price
- currency

Oto yedek parça özel alanları:

- oem_code
- equivalent_code
- vehicle_fitment_note
- brand
- part_group

---

## 6. Scope guard

FAZ 4C içinde yapılmayacaklar:

- Canlı pazaryeri entegrasyonu yok
- Trendyol / Hepsiburada / N11 API canlı entegrasyonu yok
- Paraşüt canlı senkron yok
- Barkod zorunluluğu yok
- Tam TECDOC motoru yok
- Otomatik web scraping yok
- Toplu gerçek ürün DB apply yok

Pazaryeri entegrasyonu FAZ 4D kapsamındadır.

---

## 7. 4C-5 planı

1. 4C-5A — Data Entry / Import Scope Freeze
2. 4C-5B — Import Template Structure Precheck
3. 4C-5C — Product / Stock Table Discovery
4. 4C-5D — Import Mapping Strategy Decision
5. 4C-5E — Sample CSV Generation / Validation
6. 4C-5F — Import SQL Package / Dry Run Plan
7. 4C-5G — Import Dry Run / ROLLBACK Verification
8. 4C-5H — Controlled Sample Data Apply
9. 4C-5I — Sample Data Verification
10. 4C-5J — Real Pilot Data Entry / Import Final Closure

---

## 8. 4C-5A status

4C_5A_DATA_IMPORT_SCOPE_STATUS=PASS
4C_5A_TENANT_BUSINESS_CODE=UZMANPARCACI
4C_5A_PILOT_BUSINESS_NAME=uzmanparcaci
4C_5A_PILOT_SECTOR=OTO_YEDEK_PARCA
4C_5A_IMPORT_TARGET_ENTITY=PRODUCT_STOCK
4C_5A_INITIAL_PRODUCT_SAMPLE_TARGET=200
4C_5A_FULL_STOCK_ESTIMATE=1000
4C_5A_BARCODE_REQUIRED_FOR_PILOT=NO
4C_5A_MARKETPLACE_LIVE_INTEGRATION=NO
4C_5A_MARKETPLACE_PHASE=FAZ_4D
4C_5A_DB_WRITE_APPLIED=NO
4C_5B_READY=YES

---

## 9. Sonraki adım

Sonraki adım:

4C-5B — Import Template Structure Precheck

Bu adımda CSV/import template kolonları ve minimum veri kalite kuralları doğrulanacaktır.
