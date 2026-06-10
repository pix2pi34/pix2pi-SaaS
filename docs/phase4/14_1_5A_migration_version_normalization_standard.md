# FAZ 4 / 14.1.5A - Migration Version Normalization / DB-Local Chain Mismatch Analysis

Amac:
DB schema_migrations version degeri ile db/migrations dosya zinciri ayni dili konusuyor mu kanitlamak.

Bu adim DB mutate etmez.
Migration apply yapmaz.
Sadece analiz ve rapor uretir.

Desteklenen local migration formatlari:
1. 001_name.up.sql
2. 0001_name.up.sql
3. 20260425_090101_name.up.sql
4. 20260425090101_name.up.sql

Normalize mantigi:
1. 001 -> 1
2. 0001 -> 1
3. 20260425_090101 -> 20260425090101
4. 20260425090101 -> 20260425090101

Kontroller:
1. DB primary/write olmali.
2. schema_migrations dirty=false olmali.
3. DB current version okunmali.
4. Local up migration dosyalari normalize edilmeli.
5. DB current version local dosyada eslesiyor mu raporlanmali.
6. DB current version local latest ile ayni mi raporlanmali.
7. Uyumsuzluk varsa apply yapmadan mismatch olarak raporlanmali.

Kapanis hedefi:
MIGRATION_VERSION_NORMALIZATION=PASS
DB_VERSION_MATCH_LOCAL=YES
DB_LOCAL_CHAIN_MISMATCH_ANALYZED=YES
FAZ4_14_1_5A_FINAL_STATUS=PASS
