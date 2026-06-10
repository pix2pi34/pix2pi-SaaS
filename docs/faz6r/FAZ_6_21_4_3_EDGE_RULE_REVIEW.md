# FAZ 6-R / 282 — FAZ 6-21.4.3 Edge Rule Review

## Amaç

Pix2pi edge katmanındaki route, güvenlik, cache, redirect, header ve provider-neutral rule setlerini gözden geçirip release öncesi edge rule review standardını oluşturur.

Bu adım canlı Cloudflare veya edge provider üzerinde doğrudan rule push yapmaz. Edge rule review dokümanı, config sözleşmesi, fixture, validator, audit ve evidence üretir.

## Bağımlılıklar

- FAZ 6-21.4.1 WAF tuning
- FAZ 6-21.4.2 Abuse / bot tuning

## Required Controls

- waf_dependency_gate
- abuse_bot_dependency_gate
- public_private_route_boundary
- api_route_policy_review
- auth_route_policy_review
- panel_route_policy_review
- health_route_policy_review
- static_asset_cache_policy_review
- redirect_canonical_policy_review
- security_header_policy_review
- origin_lockdown_policy_review
- edge_cache_bypass_policy_review
- webhook_route_exception_review
- tenant_header_edge_observability_review
- rollback_policy
- evidence_audit_policy

## Edge Rule Review Prensipleri

1. Public web rotaları ile private API rotaları net ayrılır.
2. Auth, panel ve API rotaları daha sıkı edge policy altında tutulur.
3. Health endpointler gereksiz challenge veya block altında kalmaz.
4. Static asset rotaları cache edilebilir ama API rotaları cache edilmez.
5. Webhook rotaları edge üzerinde aşırı boğulmaz; imza doğrulama application layer'da kalır.
6. Canonical redirect kararı belgelenir.
7. Security header standardı netleşir.
8. Origin lockdown ileride provider seviyesinde uygulanacak şekilde kapı açar.
9. Rollback planı olmadan enforce değişikliği yapılmaz.
10. Bu adım canlı provider mutation yapmaz.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

