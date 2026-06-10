# FAZ 6-R / 299 — FAZ 6-21.3.4 Rate Limit Tuning

## Amaç

Pix2pi API gateway, auth, tenant, public web, panel, POS ve webhook yüzeyleri için rate limit tuning standardını kurar.

Bu adım canlı gateway, Redis, Cloudflare/WAF, Nginx veya application rate limit mutation yapmaz. Sadece rate limit sinyalleri, tenant bazlı limit modeli, burst policy, false-positive guard, abuse/bot/WAF bağı, dry-run öneri çıktısı ve evidence üretir.

## Bağımlılık

- FAZ 6-21.3.3 Cache hit/miss tuning

## Required Controls

- cache_hit_miss_dependency_gate
- rate_limit_surface_inventory
- tenant_rate_limit_model
- route_rate_limit_model
- auth_bruteforce_guard
- api_abuse_guard
- webhook_rate_limit_guard
- public_web_rate_limit_guard
- burst_policy_review
- false_positive_guard
- redis_namespace_guard
- edge_waf_alignment_guard
- dry_run_tuning_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Rate Limit Tuning İlkeleri

1. Canlı rate limit değişikliği bu adımda yapılmaz.
2. Tenant bazlı namespace ve route bazlı limit ayrımı korunur.
3. Auth/bruteforce yüzeyi yüksek risklidir; gevşetme önerisi security owner review gerektirir.
4. Webhook yüzeyi idempotency ve provider retry davranışıyla birlikte değerlendirilir.
5. Public web rate limit SEO ve gerçek kullanıcı trafiği false-positive guard ile korunur.
6. Abuse/bot ve WAF tuning ile çelişen öneri üretilemez.
7. Redis rate limit key namespace korunmadan tuning uygulanamaz.
8. Evidence olmadan DB HA topolojisi bloğuna geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- TUNING_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

