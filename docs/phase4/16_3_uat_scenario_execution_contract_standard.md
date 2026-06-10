# FAZ 4B / 16.3 - UAT Scenario Execution Contract

Amaç:
Pilot / UAT / Onboarding rollout için UAT senaryolarını çalıştırma sözleşmesine çevirmek.

Bu adım:
- Gerçek UAT çalıştırmaz.
- Gerçek satış / stok / muhasebe işlemi oluşturmaz.
- Gerçek tenant oluşturmaz.
- Gerçek kullanıcı oluşturmaz.
- Şifre/token üretmez.
- Uygulama kodu yazmaz.
- UI kodu yazmaz.
- API route oluşturmaz.
- Backend implementation yapmaz.
- DB tablo / migration oluşturmaz.
- DB apply yapmaz.
- DB mutate etmez.
- Event Bus publish/consume yapmaz.
- Notification göndermez.
- Servis restart etmez.
- Container restart etmez.
- Docker compose up/down/restart çalıştırmaz.
- Nginx reload/restart yapmaz.
- Firewall değiştirmez.
- Port kapatmaz/açmaz.
- Config/env değiştirmez.
- Secret değeri, raw DSN, token, password veya müşteri hassas verisi rapora basmaz.
- Sadece UAT execution plan, actor matrix, evidence matrix ve blocker policy metadata üretir.

Ön koşul:
- 16.1 Pilot / UAT / Onboarding baseline PASS olmalı.
- 16.2 Pilot tenant readiness / role & onboarding contract PASS olmalı.
- 17 Workflow / Realtime UI final closure PASS olmalı.
- 20 Infra Cleanup / Production Hardening PASS olmalı.
- 21 Security / RBAC / Audit PASS olmalı.
- 22 Observability / Ops Console final closure PASS olmalı.

UAT execution hedefleri:
- P0 senaryolar rollout blocker olarak işaretlenmeli.
- P1 senaryolar kontrollü workaround ile ilerleyebilir olmalı.
- Her senaryoda aktör, ön koşul, execution step ve beklenen evidence net olmalı.
- Her mutating senaryoda audit evidence zorunlu olmalı.
- Tenant isolation ve RBAC testleri P0 olmalı.
- Satış / stok / muhasebe zinciri P0 olmalı.
- Go / No-Go kararı P0 olmalı.
- Secret, raw payload, token, password, raw DSN rapora basılmamalı.

Kapanış hedefi:
UAT_SCENARIO_EXECUTION_CONTRACT=PASS
UAT_PREVIOUS_16_2=PASS
UAT_EXECUTION_PLAN=PASS
UAT_ACTOR_MATRIX=PASS
UAT_EVIDENCE_MATRIX=PASS
UAT_BLOCKER_POLICY=PASS
UAT_NO_RUNTIME_CHANGE=PASS
UAT_NO_CONFIG_CHANGE=PASS
UAT_SECRET_SAFE=PASS
FAZ4B_16_3_FINAL_STATUS=PASS
