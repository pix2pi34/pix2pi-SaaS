# 182 — FAZ 4-14.4 Backfill / Rebuild Script Standardı

## Amaç

Import staging altyapısı için güvenli, tenant-aware ve dry-run destekli backfill / rebuild standardı kurar.

## Kapsam

Bu adım aşağıdaki standardı getirir:

- Tenant zorunlu çalıştırma
- Import batch zorunlu çalıştırma
- Schema parametresi
- Dry-run varsayılan çalışma
- APPLY=1 olmadan veri değiştirmeme
- Validation error aggregate rebuild
- Import row validation status rebuild
- Import batch sayaç rebuild
- Commit/failed row sayaç rebuild
- Audit evidence üretimi
- PostgreSQL temporary schema üstünde gerçek davranış testi

## Runtime Script

Script:

scripts/faz4r/run_import_batch_backfill_rebuild.sh

Zorunlu parametreler:

- TENANT_ID
- IMPORT_BATCH_ID

Opsiyonel parametreler:

- SCHEMA
- APPLY
- DB_WRITE_DSN veya DATABASE_URL

## Güvenlik Kuralı

Varsayılan mod dry-run'dır.

APPLY=1 verilmeden update çalışmaz.

Canlı dış provider, GIB, banka veya POS aktivasyonu yapılmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Runtime rebuild script vardır.
- Runtime script executable durumdadır.
- Config artifact vardır.
- SQL behavior test vardır.
- Audit script vardır.
- Dry-run veri değiştirmez.
- APPLY=1 sayaçları gerçek DB davranışıyla rebuild eder.
- Tenant/batch guard çalışır.
- Final status gerçek test/audit sayaçlarından türetilir.

## FIX V2 Notu

İlk testte APPLY sonrası counter rebuild aynı SQL CTE snapshot içinde eski validation_status değerlerini okuduğu için valid_rows 0 kalmıştı.

FIX V2 ile işlem iki ayrı SQL statement olarak ayrıldı:

1. Önce import_staging_rows validation_status ve validation_errors rebuild edilir.
2. Sonra import_batches counter değerleri güncel row state üzerinden rebuild edilir.

Bu düzeltme PostgreSQL MVCC / CTE snapshot davranışına uygundur.
