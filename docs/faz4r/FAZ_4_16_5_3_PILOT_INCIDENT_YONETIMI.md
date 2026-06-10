# 219 — FAZ 4-16.5.3 Pilot Incident Yönetimi

## Amaç

Controlled pilot sürecinde oluşabilecek incident kayıtlarının standart şekilde açılması, sınıflandırılması, owner atanması, timeline tutulması, kanıt bağlanması, escalation/rollback sinyaliyle ilişkilendirilmesi ve closure/post-review akışına alınmasını sağlar.

Bu adım 218 Pilot Health Dashboard PASS olduktan sonra pilot operasyon izleme yüzeyinden gelen incident sinyallerinin yönetim standardını kurar.

## Kapsam

- Incident intake
- Incident classification
- Severity P0/P1/P2/P3 mapping
- Incident owner assignment
- Incident timeline record
- Evidence attachment
- Incident status lifecycle
- Communication log
- Escalation link
- Rollback signal link
- Resolution note
- Post-review
- Closed provider policy incident route
- Incident closure checklist

## Ana Kural

Bu adım gerçek ticket sistemi açmaz.

Bu adım gerçek e-posta göndermez.

Bu adım rollback çalıştırmaz.

Bu adım hotfix deploy yapmaz.

Bu adım production launch yapmaz.

Bu adım canlı dış provider, GIB, banka, POS veya ödeme sağlayıcı aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Pilot incident yönetimi PASS sayılırsa:

- incident_management_status = READY olmalıdır.
- incident_management_mode = CONTROLLED_PILOT olmalıdır.
- required incident rule'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_rule_count gerçek rule sayısıyla eşleşmelidir.
- ready_rule_count gerçek READY sayısıyla eşleşmelidir.
- missing_rule_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- pilot_health_dashboard_status = PASS olmalıdır.
- incident_status_lifecycle = READY olmalıdır.
- escalation_link_status = READY olmalıdır.
- rollback_signal_link_status = READY olmalıdır.
- closure_checklist_status = READY olmalıdır.
- no_real_ticket_system = true olmalıdır.
- no_real_email_dispatch = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Pilot incident yönetimi dokümanı vardır.
- Master config artifact vardır.
- Incident management artifact vardır.
- Incident yönetimi kanıt dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid incident fixture PASS döner.
- Invalid incident fixture FAIL döner.
- Required incident rule guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Open blocker zero guard doğrulanır.
- No real ticket/email guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
