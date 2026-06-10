# FAZ 6-R / 302 — FAZ 6-21.2.5 Point-in-time Recovery Provası

## Amaç

Pix2pi PostgreSQL katmanında PITR readiness ve restore prova standardını dry-run olarak kurar.

Bu adım canlı restore, primary overwrite, replica rebuild, WAL replay execution, backup delete, DNS/DSN switch veya provider mutation yapmaz. Sadece PITR hedef zamanı, backup/WAL zinciri, restore preflight, isolated restore target, RTO/RPO ölçüm modeli, rollback kararı ve evidence üretir.

## Bağımlılık

- FAZ 6-21.2.2 Replica failover provası

## Required Controls

- replica_failover_dependency_gate
- backup_chain_inventory
- wal_archive_inventory
- recovery_target_time_policy
- isolated_restore_target_policy
- restore_preflight_policy
- wal_replay_validation_policy
- data_integrity_validation_policy
- tenant_scope_validation_policy
- rto_rpo_measurement_policy
- restore_execution_closed_policy
- production_mutation_closed_policy
- manual_approval_policy
- dry_run_pitr_runtime
- evidence_capture_policy
- final_status_policy

## PITR İlkeleri

1. Canlı DB restore bu adımda yapılmaz.
2. Primary overwrite kesinlikle kapalıdır.
3. PITR sadece isolated restore target modelinde prova edilir.
4. Backup chain ve WAL archive evidence yoksa restore kararı BLOCKED olur.
5. Recovery target time açıkça seçilmelidir.
6. Tenant scope ve data integrity validation zorunludur.
7. Restore execution, DNS/DSN switch ve route mutation kapalıdır.
8. Manual approval olmadan hiçbir restore işlemi yapılmaz.
9. Evidence olmadan service discovery tuning adımına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- REHEARSAL_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

