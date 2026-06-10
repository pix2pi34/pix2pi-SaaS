# FAZ 4 / 14.1.4 - Real DB Connection / Schema Migrations Evidence

Amac:
Migration apply gate icin gercek DB baglantisini kanitlamak.

Gizlilik:
Raw DSN, DB sifresi ve secret degerleri terminale veya rapora basilmaz.

Kontroller:
1. DSN adaylari process env ve env dosyalarindan toplanir.
2. DSN adaylari maskelenerek raporlanir.
3. Placeholder DSN tespit edilir.
4. psql varsa baglanti testi denenir.
5. public.schema_migrations var mi kontrol edilir.
6. dirty column varsa dirty state okunur.
7. Gercek baglanti gecerse PASS verilir.
8. Gercek baglanti yoksa FAIL yerine NEEDS_REAL_DSN raporlanir.

Kapanis hedefi:
DB_CONNECTION_EVIDENCE=PASS
DB_CONNECTION_CHECK=PASS
FAZ4_14_1_4_FINAL_STATUS=PASS
