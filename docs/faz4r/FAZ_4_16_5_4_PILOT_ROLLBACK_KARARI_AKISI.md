# 216 — FAZ 4-16.5.4 Pilot Rollback Kararı Akışı

## Amaç

Controlled pilot sırasında rollback gerekip gerekmediğini karar standardına bağlar.

Bu adım 215 Günlük Pilot Review PASS olduktan sonra rollback sinyali, blocker, critical issue, veri güvenliği, owner onayı, iletişim ve karar defteri üzerinden **karar akışı** kurar.

## Kapsam

- Rollback signal intake
- P0/P1 rollback trigger matrix
- Open blocker değerlendirme
- Data safety precheck
- Tenant impact assessment
- Owner approval matrix
- No-rollback decision path
- Rollback candidate decision path
- Communication precheck
- Recovery validation plan
- Evidence attachment rule
- Decision log link
- Closed provider policy review
- Real rollback execution closed gate

## Ana Kural

Bu adım gerçek rollback çalıştırmaz.

Bu adım deploy, hotfix veya production launch yapmaz.

Bu adım sadece rollback karar akışını standardize eder.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Pilot rollback kararı akışı PASS sayılırsa:

- rollback_decision_status = READY olmalıdır.
- rollback_decision_mode = CONTROLLED_PILOT olmalıdır.
- required decision rule'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_rule_count gerçek rule sayısıyla eşleşmelidir.
- ready_rule_count gerçek READY sayısıyla eşleşmelidir.
- missing_rule_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- daily_pilot_review_status = PASS olmalıdır.
- rollback_signal_status = CLEAR olmalıdır.
- rollback_decision_result = NO_ROLLBACK_REQUIRED olmalıdır.
- owner_approval_matrix_status = READY olmalıdır.
- recovery_validation_plan_status = READY olmalıdır.
- communication_precheck_status = READY olmalıdır.
- decision_log_status = READY olmalıdır.
- no_real_rollback_execution = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Rollback karar dokümanı vardır.
- Master config artifact vardır.
- Rollback decision flow artifact vardır.
- Rollback karar dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid rollback decision fixture PASS döner.
- Invalid rollback decision fixture FAIL döner.
- Required rule guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Rollback signal clear guard doğrulanır.
- No real rollback execution guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
