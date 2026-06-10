# 232 — FAZ 4-16.8.2 UAT Başarı Eşiği

## Amaç

231 Pilot KPI Değerlendirmesi PASS olduktan sonra controlled pilot kapanışı için UAT başarı eşiği standardını kurar.

Bu adım Go/No-Go kararı vermez. Sadece yönetim paneli, POS, muhasebe, muhasebeci portalı, e-Belge/export ve genel UAT sign-off sonuçlarının eşik değerlerine göre ölçülebilir şekilde uygun olup olmadığını doğrular.

## Kapsam

- UAT threshold kickoff
- Pilot KPI evaluation link
- Management panel UAT threshold
- POS UAT threshold
- Accounting UAT threshold
- Accountant portal UAT threshold
- e-Belge/export UAT threshold
- Required case pass threshold
- Critical issue zero threshold
- Open blocker zero threshold
- Evidence completeness threshold
- Sign-off completeness threshold
- Exception policy threshold
- External policy closed threshold
- Final UAT threshold report

## Ana Kural

Bu adım Go/No-Go kararı vermez.

Bu adım production launch yapmaz.

Bu adım canlı provider, GIB, banka, POS, ödeme sağlayıcı, DNS, Nginx veya SSL değişikliği yapmaz.

Bu adım sadece UAT başarı eşiği üretir ve doğrular.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

UAT başarı eşiği PASS sayılırsa:

- uat_threshold_status = READY olmalıdır.
- uat_threshold_mode = CONTROLLED_PILOT olmalıdır.
- required threshold item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- pilot_kpi_status = PASS olmalıdır.
- management_panel_uat_status = PASS olmalıdır.
- pos_uat_status = PASS olmalıdır.
- accounting_uat_status = PASS olmalıdır.
- accountant_portal_uat_status = PASS olmalıdır.
- edocument_export_uat_status = PASS olmalıdır.
- required_case_pass_rate >= 100 olmalıdır.
- evidence_completeness_rate >= 100 olmalıdır.
- signoff_completeness_rate >= 100 olmalıdır.
- no_go_no_go_decision = true olmalıdır.
- no_production_launch = true olmalıdır.
- no_live_external_provider_activation = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- UAT başarı eşiği dokümanı vardır.
- Master config artifact vardır.
- UAT threshold artifact vardır.
- UAT threshold item kanıt dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid UAT threshold fixture PASS döner.
- Invalid UAT threshold fixture FAIL döner.
- Required item guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Yönetim/POS/muhasebe/muhasebeci/e-Belge UAT guard doğrulanır.
- Required case/evidence/signoff threshold guard doğrulanır.
- No Go/No-Go decision / no production launch / no provider activation guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
