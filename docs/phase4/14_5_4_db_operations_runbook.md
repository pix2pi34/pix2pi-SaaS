# FAZ 4 / 14.5.4 - DB Operations Runbook / Incident Checklist

Generated at: 2026-04-27 17:40:04 +0300

## 1. Current DB Readiness Snapshot

| Alan | Deger |
|---|---|
| Production readiness score | 96/100 |
| Production readiness grade | A |
| Production readiness status | READY_WITH_DEFERRED_ACTIONS |
| Blocker count | 0 |
| Deferred action count | 4 |
| Observe-only count | 2 |
| DB health risk | LOW |
| PITR current ready | NO |

## 2. Golden Safety Rules

- Canli DB uzerinde once kanit, sonra karar.
- Raw DSN, password ve query text rapora basma.
- Backup almadan config apply yapma.
- Restore drill kaniti olmadan backup'a guvenme.
- Query kill / lock termination yalniz incident owner onayi ile.
- Index drop karari production veri hacmi ve tekrar baseline olmadan verilmez.
- Vacuum/analyze canli ortamda sadece kontrollu planla uygulanir.
- PITR apply islemi maintenance window olmadan yapilmaz.

## 3. DB Health Quick Check

Amac: DB calisiyor mu, primary mi, lock/deadlock/idle transaction var mi?

```bash
cd ~/pix2pi/pix2pi-SaaS

bash scripts/phase4_db_health_baseline.sh .

grep -E 'DB_CONNECTION_CHECK=|DB_ROLE=|DB_TOTAL_CONNECTIONS=|DB_IDLE_IN_TRANSACTION_CONNECTIONS=|DB_LONG_RUNNING_ACTIVE_QUERIES_60S=|DB_WAITING_LOCK_COUNT=|DB_DEADLOCK_COUNT=|DB_PREPARED_TRANSACTION_COUNT=|DB_HEALTH_RISK_LEVEL=' \
  docs/phase4/14_4_4_db_health_baseline_report.md
```

Beklenen:
```text
DB_CONNECTION_CHECK=PASS
DB_ROLE=PRIMARY_WRITE
DB_WAITING_LOCK_COUNT=0
DB_DEADLOCK_COUNT=0
DB_IDLE_IN_TRANSACTION_CONNECTIONS=0
DB_HEALTH_RISK_LEVEL=LOW
```

## 4. Backup / Restore Quick Check

```bash
cd ~/pix2pi/pix2pi-SaaS

bash scripts/phase4_logical_backup_smoke.sh .
bash scripts/phase4_restore_drill_test.sh .

grep -E 'LOGICAL_BACKUP_SMOKE=|DUMP_SIZE_BYTES=|PG_RESTORE_LIST_CHECK=' \
  docs/phase4/14_2_2_logical_backup_smoke_report.md

grep -E 'RESTORE_DRILL_TEST=|SANDBOX_RESTORE_STATUS=|RESTORED_TABLE_COUNT=|SANDBOX_CLEANUP_STATUS=' \
  docs/phase4/14_2_4_restore_drill_test_report.md
```

Beklenen:
```text
LOGICAL_BACKUP_SMOKE=PASS
RESTORE_DRILL_TEST=PASS
SANDBOX_RESTORE_STATUS=PASS
SANDBOX_CLEANUP_STATUS=PASS
```

## 5. PITR Deferred Action Runbook

Mevcut durum:
```text
PITR_CURRENT_READY=NO
PITR_ENABLE_DECISION=PLAN_READY_APPLY_NOT_EXECUTED
HOST_WAL_ARCHIVE_DIR_STATUS=NOT_FOUND
WAL_ARCHIVE_MOUNT_STATUS=NOT_FOUND
ARCHIVE_MODE_READY=NO
ARCHIVE_COMMAND_READY=NO
```

PITR maintenance window oncesi zorunlu kapilar:

- Fresh logical backup al.
- Restore drill PASS al.
- Docker compose/config backup al.
- WAL archive host dizini olustur.
- WAL archive mount ekle.
- archive_mode=on yap.
- archive_command tanimla.
- PostgreSQL controlled restart yap.
- DB health PASS al.
- pg_switch_wal ile WAL dosyasi arsive dustu mu dogrula.
- Restic backup kapsamina WAL archive dizinini al.
- PITR readiness raporunu tekrar calistir.

Kontrol komutlari:
```bash
cd ~/pix2pi/pix2pi-SaaS

bash scripts/phase4_db_backup_pitr_readiness.sh .
bash scripts/phase4_pitr_enable_gate.sh .

grep -E 'PITR_CURRENT_READY=|ARCHIVE_MODE_READY=|ARCHIVE_COMMAND_READY=|HOST_WAL_ARCHIVE_DIR_STATUS=|WAL_ARCHIVE_MOUNT_STATUS=' \
  docs/phase4/14_2_6_pitr_enable_gate_report.md
```

## 6. WAL Archive Enable Checklist

- [ ] Bakim penceresi onaylandi.
- [ ] Fresh backup PASS.
- [ ] Restore drill PASS.
- [ ] Config backup alindi.
- [ ] Host WAL archive dizini olusturuldu.
- [ ] Container mount eklendi.
- [ ] archive_mode=on yapildi.
- [ ] archive_command tanimlandi.
- [ ] PostgreSQL restart edildi.
- [ ] DB_CONNECTION_CHECK=PASS.
- [ ] DB_ROLE=PRIMARY_WRITE.
- [ ] WAL switch test edildi.
- [ ] WAL archive dosyasi goruldu.
- [ ] Risk register DB-RISK-001/002/003 kapatildi.

