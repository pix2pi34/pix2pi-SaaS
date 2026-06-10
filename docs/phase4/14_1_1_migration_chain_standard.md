# FAZ 4 / 14.1.1 - Migration Chain Standardi

Aktif migration chain root:

db/migrations

Yeni migration dosya adi standardi:

YYYYMMDDHHMMSS_slug.up.sql
YYYYMMDDHHMMSS_slug.down.sql

Ornek:

20260427071500_migration_chain_standard.up.sql
20260427071500_migration_chain_standard.down.sql

Kurallar:
1. Her up dosyasinin down dosyasi olmak zorunda.
2. Her down dosyasinin up dosyasi olmak zorunda.
3. Version 14 haneli bitisik timestamp olmali.
4. Slug lowercase ASCII, rakam ve alt cizgi icermeli.
5. Turkce ozel karakter, bosluk, tire ve buyuk harf kullanilmaz.
6. Uygulanmis migration dosyasi sonradan degistirilmez.
7. Duzeltme gerekiyorsa yeni migration yazilir.
8. db/tests aktif migration chain sayilmaz.
9. deploy/sql aktif migration chain sayilmaz.
10. internal/db/migrations* legacy kabul edilir.

Kapanis kriteri:

MIGRATION_CHAIN_VALIDATION=PASS
PHASE4_MIGRATION_CHAIN_STANDARD_TEST=PASS
