# 218 — FAZ 4-16.5.1 Pilot Health Dashboard

## Amaç

Controlled pilot operasyonları için tek bakışta sağlık görünümü sağlayan pilot health dashboard standardını kurar.

Bu adım 217 Pilot Operations Testleri PASS olduktan sonra pilot tenant için health, import, readmodel, UAT, support, escalation, rollback, KPI ve closed-policy durumlarının aynı panelde izlenmesini sağlar.

## Kapsam

Pilot health dashboard aşağıdaki widget alanlarını kapsar:

- Pilot tenant health summary
- Service health widget
- Import pipeline health widget
- Readmodel / reporting health widget
- UAT status widget
- Training / support health widget
- Support triage health widget
- Issue escalation health widget
- Rollback signal health widget
- KPI snapshot widget
- Open blocker / critical issue widget
- Closed provider policy widget
- Operations handoff widget
- Last review timestamp widget

## Ana Kural

Bu dashboard gerçek provider, GIB, banka, POS veya ödeme sağlayıcı bağlantısı açmaz.

Bu dashboard production launch paneli değildir.

Bu dashboard yalnızca controlled pilot health görünümüdür.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Pilot health dashboard PASS sayılırsa:

- dashboard_status = READY olmalıdır.
- dashboard_mode = CONTROLLED_PILOT olmalıdır.
- required widget'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_widget_count gerçek widget sayısıyla eşleşmelidir.
- ready_widget_count gerçek READY sayısıyla eşleşmelidir.
- missing_widget_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- pilot_operations_tests_status = PASS olmalıdır.
- last_review_status = PASS olmalıdır.
- rollback_signal_status = CLEAR olmalıdır.
- operations_handoff_ready = YES olmalıdır.
- html_dashboard_status = READY olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Pilot health dashboard dokümanı vardır.
- Master config artifact vardır.
- Dashboard data artifact vardır.
- Static HTML dashboard artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid dashboard fixture PASS döner.
- Invalid dashboard fixture FAIL döner.
- Required widget guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Open blocker zero guard doğrulanır.
- Closed provider policy guard doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
