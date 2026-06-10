# FAZ 6-R / 300 — FAZ 6-21.2.1 DB HA Topolojisi

## Amaç

Pix2pi PostgreSQL katmanı için HA topoloji standardını tanımlar.

Bu adım canlı database promotion, replica attach/detach, DNS change, connection string switch, read/write routing mutation veya provider mutation yapmaz. Sadece HA topology modeli, primary/replica rol ayrımı, failover karar guardları, replication health sinyalleri, dry-run topology snapshot ve evidence üretir.

## Bağımlılık

- FAZ 6-21.3.4 Rate limit tuning

## Required Controls

- rate_limit_tuning_dependency_gate
- db_ha_role_model
- primary_replica_topology_model
- write_primary_guard
- read_replica_guard
- replication_health_model
- failover_decision_guard
- split_brain_prevention_policy
- connection_routing_policy
- backup_pitr_dependency_policy
- rto_rpo_alignment_policy
- dry_run_topology_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## DB HA İlkeleri

1. Tek write-primary kuralı korunur.
2. Replica sadece read-pool veya failover candidate olarak modellenir.
3. Split-brain riski varsa failover kararı BLOCKED olur.
4. Promotion bu adımda çalıştırılmaz.
5. DSN / DNS / application route mutation bu adımda yapılmaz.
6. RTO/RPO ve PITR uyumu HA karar modeline bağlıdır.
7. Manual approval olmadan DB HA mutation yapılmaz.
8. Evidence olmadan replica failover provası adımına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- TOPOLOGY_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

