# FAZ 6-R / 280 — FAZ 6-21.4.1 WAF Tuning

## Amaç

Pix2pi edge güvenlik katmanı için WAF tuning standardını tanımlar.

Bu adım canlı Cloudflare veya edge provider üzerinde doğrudan kural değiştirmez. Önce provider-neutral WAF tuning sözleşmesi, fixture, validator, audit ve evidence üretir.

## Required Controls

- managed_waf_baseline
- api_abuse_surface_guard
- auth_bruteforce_guard
- tenant_api_header_presence_guard
- dangerous_method_block
- scanner_exploit_path_guard
- upload_boundary_guard
- health_endpoint_safe_policy
- safe_rollout_policy
- rollback_policy
- evidence_audit_policy

## Rollout Model

1. observe / log only
2. challenge / managed challenge
3. enforce / block
4. rollback / previous stable policy

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

