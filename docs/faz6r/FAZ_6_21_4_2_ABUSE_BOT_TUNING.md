# FAZ 6-R / 281 — FAZ 6-21.4.2 Abuse / Bot Tuning

## Amaç

Pix2pi edge katmanında abuse, bot, scanner, credential-stuffing ve otomatik kötüye kullanım trafiğine karşı provider-neutral tuning standardını tanımlar.

Bu adım canlı Cloudflare veya edge provider üzerinde doğrudan rule push yapmaz. Önce bot/abuse tuning sözleşmesi, fixture, validator, audit ve evidence üretir.

## Bağımlılık

Bu adım FAZ 6-21.4.1 WAF tuning sonrasında çalışır.

## Required Controls

- bot_score_policy
- suspicious_automation_guard
- credential_stuffing_guard
- login_rate_anomaly_guard
- api_scraping_guard
- high_error_rate_guard
- bad_user_agent_guard
- impossible_path_guard
- tenant_abuse_signal_policy
- allowlist_policy
- false_positive_review_policy
- safe_rollout_policy
- rollback_policy
- evidence_audit_policy

## Abuse / Bot Tuning Prensipleri

1. Login ve auth yüzeyinde düşük tolerans
2. Public landing yüzeyinde yüksek false-positive toleransı
3. API scraping davranışlarında challenge-first yaklaşımı
4. Known bad user-agent ve impossible path için enforce/block
5. Tenant bazlı abuse signal üretimi
6. Admin/panel rotalarında daha sıkı koruma
7. Sağlık endpointlerinde gereksiz challenge/block yok
8. Önce observe, sonra challenge, en son enforce
9. Allowlist kontrollü ve kanıtlı olmalı
10. Rollback planı olmadan enforce yapılmaz

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

