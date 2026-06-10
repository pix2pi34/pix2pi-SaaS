# FAZ 6-R / 286 — FAZ 6-21.7.2 Otomatik Remediation

## Amaç

Pix2pi SRE operasyonları için güvenli otomatik remediation standardını kurar.

Bu adım canlı production değişikliği yapmaz. Remediation motoru dry-run / guarded mode ile çalışır. Destructive veya production mutation içeren aksiyonlar otomatik uygulanmaz; manual approval ve evidence zorunludur.

## Bağımlılık

- FAZ 6-21.7.1 Runbook seti

## Required Controls

- runbook_dependency_gate
- remediation_rule_index
- dry_run_runtime
- manual_approval_gate
- no_destructive_default_policy
- production_mutation_guard
- evidence_capture_policy
- rollback_action_guard
- p0_p1_approval_policy
- safe_action_allowlist
- unsafe_action_denylist
- final_status_policy

## Remediation İlkeleri

1. Varsayılan mod dry-run olmalıdır.
2. Production restart, rollback, DB failover, data restore, firewall enforce ve destructive cleanup otomatik çalışmaz.
3. Sadece güvenli teşhis ve öneri aksiyonları otomatik üretilebilir.
4. P0/P1 olaylarda manual approval zorunludur.
5. Her remediation kararı evidence üretmelidir.
6. Her rule bir runbook ile bağlı olmalıdır.
7. Rollback aksiyonları sadece öneri olarak üretilir, otomatik uygulanmaz.
8. Bu adım canlı remediation çalıştırmaz.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- RULES_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

