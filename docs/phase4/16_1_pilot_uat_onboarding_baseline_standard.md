# FAZ 4B / 16.1 - Pilot / UAT / Onboarding Baseline

Amaç:
Pix2pi FAZ 4B içinde pilot müşteri, UAT ve onboarding rollout için başlangıç kapsamını çıkarmak.

Bu adım:
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
- Sadece pilot scope, UAT senaryosu, onboarding checklist ve rollout gate metadata üretir.

Ön koşul:
- 17 Workflow / Realtime UI final closure PASS olmalı.
- 20 Infra Cleanup / Production Hardening PASS olmalı.
- 21 Security / RBAC / Audit PASS olmalı.
- 22 Observability / Ops Console final closure PASS olmalı.

Pilot hedefleri:
- Pilot tenant hazırlığı
- Pilot kullanıcı rolleri
- Pilot mağaza / şube / kasa hazırlığı
- Ürün / stok / cari / satış akışı doğrulaması
- Muhasebe / TDHP export doğrulama zemini
- Onboarding checklist
- UAT kabul kriterleri
- Feedback / support / incident loop
- Go / No-Go rollout gate

Kapanış hedefi:
PILOT_UAT_ONBOARDING_BASELINE=PASS
PILOT_PREVIOUS_FOUNDATION=PASS
PILOT_SCOPE_INVENTORY=PASS
PILOT_UAT_SCENARIO_CATALOG=PASS
PILOT_ONBOARDING_CHECKLIST=PASS
PILOT_ROLLOUT_GATE_MATRIX=PASS
PILOT_NO_RUNTIME_CHANGE=PASS
PILOT_NO_CONFIG_CHANGE=PASS
PILOT_SECRET_SAFE=PASS
FAZ4B_16_1_FINAL_STATUS=PASS
