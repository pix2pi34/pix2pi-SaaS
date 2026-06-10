# 194 — FAZ 4-16.1.6 Onboarding Smoke

## Amaç

Pilot tenant kabulünden sonra gerçek pilot açılışına geçmeden önce onboarding smoke kapısını kurar.

Bu adım tenant'ın onboarding sürecine güvenli şekilde alınabileceğini doğrular.

## Smoke Kapsamı

Onboarding smoke aşağıdaki alanları kontrol eder:

- Tenant acceptance PASS
- Pilot veri sınırları PASS
- Tenant kimliği hazır
- Tenant config hazır
- Tenant admin hazır
- Role baseline hazır
- Kullanıcı davet akışı hazır
- Import dry-run smoke hazır
- Readmodel/reporting smoke hazır
- Operational readmodel smoke hazır
- Support/issue kanalı hazır
- Rollback/cutover guard hazır
- Audit evidence hazır
- Kritik issue sayısı 0
- Canlı dış provider/GIB/banka/POS kapalı policy gate korunuyor

## Kabul Kuralı

Onboarding smoke PASS sayılırsa:

- onboarding_status = READY olmalıdır.
- tenant_acceptance_status = PASS olmalıdır.
- pilot_data_boundary_status = PASS olmalıdır.
- critical_issue_count = 0 olmalıdır.
- Her required smoke check PASS olmalıdır.
- Her required smoke check için evidence_ref dolu olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Dış Provider Policy

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Onboarding smoke dokümanı vardır.
- Config artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Required smoke evidence guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
