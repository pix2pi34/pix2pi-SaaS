# FAZ 4 / 14.2.6 - PITR Enable Gate

Amac:
PITR/WAL archive acma isleminden once guvenlik kapisini kurmak.

Bu adim:
- PITR acmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- DB mutate etmez.
- WAL archive dizini olusturmaz.
- Sadece enable icin gereken kosullari kontrol eder ve aday uygulama planini uretir.

Zorunlu kanitlar:
1. 14.2.1 readiness discovery PASS olmali.
2. 14.2.4 restore drill PASS olmali.
3. 14.2.5 PITR design PASS olmali.
4. DB primary/write olmali.
5. wal_level replica/logical olmali.
6. archive_mode ve archive_command mevcut durum olarak raporlanmali.
7. Primary container ve image tespit edilmeli.
8. WAL archive host/container path plani raporlanmali.
9. Config degisikligi ve restart gereksinimi raporlanmali.
10. Candidate execution plan exit 99 ile bloklu olmali.

Default guvenlik:
APPLY_PITR=0

Kapanis hedefi:
PITR_ENABLE_GATE=PASS
PITR_ENABLE_EXECUTED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
DB_MUTATION=NO
FAZ4_14_2_6_FINAL_STATUS=PASS