## 7. Lock / Deadlock Incident Checklist

Ilk kontrol:
```bash
cd ~/pix2pi/pix2pi-SaaS
bash scripts/phase4_db_health_baseline.sh .

grep -E 'DB_WAITING_LOCK_COUNT=|DB_BLOCKED_PID_COUNT=|DB_DEADLOCK_COUNT=|DB_HEALTH_RISK_LEVEL=' \
  docs/phase4/14_4_4_db_health_baseline_report.md
```

Karar agaci:
- Waiting lock 0 ise incident yok.
- Waiting lock > 0 ise once etkilenen servis/tenant/log kontrol edilir.
- Query text rapora basilmaz.
- Kill islemi otomatik yapilmaz.
- Query kill gerekiyorsa incident owner onayi gerekir.
- Kill sonrasi DB health baseline tekrar alinir.

## 8. Slow Query Incident Checklist

Ilk kontrol:
```bash
cd ~/pix2pi/pix2pi-SaaS
bash scripts/phase4_query_performance_baseline.sh .

grep -E 'PG_STAT_MEAN_OVER_WARN_COUNT=|PG_STAT_TOTAL_OVER_WARN_COUNT=|PG_STAT_TEMP_BLOCK_QUERY_COUNT=|QUERY_PERF_RISK_LEVEL=' \
  docs/phase4/14_4_1_query_performance_baseline_report.md
```

Karar agaci:
- Risk LOW ise observe.
- Mean/total threshold asildiysa queryid bazli analiz yap.
- Query text rapora basma.
- Index ekleme karari icin 14.4.2 index usage baseline ile birlikte degerlendir.
- Production verisi artinca tekrar baseline al.

## 9. Connection Saturation Checklist

Kontrol:
```bash
grep -E 'POSTGRES_MAX_CONNECTIONS=|DB_TOTAL_CONNECTIONS=|DB_CONNECTION_USAGE_PERCENT=|DB_IDLE_IN_TRANSACTION_CONNECTIONS=' \
  docs/phase4/14_4_4_db_health_baseline_report.md
```

Karar agaci:
- Connection usage < %70 ise normal.
- Usage >= %70 ise connection pool ayarlari incelenir.
- idle in transaction > 0 ise uygulama transaction lifecycle incelenir.
- Max connection artirmadan once pool / leak analizi yapilir.

## 10. Vacuum / Bloat Observe Checklist

Kontrol:
```bash
cd ~/pix2pi/pix2pi-SaaS
bash scripts/phase4_vacuum_bloat_readiness.sh .

grep -E 'AUTOVACUUM=|TRACK_COUNTS=|DB_TOTAL_LIVE_TUPLES=|DB_TOTAL_DEAD_TUPLES=|DB_HIGH_DEAD_RATIO_TABLE_COUNT=|LOW_DATA_CONTEXT=|VACUUM_RISK_LEVEL=' \
  docs/phase4/14_4_3_vacuum_bloat_readiness_report.md
```

Karar:
- LOW_DATA_CONTEXT=YES ise vacuum/analyze calistirma, observe-only.
- Production veri hacmi artinca tekrar baseline al.
- Gercek bloat icin pgstattuple ayri gate ile degerlendirilecek.

## 11. Index Usage Observe Checklist

Kontrol:
```bash
cd ~/pix2pi/pix2pi-SaaS
bash scripts/phase4_index_usage_baseline.sh .

grep -E 'DB_UNUSED_INDEX_COUNT=|DB_UNUSED_NON_UNIQUE_INDEX_COUNT=|LOW_DATA_CONTEXT=|INDEX_USAGE_RISK_LEVEL=' \
  docs/phase4/14_4_2_index_usage_baseline_report.md
```

Karar:
- LOW_DATA_CONTEXT=YES ise index drop yok.
- Primary/unique indexler observe-only.
- Production veri hacmi artinca index usage tekrar degerlendirilir.
- Drop karari icin en az iki farkli production baseline gerekir.

## 12. Rollback Decision Tree

Config apply sonrasi DB acilmiyorsa:
1. Son config backup bulunur.
2. Son compose/config backup restore edilir.
3. PostgreSQL container controlled restart edilir.
4. DB_CONNECTION_CHECK=PASS dogrulanir.
5. DB_ROLE=PRIMARY_WRITE dogrulanir.
6. Incident kaydi acilir.
7. Basarisiz config apply risk register'a eklenir.

Backup/restore problemi varsa:
1. Son logical backup raporu kontrol edilir.
2. Son restore drill raporu kontrol edilir.
3. Dump checksum dogrulanir.
4. Sandbox restore tekrar denenir.
5. Canli restore yapilmaz; once sandbox kaniti alinir.

## 13. Production Sonrasi Tekrar Baseline Takvimi

- Ilk 1 hafta: Her gun DB health baseline.
- Ilk 1 hafta: Her gun query performance baseline.
- Ilk 1 ay: Haftalik index usage baseline.
- Ilk 1 ay: Haftalik vacuum/bloat readiness baseline.
- Her major release sonrasi: 14.4.1 - 14.4.5 tekrar.
- PITR enable sonrasi: 14.2.1 - 14.2.6 tekrar.

## 14. Final Operational Status

```text
DB_RUNBOOK_STATUS=ACTIVE
DB_PRODUCTION_READINESS_SCORE=96
DB_PRODUCTION_READINESS_GRADE=A
DB_PRODUCTION_READINESS_STATUS=READY_WITH_DEFERRED_ACTIONS
KNOWN_BLOCKERS=0
KNOWN_DEFERRED_ACTIONS=4
KNOWN_OBSERVE_ONLY_DECISIONS=2
```
