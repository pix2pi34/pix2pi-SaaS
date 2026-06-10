# FAZ 4 / 14.1.4B - Primary Write DSN Guard

Amac:
Migration icin kullanilan DB_WRITE_DSN degerinin replica degil primary/write DB oldugunu kanitlamak.

Kritik kural:
Migration apply sadece primary DB uzerinde calisir.
Replica DB migration apply icin kullanilmaz.

PostgreSQL kontrolu:
pg_is_in_recovery() = f ise primary/write DB
pg_is_in_recovery() = t ise replica/read DB

Bu adim:
1. Calisan PostgreSQL containerlarini tarar.
2. DSN adaylarini sifre basmadan test eder.
3. pg_is_in_recovery() sonucunu okur.
4. Primary DSN bulursa .env icindeki DB_WRITE_DSN ve DB_DSN degerlerini primary DSN ile gunceller.
5. Replica DSN'i write DSN olarak birakmaz.
6. Raporlarda raw password basilmaz.

Kapanis hedefi:
PRIMARY_WRITE_DSN_GUARD=PASS
PRIMARY_DSN_FOUND=1
REPLICA_DSN_FOUND opsiyonel olabilir
FAZ4_14_1_4B_FINAL_STATUS=PASS
