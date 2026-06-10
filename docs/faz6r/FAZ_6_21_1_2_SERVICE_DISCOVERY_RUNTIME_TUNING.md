# FAZ 6-R / 303 — FAZ 6-21.1.2 Service Discovery Runtime Tuning

## Amaç

Pix2pi servis keşfi, registry, health-based routing ve runtime discovery davranışı için tuning standardını kurar.

Bu adım canlı service registry mutation, DNS mutation, load balancer mutation, service route switch, container restart, deployment rollout veya provider mutation yapmaz. Sadece servis keşif sinyalleri, health TTL modeli, deregistration / stale endpoint guard, route confidence modeli, dry-run tuning çıktısı ve evidence üretir.

## Bağımlılık

- FAZ 6-21.2.5 Point-in-time recovery provası

## Required Controls

- pitr_dependency_gate
- service_inventory_model
- registry_health_ttl_policy
- stale_endpoint_guard
- deregistration_guard
- health_based_routing_guard
- service_route_confidence_policy
- dependency_graph_policy
- dns_lb_alignment_guard
- tenant_aware_service_guard
- dry_run_discovery_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Service Discovery İlkeleri

1. Canlı registry mutation bu adımda yapılmaz.
2. DNS, LB, gateway route ve deployment mutation kapalıdır.
3. Stale endpoint temizliği sadece öneri olarak üretilir.
4. Health TTL ve deregistration önerileri manual approval gerektirir.
5. Tenant-aware routing bozulamaz.
6. API gateway, auth, panel, POS, event consumer ve DB-facing servisler ayrı risk sınıfında değerlendirilir.
7. Route confidence düşükse otomatik route switch BLOCKED olur.
8. Evidence olmadan session / sticky policy adımına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- TUNING_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

