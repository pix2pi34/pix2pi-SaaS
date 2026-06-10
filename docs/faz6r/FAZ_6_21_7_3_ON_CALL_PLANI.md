# FAZ 6-R / 287 — FAZ 6-21.7.3 On-call Planı

## Amaç

Pix2pi SRE operasyonları için on-call plan standardını kurar.

Bu adım gerçek pager, SMS, telefon, e-posta veya dış notification provider entegrasyonu açmaz. Önce on-call rol modeli, coverage standardı, severity response hedefleri, handoff prosedürü, override kuralı, evidence zorunluluğu ve escalation zincirine geçiş kapısı oluşturulur.

## Bağımlılık

- FAZ 6-21.7.2 Otomatik remediation

## Required Controls

- auto_remediation_dependency_gate
- on_call_role_model
- primary_secondary_coverage_policy
- severity_response_target_policy
- handoff_policy
- override_policy
- fatigue_management_policy
- incident_commander_policy
- notification_provider_closed_policy
- escalation_placeholder_policy
- evidence_capture_policy
- final_status_policy

## On-call İlkeleri

1. Her kritik zaman diliminde primary ve secondary owner bulunur.
2. P0/P1 olaylarda incident commander atanır.
3. On-call planı escalation zincirinin yerine geçmez; 288'de escalation zinciri detaylanır.
4. Gerçek notification provider bu adımda açılmaz.
5. Handoff kanıtı olmadan nöbet devri tamam sayılmaz.
6. Override sadece sebep, süre ve owner ile yapılır.
7. Fatigue yönetimi için maksimum aralıksız nöbet sınırı bulunur.
8. Her incident için evidence zorunludur.
9. Bu adım canlı pager/SMS/e-posta gönderimi yapmaz.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- PLAN_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

