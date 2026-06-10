# 229 — FAZ 4-16.7.4 İletişim Planı

## Amaç

228 Geri Dönüş Provası PASS olduktan sonra controlled pilot cutover/dry-run/canlı hazırlık iletişim planını standartlaştırır.

Bu adım gerçek e-posta, SMS, WhatsApp, status page yayını veya public announcement göndermez. Sadece iletişim alıcılarını, kanal planını, mesaj taslaklarını, zaman penceresini, destek nöbetini, rollback mesajını, onay sahibini ve kanıt bağlantılarını hazırlar.

## Kapsam

- Communication kickoff
- Audience map
- Channel map
- Message owner assignment
- Timing window
- Pre-cutover message draft
- During-cutover message draft
- Rollback message draft
- Support contact note
- Incident escalation note
- Tenant admin notice
- User FAQ draft
- Internal ops note
- Status page draft
- Approval owner confirmation
- External provider policy closed gate
- Final communication report

## Ana Kural

Bu adım gerçek bildirim göndermez.

Bu adım public announcement yayınlamaz.

Bu adım production launch yapmaz.

Bu adım DNS, Nginx, SSL, provider, GIB, banka, POS, ödeme sağlayıcı veya production route değişikliği yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

İletişim planı PASS sayılırsa:

- communication_plan_status = READY olmalıdır.
- communication_plan_mode = CONTROLLED_PILOT olmalıdır.
- required communication item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- rollback_rehearsal_status = PASS olmalıdır.
- audience_map_status = READY olmalıdır.
- channel_map_status = READY olmalıdır.
- message_draft_status = READY olmalıdır.
- support_contact_status = READY olmalıdır.
- incident_escalation_status = READY olmalıdır.
- approval_owner_status = READY olmalıdır.
- no_real_email_dispatch = true olmalıdır.
- no_real_sms_dispatch = true olmalıdır.
- no_real_whatsapp_dispatch = true olmalıdır.
- no_public_announcement = true olmalıdır.
- no_production_launch = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- İletişim planı dokümanı vardır.
- Master config artifact vardır.
- Communication plan artifact vardır.
- Communication item kanıt dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid communication fixture PASS döner.
- Invalid communication fixture FAIL döner.
- Required item guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Audience/channel/message/support/escalation/approval guard doğrulanır.
- No real email/SMS/WhatsApp/public announcement/production launch guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
