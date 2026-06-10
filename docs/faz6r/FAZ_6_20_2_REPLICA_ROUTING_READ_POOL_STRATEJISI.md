# FAZ 6-R / 306 — FAZ 6-20.2 Replica Routing / Read Pool Stratejisi

## Amaç

Pix2pi PostgreSQL read scalability katmanı için replica routing ve read pool stratejisini tanımlar.

Bu adım canlı DSN switch, application routing mutation, replica promotion, read pool attach/detach, load balancer mutation, DNS mutation, DB role mutation veya provider mutation yapmaz. Sadece read/write split modeli, replica health scoring, lag-aware routing, consistency guard, tenant-safe read routing, dry-run read pool decision snapshot ve evidence üretir.

## Bağımlılık

- FAZ 6-21.1.5 Node health fencing

## Required Controls

- node_health_fencing_dependency_gate
- read_write_split_policy
- primary_write_only_guard
- replica_read_pool_model
- replica_health_scoring_policy
- lag_aware_routing_policy
- stale_read_guard
- read_after_write_consistency_guard
- tenant_safe_read_routing_guard
- reporting_read_pool_policy
- operational_read_pool_policy
- failover_candidate_exclusion_policy
- dry_run_read_pool_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Replica Routing İlkeleri

1. Write trafiği her zaman primary-only kalır.
2. Read pool sadece read-only replica hedeflerine yönlenir.
3. Replica lag threshold üstündeyse routing kararı BLOCKED olur.
4. Read-after-write consistency gereken route’lar primary-read fallback veya strict consistency ister.
5. Tenant scope korunmadan read routing yapılamaz.
6. Reporting/readmodel workload ile operational read workload ayrılır.
7. Failover candidate replica ile read pool replica policy çakışması kontrol edilir.
8. Canlı DSN, DNS, LB, gateway veya DB mutation yapılmaz.
9. Evidence olmadan partition / shard readiness modeline geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- STRATEGY_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

