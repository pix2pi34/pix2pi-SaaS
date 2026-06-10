# FAZ 6-R / 288 — FAZ 6-21.7.4 Escalation Zinciri

## Amaç

Pix2pi SRE operasyonları için olay seviyesine göre escalation zincirini tanımlar.

Bu adım gerçek SMS, telefon, pager, e-posta veya dış notification provider entegrasyonu açmaz. Escalation zinciri provider-neutral ve evidence-first şekilde kurulur.

## Bağımlılık

- FAZ 6-21.7.3 On-call planı

## Required Controls

- on_call_dependency_gate
- escalation_level_model
- severity_to_escalation_mapping
- ack_timeout_policy
- p0_escalation_chain
- p1_escalation_chain
- p2_escalation_chain
- p3_escalation_chain
- business_owner_notification_policy
- security_owner_notification_policy
- technical_owner_notification_policy
- manual_approval_policy
- provider_closed_policy
- evidence_capture_policy
- final_status_policy

## Escalation İlkeleri

1. P0 olaylarda hızlı escalation zorunludur.
2. P1 olaylarda incident commander ve SRE owner devrededir.
3. P2 olaylarda primary/secondary ve owner takibi yeterlidir.
4. P3 olaylarda takip ve kayıt esastır.
5. Gerçek notification provider bu adımda kapalıdır.
6. Ack timeout aşılırsa bir üst seviyeye çıkar.
7. Business, security ve technical owner ayrımı korunur.
8. Production mutation kararları manual approval gerektirir.
9. Her escalation kararı evidence üretir.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- CHAIN_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

