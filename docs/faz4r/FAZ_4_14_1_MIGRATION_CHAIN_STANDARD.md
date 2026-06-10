# 183 — FAZ 4-14.1 Migration Chain Standardı

## Amaç

FAZ 4-R migration zinciri için standart dosya adı, sıralama, apply güvenliği, rollback referansı ve gerçek PostgreSQL test davranışını tanımlar.

## Standart

Migration dosyaları şu dizinde tutulur:

db/migrations/faz4

Dosya adı formatı:

YYYYMMDD_HHMMSS_faz_x_y_z_description.sql

Örnek:

20260508_130110_faz_4_14_3_import_staging_tables.sql

## Kurallar

- Migration dosyaları timestamp ile başlamalıdır.
- Timestamp formatı YYYYMMDD_HHMMSS olmalıdır.
- Aynı timestamp birden fazla migration dosyasında kullanılmamalıdır.
- Dosya boş olmamalıdır.
- Faz 4-R migration dosyaları `.sql` uzantılı olmalıdır.
- Migration chain sıralaması lexicographic timestamp sırasına göre yapılır.
- Chain apply testi temporary schema içinde yapılır.
- Canlı domain datası migration chain testinde değiştirilemez.
- Rollback dosyaları ilgili backup dizinlerinde kanıt olarak saklanır.
- Final status sadece gerçek test/audit sayaçlarından türetilir.

## FAZ 4-R Kapalı Dış Policy

Migration chain standardı canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Migration chain standard dokümanı vardır.
- Config artifact vardır.
- Chain validation script vardır ve executable durumdadır.
- SQL test artifact vardır.
- Audit script vardır.
- Faz 4 migration dizini vardır.
- 180 migration dosyası chain içinde bulunur.
- Timestamp formatı doğrulanır.
- Duplicate timestamp yoktur.
- Migration dosyaları boş değildir.
- 180 migration temporary schema içinde başarıyla apply edilir.
- Final status gerçek sayaçlardan türetilir.
