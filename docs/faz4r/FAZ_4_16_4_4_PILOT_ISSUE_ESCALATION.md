# 213 — FAZ 4-16.4.4 Pilot Issue Escalation

## Amaç

Controlled pilot sırasında triage edilmiş issue'ların doğru escalation hattına alınmasını standartlaştırır.

Bu adım 212 İlk Destek Triage Akışı PASS olduktan sonra P0/P1/P2/P3 issue'ların owner, SLA, evidence, decision ve closure akışına göre yükseltilmesini sağlar.

## Kapsam

Pilot issue escalation aşağıdaki başlıkları kapsar:

- P0 blocker escalation
- P1 critical escalation
- P2 normal escalation
- P3 question escalation
- Product owner escalation
- Technical owner escalation
- Support owner escalation
- Business owner visibility
- Escalation SLA matrisi
- Evidence completeness guard
- Duplicate / linked issue guard
- Decision log bağlantısı
- Hotfix candidate marker
- Policy-only issue route
- Closure readiness checklist

## Ana Kural

Bu adım gerçek ticket sistemi, gerçek e-posta gönderimi, gerçek müşteri destek sistemi veya canlı provider bağlantısı açmaz.

Bu adım hotfix deploy yapmaz.

Bu adım sadece controlled pilot escalation standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Pilot issue escalation PASS sayılırsa:

- escalation_status = READY olmalıdır.
- escalation_mode = CONTROLLED_PILOT olmalıdır.
- required escalation rule'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_rule_count gerçek rule sayısıyla eşleşmelidir.
- ready_rule_count gerçek READY sayısıyla eşleşmelidir.
- missing_rule_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- triage_status = PASS olmalıdır.
- owner_matrix_status = READY olmalıdır.
- escalation_sla_status = READY olmalıdır.
- evidence_completeness_status = READY olmalıdır.
- decision_log_status = READY olmalıdır.
- no_real_external_dispatch = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Pilot issue escalation dokümanı vardır.
- Master config artifact vardır.
- Escalation artifact vardır.
- Escalation dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid escalation fixture PASS döner.
- Invalid escalation fixture FAIL döner.
- Required rule guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Owner matrix guard doğrulanır.
- Escalation SLA guard doğrulanır.
- Decision log guard doğrulanır.
- No real external dispatch guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
