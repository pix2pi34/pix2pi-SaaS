# FAZ 6-R / 304 — FAZ 6-21.1.4 Session / Sticky Policy

## Amaç

Pix2pi runtime katmanında session, sticky routing, tenant-aware affinity ve stateless fallback standardını kurar.

Bu adım canlı gateway, load balancer, Nginx, Redis session store, cookie policy, DNS/LB, deployment rollout veya provider mutation yapmaz. Sadece session/sticky policy modeli, tenant-aware affinity guard, stateless fallback, failover davranışı, dry-run policy snapshot ve evidence üretir.

## Bağımlılık

- FAZ 6-21.1.2 Service discovery runtime tuning

## Required Controls

- service_discovery_dependency_gate
- session_surface_inventory
- sticky_affinity_policy
- tenant_aware_affinity_guard
- stateless_fallback_policy
- session_store_health_policy
- cookie_security_policy
- failover_affinity_policy
- websocket_sse_affinity_policy
- pos_offline_session_policy
- gateway_lb_alignment_guard
- dry_run_session_policy_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Session / Sticky İlkeleri

1. Canlı LB sticky policy değişikliği bu adımda yapılmaz.
2. Tenant-aware affinity bozulamaz.
3. Session store health sinyali olmadan sticky davranışı değiştirilemez.
4. Stateless fallback her zaman tanımlı olmalıdır.
5. POS/offline akışı sticky session’a bağımlı hale getirilemez.
6. WebSocket/SSE için affinity ayrı policy ile değerlendirilir.
7. Cookie güvenlik ayarları production mutation olmadan review-only kalır.
8. Manual approval olmadan gateway/LB/session mutation yapılmaz.
9. Evidence olmadan node health fencing adımına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- POLICY_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

