# FAZ 4B / 16.2 - Pilot Tenant Readiness / Role & Onboarding Contract

Amaç:
Pilot tenant, kullanıcı rolleri, onboarding sorumluları, eğitim/destek planı ve kabul kanıtlarını sözleşme olarak netleştirmek.

Bu adım:
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
- Sadece pilot readiness, role/permission, onboarding ownership, evidence ve training/support metadata üretir.

Ön koşul:
- 16.1 Pilot / UAT / Onboarding baseline PASS olmalı.
- 17 Workflow / Realtime UI final closure PASS olmalı.
- 20 Infra Cleanup / Production Hardening PASS olmalı.
- 21 Security / RBAC / Audit PASS olmalı.
- 22 Observability / Ops Console final closure PASS olmalı.

Hazırlık hedefleri:
- Pilot tenant readiness catalog
- Pilot role / permission matrix
- Onboarding owner matrix
- Evidence / acceptance matrix
- Training / support plan
- No-runtime-change / no-config-change / no-secret safety

Kapanış hedefi:
PILOT_TENANT_READINESS_CONTRACT=PASS
PILOT_TENANT_PREVIOUS_16_1=PASS
PILOT_TENANT_READINESS_CATALOG=PASS
PILOT_ROLE_PERMISSION_MATRIX=PASS
PILOT_ONBOARDING_OWNER_MATRIX=PASS
PILOT_EVIDENCE_ACCEPTANCE_MATRIX=PASS
PILOT_TRAINING_SUPPORT_PLAN=PASS
PILOT_TENANT_NO_RUNTIME_CHANGE=PASS
PILOT_TENANT_NO_CONFIG_CHANGE=PASS
PILOT_TENANT_SECRET_SAFE=PASS
FAZ4B_16_2_FINAL_STATUS=PASS
