# 233 — FAZ 4-16.8.3 Kritik Hata Sıfırlama

## Amaç

232 UAT Başarı Eşiği PASS olduktan sonra controlled pilot kapanışına girmeden önce kritik hata sayısını sıfırda tutma standardını kurar.

Bu adım canlıya geçiş kararı vermez. Sadece P0/P1 kritik hata, açık blocker, açık incident, regression fail ve exception durumlarının sıfır olduğunu ölçer, kanıtlar ve doğrular.

## Kapsam

- Critical reset kickoff
- UAT threshold link
- Critical issue inventory
- Severity classification
- P0/P1 zero target
- Resolution evidence index
- Regression test evidence
- Owner signoff
- Support confirmation
- Pilot tenant confirmation
- Incident backlog zero
- Open blocker zero
- Exception policy closed
- External policy closed gate
- Final critical reset report

## Ana Kural

Bu adım Go/No-Go kararı vermez.

Bu adım production launch yapmaz.

Bu adım canlı provider, GIB, banka, POS, ödeme sağlayıcı, DNS, Nginx veya SSL değişikliği yapmaz.

Bu adım sadece kritik hata sıfırlama validasyonu üretir.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Kritik hata sıfırlama PASS sayılırsa:

- critical_issue_reset_status = READY olmalıdır.
- critical_issue_reset_mode = CONTROLLED_PILOT olmalıdır.
- required reset item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- p0_issue_count = 0 olmalıdır.
- p1_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- open_incident_count = 0 olmalıdır.
- regression_fail_count = 0 olmalıdır.
- exception_count = 0 olmalıdır.
- uat_threshold_status = PASS olmalıdır.
- resolution_evidence_status = READY olmalıdır.
- regression_evidence_status = READY olmalıdır.
- owner_signoff_status = READY olmalıdır.
- support_confirmation_status = READY olmalıdır.
- tenant_confirmation_status = READY olmalıdır.
- no_go_no_go_decision = true olmalıdır.
- no_production_launch = true olmalıdır.
- no_live_external_provider_activation = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Kritik hata sıfırlama dokümanı vardır.
- Master config artifact vardır.
- Critical issue reset artifact vardır.
- Reset item kanıt dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid reset fixture PASS döner.
- Invalid reset fixture FAIL döner.
- Required item guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- P0/P1/critical/open blocker/open incident/regression/exception zero guard doğrulanır.
- UAT threshold dependency guard doğrulanır.
- Owner/support/tenant confirmation guard doğrulanır.
- No Go/No-Go decision / no production launch / no provider activation guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
