# 214 — FAZ 4-16.4.5 Eğitim / Destek Smoke

## Amaç

Controlled pilot için kullanıcı eğitim seti, yardım merkezi, ilk destek triage ve pilot issue escalation akışlarının uçtan uca smoke doğrulamasını yapar.

Bu adım 210–213 arası eğitim/destek bloklarının birlikte çalışmaya hazır olduğunu mühürler.

## Kapsam

- Eğitim seti erişilebilirlik smoke
- Yardım merkezi içerik smoke
- Destek intake smoke
- Triage sınıflandırma smoke
- Escalation yönlendirme smoke
- Evidence attachment smoke
- Owner matrix smoke
- SLA matrix smoke
- Closed provider policy smoke
- Pilot kullanıcı first response smoke
- Completion checklist smoke
- Eğitim/destek final handoff smoke

## Ana Kural

Bu adım gerçek ticket sistemi açmaz.

Bu adım gerçek e-posta göndermez.

Bu adım hotfix deploy yapmaz.

Bu adım production support launch değildir.

Bu adım canlı dış provider, GIB, banka, POS veya ödeme sağlayıcı aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Eğitim / destek smoke PASS sayılırsa:

- smoke_status = READY olmalıdır.
- smoke_mode = CONTROLLED_PILOT olmalıdır.
- required smoke check'lerin tamamı PASS olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_check_count gerçek check sayısıyla eşleşmelidir.
- pass_check_count gerçek PASS sayısıyla eşleşmelidir.
- fail_check_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- training_set_status = PASS olmalıdır.
- help_center_status = PASS olmalıdır.
- triage_status = PASS olmalıdır.
- escalation_status = PASS olmalıdır.
- no_real_external_dispatch = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Eğitim / destek smoke dokümanı vardır.
- Master config artifact vardır.
- Smoke artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid smoke fixture PASS döner.
- Invalid smoke fixture FAIL döner.
- Required smoke check guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Dependency guard doğrulanır.
- No real external dispatch guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
