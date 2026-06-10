# FAZ 6-R / 293 — FAZ 6-21.5.1 Compute Maliyet Optimizasyonu

## Amaç

Pix2pi compute katmanı için maliyet optimizasyonu standardını kurar.

Bu adım canlı sunucu resize, instance kapatma, autoscaling policy değişikliği veya provider mutation yapmaz. Sadece compute workload sınıflandırması, rightsizing karar modeli, dry-run öneri çıktısı, guard ve evidence üretir.

## Bağımlılık

- FAZ 6-21.6.5 DR rehearsal

## Required Controls

- dr_rehearsal_dependency_gate
- compute_inventory_model
- workload_classification_policy
- rightsizing_recommendation_policy
- idle_capacity_detection_policy
- scale_down_guard_policy
- reservation_commitment_review_policy
- burst_capacity_policy
- performance_slo_guard
- production_mutation_closed_policy
- manual_approval_policy
- dry_run_cost_runtime
- evidence_capture_policy
- final_status_policy

## Compute Optimizasyon İlkeleri

1. Production resize bu adımda yapılmaz.
2. Scale-down önerileri SLO guard ile korunur.
3. CPU/RAM/IO/network sinyalleri birlikte değerlendirilir.
4. Kritik servisler için minimum kapasite korunur.
5. DR ve failover readiness düşürülmez.
6. Reserved/commit önerileri sadece review-ready çıkar.
7. Her öneride risk seviyesi ve approval ihtiyacı bulunur.
8. Evidence olmadan DB maliyet optimizasyonuna geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- PLAN_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

