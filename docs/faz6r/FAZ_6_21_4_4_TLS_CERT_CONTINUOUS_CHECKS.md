# FAZ 6-R / 283 — FAZ 6-21.4.4 TLS / Cert Continuous Checks

## Amaç

Pix2pi edge ve public domain yüzeyleri için TLS, sertifika, süre bitimi, HTTPS zorunluluğu ve security header süreklilik kontrol standardını kurar.

Bu adım canlı certificate provider üzerinde doğrudan değişiklik yapmaz. Önce provider-neutral TLS/cert continuous check sözleşmesi, fixture, validator, audit ve evidence üretir.

## Bağımlılık

- FAZ 6-21.4.3 Edge rule review

## Required Controls

- edge_rule_review_dependency_gate
- tls_domain_inventory
- certificate_expiry_check_policy
- https_enforcement_policy
- hsts_policy
- tls_min_version_policy
- certificate_chain_validation_policy
- canonical_host_tls_policy
- api_domain_tls_policy
- auth_domain_tls_policy
- panel_domain_tls_policy
- alert_threshold_policy
- scheduled_check_policy
- rollback_policy
- evidence_audit_policy

## TLS / Cert Continuous Check Prensipleri

1. Tüm public domainler TLS kontrol listesine girer.
2. Sertifika expiry eşiği kritik/uyarı olarak ayrılır.
3. HTTPS zorunluluğu edge standardında tutulur.
4. HSTS production public yüzeyde zorunlu kabul edilir.
5. TLS minimum sürüm standardı TLS 1.2 altına düşmez.
6. API, auth ve panel domainleri ayrı izlenir.
7. Certificate chain validation zorunludur.
8. Scheduled check ileride cron/monitor job olarak bağlanabilir.
9. Bu adım live certificate mutation yapmaz.
10. Evidence olmadan release gate açılmaz.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

