# 180 — FAZ 4-14.3 Import / Staging Tabloları

## Amaç

FAZ 4-R Pilot / Import / UAT Final Closure kapsamında import verilerinin canlı domain tablolarına doğrudan yazılmadan önce tenant-safe staging alanında tutulmasını sağlar.

## Kapsam

Bu adım aşağıdaki import altyapısını kurar:

- import_batches
- import_source_files
- import_staging_rows
- import_staging_customers
- import_staging_products
- import_staging_stock_entries
- import_staging_finance_documents
- import_validation_errors
- import_audit_events

## Mimari Karar

Import sistemi canlı domain tablolarına doğrudan yazmaz.

Akış:

1. Dosya alınır.
2. import_batches açılır.
3. Kaynak dosya import_source_files tablosuna kaydedilir.
4. Ham satırlar import_staging_rows tablosuna yazılır.
5. Domain bazlı staging tablolarına normalize edilir.
6. Validation errors ayrı tutulur.
7. Commit sonraki fazlarda kontrollü yapılır.
8. Rollback ve audit izleri korunur.

## Tenant Güvenliği

Tüm staging tablolarında tenant_id zorunludur.

Primary key ve index tasarımları tenant_id ile başlar.

## Canlı Dış Kapılar

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Sıradaki Bağımlı İşler

- 181 — FAZ 4-14.7 Migration / lifecycle / import testleri
- 182 — FAZ 4-14.4 Backfill / rebuild script standardı
- 198 — FAZ 4-16.2.1 Cari import
- 199 — FAZ 4-16.2.2 Ürün / stok import
- 200 — FAZ 4-16.2.3 Fiş / hareket import
- 201 — FAZ 4-16.2.4 Mapping / transform kuralları
- 202 — FAZ 4-16.2.5 Import validation raporu
- 203 — FAZ 4-16.2.6 Import testleri

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Migration dosyası vardır.
- Rollback dosyası vardır.
- Config artifact vardır.
- Audit script vardır.
- PostgreSQL üzerinde temporary schema içinde migration uygulanabilir.
- Required staging tabloları metadata üzerinden doğrulanır.
- Required index/constraint/fk izleri metadata üzerinden doğrulanır.
- Final status sayaçlardan türetilir.
