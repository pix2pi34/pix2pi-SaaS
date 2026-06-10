# FAZ 6-R / 301 — FAZ 6-21.2.2 Replica Failover Provası

## Amaç

Pix2pi PostgreSQL HA katmanında replica failover provası için dry-run karar ve doğrulama standardını kurar.

Bu adım canlı DB promotion, replica promotion, DNS değişikliği, DSN switch, application read/write route change, replication slot mutation veya provider mutation yapmaz. Sadece replica failover readiness modeli, preflight kontrolleri, split-brain guard, RTO/RPO ölçüm modeli, rollback kararı ve evidence üretir.

## Bağımlılık

- FAZ 6-21.2.1 DB HA topolojisi

## Required Controls

- db_ha_topology_dependency_gate
- failover_candidate_preflight
- primary_reachability_check
- replica_reachability_check
- replica_lag_guard
- wal_replay_guard
- backup_pitr_guard
- split_brain_guard
- promotion_decision_policy
- dns_dsn_route_switch_guard
- rollback_decision_policy
- rto_rpo_measurement_policy
- dry_run_failover_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Failover Provası İlkeleri

1. Canlı promotion bu adımda yapılmaz.
2. Primary belirsizse failover kararı BLOCKED olur.
3. Replica lag threshold üstündeyse promotion kararı BLOCKED olur.
4. WAL replay ve backup/PITR zinciri sağlıklı değilse failover kararı BLOCKED olur.
5. DNS, DSN ve application routing switch kapalıdır.
6. Split-brain riski varsa karar BLOCKED olur.
7. RTO/RPO sadece dry-run ölçüm olarak kaydedilir.
8. Manual approval olmadan hiçbir DB HA mutation yapılmaz.
9. Evidence olmadan PITR provası adımına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- REHEARSAL_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

