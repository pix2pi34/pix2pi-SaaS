# FAZ 6-R / 307 — FAZ 6-20.6 Partition / Shard Readiness Modeli

## Amaç

Pix2pi DB scale readiness katmanında partition ve shard hazırlık modelini tanımlar.

Bu adım canlı partition create/drop, shard split/move, tenant move, table rewrite, index rebuild, sequence remap, foreign-key mutation, routing mutation, DSN switch veya provider mutation yapmaz. Sadece partition candidate modeli, shard key readiness, tenant distribution analizi, cross-shard transaction guard, reporting/readmodel etkisi, migration safety, dry-run readiness snapshot ve evidence üretir.

## Bağımlılık

- FAZ 6-20.2 Replica routing / read pool stratejisi

## Required Controls

- replica_routing_dependency_gate
- partition_candidate_inventory
- shard_key_readiness_policy
- tenant_distribution_model
- data_locality_policy
- cross_shard_transaction_guard
- sequence_identity_guard
- foreign_key_boundary_guard
- reporting_readmodel_impact_guard
- migration_rewrite_safety_policy
- rollback_reversibility_policy
- dry_run_shard_readiness_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Partition / Shard İlkeleri

1. Canlı partition veya shard mutation yapılmaz.
2. Tenant move ve shard split bu adımda kapalıdır.
3. Shard key tenant-safe ve deterministic olmadan ready sayılmaz.
4. Cross-shard transaction riski BLOCKED olarak işaretlenir.
5. Finance/billing gibi strict consistency alanları shard adayı yapılmaz; önce boundary guard gerekir.
6. Reporting/readmodel etkisi değerlendirilmeden partition/shard kararı uygulanamaz.
7. Table rewrite/index rebuild üretim mutation olarak kapalıdır.
8. Rollback/reversibility kanıtı olmadan scale mutation yapılmaz.
9. Evidence olmadan WEB-L9 final release polish bloğuna geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- MODEL_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

