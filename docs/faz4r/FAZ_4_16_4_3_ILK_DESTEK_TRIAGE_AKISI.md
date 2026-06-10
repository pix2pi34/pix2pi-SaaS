# 212 — FAZ 4-16.4.3 İlk Destek Triage Akışı

## Amaç

Controlled pilot sırasında kullanıcıdan gelen ilk destek/hata bildirimlerini standart triage akışına sokar.

Bu adım 211 Yardım Merkezi İçeriği PASS olduktan sonra destek taleplerinin sınıflandırılması, önceliklendirilmesi, doğru kişiye yönlendirilmesi ve kanıtla kapatılması için ilk destek triage standardını kurar.

## Kapsam

İlk destek triage akışı aşağıdaki başlıkları kapsar:

- Destek intake formu
- Issue sınıflandırma
- P0 blocker sınıfı
- P1 critical sınıfı
- P2 normal sınıfı
- P3 question sınıfı
- Product owner yönlendirme
- Technical owner yönlendirme
- Support owner yönlendirme
- İlk yanıt SLA matrisi
- Evidence attachment kuralı
- Duplicate issue guard
- Kapalı canlı provider policy route
- İlk yanıt template
- Triage completion checklist

## Ana Kural

Bu adım gerçek ticket sistemi, gerçek e-posta gönderimi, gerçek müşteri destek sistemi veya canlı provider bağlantısı açmaz.

Bu adım public production support launch değildir.

Bu adım controlled pilot ilk destek triage standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

İlk destek triage akışı PASS sayılırsa:

- triage_status = READY olmalıdır.
- triage_mode = CONTROLLED_PILOT olmalıdır.
- required triage flow'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_flow_count gerçek flow sayısıyla eşleşmelidir.
- ready_flow_count gerçek READY sayısıyla eşleşmelidir.
- missing_flow_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- training_set_status = PASS olmalıdır.
- help_center_status = PASS olmalıdır.
- intake_channel_status = READY olmalıdır.
- severity_matrix_status = READY olmalıdır.
- routing_matrix_status = READY olmalıdır.
- response_sla_status = READY olmalıdır.
- evidence_attachment_status = READY olmalıdır.
- no_real_external_dispatch = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- İlk destek triage dokümanı vardır.
- Master config artifact vardır.
- Initial support triage flow artifact vardır.
- Support triage dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid triage fixture PASS döner.
- Invalid triage fixture FAIL döner.
- Required flow guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Intake channel guard doğrulanır.
- Severity matrix guard doğrulanır.
- Routing matrix guard doğrulanır.
- No real external dispatch guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
