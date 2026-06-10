# FAZ 6-R / 296 — FAZ 6-21.5.4 Cache / Queue Maliyet Optimizasyonu

## Amaç

Pix2pi Redis/cache ve NATS/queue katmanları için maliyet optimizasyonu standardını kurar.

Bu adım canlı Redis key delete, cache flush, queue purge, stream delete, consumer delete, retention shrink veya provider mutation yapmaz. Sadece cache/queue maliyet sinyalleri, TTL/retention review, consumer/stream review, dry-run öneri çıktısı ve evidence üretir.

## Bağımlılık

- FAZ 6-21.5.3 Storage / log maliyet optimizasyonu

## Required Controls

- storage_log_cost_dependency_gate
- cache_inventory_model
- queue_inventory_model
- cache_ttl_review_policy
- cache_hot_key_review_policy
- cache_memory_review_policy
- queue_retention_review_policy
- queue_consumer_lag_review_policy
- dlq_growth_review_policy
- stream_storage_review_policy
- tenant_namespace_guard
- idempotency_safety_guard
- production_mutation_closed_policy
- manual_approval_policy
- dry_run_cost_runtime
- evidence_capture_policy
- final_status_policy

## Cache / Queue Optimizasyon İlkeleri

1. Canlı cache flush veya queue purge yapılmaz.
2. Tenant namespace korunmadan hiçbir key/stream önerisi uygulanamaz.
3. TTL değişikliği bile review-only ve approval gerektirir.
4. Queue retention düşürme idempotency ve replay güvenliğiyle kontrol edilir.
5. DLQ ve stream storage önerileri veri kaybı riski taşıdığı için high-risk kabul edilir.
6. Consumer lag ve hot key sinyalleri maliyet/performance dengesiyle değerlendirilir.
7. Manual approval olmadan cache/queue mutation yapılmaz.
8. Evidence olmadan cost-performance raporuna geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- PLAN_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

