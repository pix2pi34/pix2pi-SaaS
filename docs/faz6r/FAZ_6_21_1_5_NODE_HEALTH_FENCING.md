# FAZ 6-R / 305 — FAZ 6-21.1.5 Node Health Fencing

## Amaç

Pix2pi runtime/cluster readiness katmanında node health fencing standardını kurar.

Bu adım canlı node cordon, drain, shutdown, restart, LB detach, DNS change, gateway route switch, container kill, deployment rollout veya provider mutation yapmaz. Sadece node health sinyalleri, fencing karar modeli, quorum/split-brain guard, tenant-safe traffic isolation, dry-run fencing snapshot ve evidence üretir.

## Bağımlılık

- FAZ 6-21.1.4 Session / sticky policy

## Required Controls

- session_sticky_dependency_gate
- node_inventory_model
- node_health_signal_model
- fencing_decision_policy
- quorum_safety_guard
- split_brain_guard
- tenant_traffic_isolation_guard
- workload_drain_policy
- lb_detach_policy
- service_discovery_alignment_guard
- session_affinity_safety_guard
- dry_run_fencing_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Node Health Fencing İlkeleri

1. Canlı node fencing bu adımda yapılmaz.
2. Cordon/drain/restart/shutdown/LB detach kapalıdır.
3. Quorum ve split-brain guard olmadan fencing kararı üretilemez.
4. Tenant traffic isolation bozulamaz.
5. Session/sticky policy ile çelişen node izolasyonu uygulanamaz.
6. Service discovery registry mutation bu adımda kapalıdır.
7. Workload drain sadece dry-run karar olarak üretilir.
8. Manual approval olmadan node health mutation yapılmaz.
9. Evidence olmadan DB-L8 scale readiness bloğuna geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- POLICY_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

