# 222 — FAZ 4-16.6.2 Değişiklik Sınıflandırma

## Amaç

Controlled pilot sırasında toplanan feedback, UAT notu, destek girdisi, incident girdisi ve günlük review notlarının ürün değişikliği mi, hata mı, operasyonel iyileştirme mi, eğitim ihtiyacı mı yoksa sonraya bırakılacak karar mı olduğunu standart şekilde sınıflandırır.

Bu adım 221 Feedback Toplama Kanalı PASS olduktan sonra feedback closure ve hızlı düzeltme hattına gidecek girdilerin ön sınıflandırmasını kurar.

## Kapsam

- Feedback intake classification
- Bug / defect classification
- UX improvement classification
- Training gap classification
- Support process classification
- Data/import issue classification
- Reporting/readmodel issue classification
- Integration/provider policy classification
- Priority mapping
- Severity mapping
- Owner routing
- Product decision candidate marker
- Quick fix candidate marker
- Deferred change marker
- Rejection / out-of-scope marker

## Ana Kural

Bu adım değişikliği otomatik uygulamaz.

Bu adım hotfix deploy yapmaz.

Bu adım gerçek ticket sistemi veya gerçek CRM sistemi açmaz.

Bu adım production launch kararı vermez.

Bu adım canlı dış provider, GIB, banka, POS veya ödeme sağlayıcı aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Değişiklik sınıflandırma PASS sayılırsa:

- classification_status = READY olmalıdır.
- classification_mode = CONTROLLED_PILOT olmalıdır.
- required classification rule'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_rule_count gerçek rule sayısıyla eşleşmelidir.
- ready_rule_count gerçek READY sayısıyla eşleşmelidir.
- missing_rule_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- feedback_channel_status = PASS olmalıdır.
- priority_mapping_status = READY olmalıdır.
- severity_mapping_status = READY olmalıdır.
- owner_routing_status = READY olmalıdır.
- quick_fix_candidate_status = READY olmalıdır.
- product_decision_candidate_status = READY olmalıdır.
- no_auto_apply_change = true olmalıdır.
- no_hotfix_deploy = true olmalıdır.
- no_real_crm_system = true olmalıdır.
- no_real_ticket_system = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Değişiklik sınıflandırma dokümanı vardır.
- Master config artifact vardır.
- Classification artifact vardır.
- Classification rule kanıt dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid classification fixture PASS döner.
- Invalid classification fixture FAIL döner.
- Required rule guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Priority/severity/owner routing guard doğrulanır.
- No auto apply / no hotfix guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
