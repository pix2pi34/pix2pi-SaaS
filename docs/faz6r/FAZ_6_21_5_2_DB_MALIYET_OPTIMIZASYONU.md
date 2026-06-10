# FAZ 6-R / 294 — FAZ 6-21.5.2 DB Maliyet Optimizasyonu

## Amaç

Pix2pi PostgreSQL / DB katmanı için maliyet optimizasyonu standardını kurar.

Bu adım canlı database resize, replica silme, index drop, partition drop, vacuum aggressive mutation, retention delete veya provider mutation yapmaz. Sadece DB maliyet sinyalleri, rightsizing karar modeli, index/storage/replica review, dry-run öneri çıktısı ve evidence üretir.

## Bağımlılık

- FAZ 6-21.5.1 Compute maliyet optimizasyonu

## Required Controls

- compute_cost_dependency_gate
- db_inventory_model
- db_workload_classification_policy
- connection_pool_review_policy
- query_cost_review_policy
- index_cost_review_policy
- replica_cost_review_policy
- retention_cost_review_policy
- storage_growth_review_policy
- backup_cost_review_policy
- performance_slo_guard
- data_safety_guard
- production_mutation_closed_policy
- manual_approval_policy
- dry_run_cost_runtime
- evidence_capture_policy
- final_status_policy

## DB Optimizasyon İlkeleri

1. Canlı DB resize bu adımda yapılmaz.
2. Index drop, table drop, partition drop ve retention delete öneri olarak bile riskli işaretlenir.
3. Query optimizasyonu önce gözlem ve öneri seviyesinde kalır.
4. Connection pool, replica, backup ve storage maliyeti ayrı izlenir.
5. RPO/RTO, DR ve veri güvenliği düşürülmez.
6. Her öneri SLO guard ve data safety guard ile değerlendirilir.
7. Manual approval olmadan production DB mutation yapılmaz.
8. Evidence olmadan storage/log maliyet optimizasyonuna geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- PLAN_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

