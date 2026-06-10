# FAZ 4 / 14.1.3 - Migration DB Env / DSN Discovery Standardi

Amac:
Migration apply / dry-run gate icin DB baglanti bilgisinin nereden okunacagini standart hale getirmek.

Gizlilik kurali:
DB sifresi, raw DSN veya secret degeri terminale ve rapora basilmaz.

DSN oncelik sirasi:
1. DB_DSN
2. DB_WRITE_DSN
3. DATABASE_URL
4. POSTGRES_DSN
5. POSTGRES_URL
6. DATABASE_DSN

Env dosyasi adaylari:
1. .env
2. .env.local
3. .env.production
4. config/.env
5. config/common.env
6. deploy/.env
7. deploy/env/common.env
8. infra/.env
9. /etc/pix2pi/ports.env
10. /etc/pix2pi/common.env
11. /opt/pix2pi/orchestrator/env/common.env
12. /opt/pix2pi/env/common.env

Kurallar:
1. Migration icin write DSN tercih edilir.
2. Read replica DSN migration apply icin kullanilmaz.
3. DB_DSN mevcutsa en ust onceliklidir.
4. DB_WRITE_DSN varsa migration icin dogru secenektir.
5. Secret raporda maskelenir.
6. psql varsa baglanti testi denenir.
7. schema_migrations varsa dirty state okunmaya calisilir.
8. DB yoksa bu adim fail etmez; net raporlar.
9. Apply-check asamasinda DB_DSN zorunlu kalir.
10. Apply-check asamasinda BACKUP_GATE=CONFIRMED zorunlu kalir.

Kapanis kriteri:
PHASE4_DB_ENV_DISCOVERY_REAL_TEST=PASS
PHASE4_DB_ENV_DISCOVERY_MASK_TEST=PASS
PHASE4_DB_ENV_DISCOVERY_WRITE_ENV_TEST=PASS
PHASE4_DB_ENV_DISCOVERY_APPLY_GATE_INTEGRATION_TEST=PASS
DB_ENV_DISCOVERY=PASS
FAZ4_14_1_3_FINAL_STATUS=PASS
