# FAZ 6-R / 298 — FAZ 6-21.3.3 Cache Hit/Miss Tuning

## Amaç

Pix2pi Redis/cache katmanı için cache hit/miss tuning standardını kurar.

Bu adım canlı cache flush, key delete, TTL mutation, namespace mutation veya production Redis değişikliği yapmaz. Sadece cache hit/miss sinyalleri, tenant namespace güvenliği, TTL önerileri, hot key review, dry-run tuning çıktısı ve evidence üretir.

## Bağımlılık

- FAZ 6-21.5.5 Cost-performance raporu

## Required Controls

- cost_performance_dependency_gate
- cache_surface_inventory
- hit_miss_metric_model
- tenant_namespace_guard
- ttl_tuning_policy
- hot_key_review_policy
- cache_bypass_review_policy
- fallback_safety_policy
- stale_data_guard
- rate_limit_cache_guard
- dry_run_tuning_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Cache Tuning İlkeleri

1. Canlı Redis flush veya key delete yapılmaz.
2. Tenant namespace korunmadan hiçbir tuning önerisi uygulanamaz.
3. TTL değişikliği bu adımda sadece öneridir.
4. Hit ratio artırılırken stale data riski yükseltilmez.
5. Rate limit cache ve session cache ayrı risk sınıfında ele alınır.
6. Cache bypass önerileri DB yükünü artırma riskine göre sınıflandırılır.
7. Her öneri fallback safety ve SLO guard ile değerlendirilir.
8. Evidence olmadan rate limit tuning adımına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- TUNING_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

