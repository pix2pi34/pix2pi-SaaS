# FAZ 4B / 17.1 - Workflow / Realtime UI Baseline / Surface Inventory

Amaç:
Pix2pi panel, workflow ve realtime UI tarafı için başlangıç sözleşmesini çıkarmak.

Bu adım:
- UI kodu yazmaz.
- API route oluşturmaz.
- Backend implementation yapmaz.
- WebSocket / SSE server başlatmaz.
- Workflow engine runtime değiştirmez.
- DB tablo / migration oluşturmaz.
- DB apply yapmaz.
- DB mutate etmez.
- Event Bus publish/consume yapmaz.
- Servis restart etmez.
- Container restart etmez.
- Docker compose up/down/restart çalıştırmaz.
- Nginx reload/restart yapmaz.
- Firewall değiştirmez.
- Port kapatmaz/açmaz.
- Config/env değiştirmez.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece workflow domain, realtime signal, UI surface, API candidate ve event binding metadata üretir.

Ön koşul:
- FAZ 4B / 22 Observability / Ops Console final closure PASS olmalı.
- 20 Infra Cleanup / Production Hardening PASS olmalı.
- 21 Security / RBAC / Audit PASS olmalı.

Kontrol alanları:
- Workflow domain inventory
- Workflow state model
- Workflow action model
- Approval / task / job / notification binding
- Realtime signal contract
- SSE / WebSocket candidate channels
- UI surface contract
- API surface candidate inventory
- Event binding placeholder
- Tenant / RBAC / audit visibility standardı
- No-runtime-change / no-config-change / no-secret safety

Production hedef prensibi:
- Workflow her tenant için izole çalışmalı.
- UI surface RBAC kontrollü olmalı.
- Realtime sinyaller tenant_id, user_id, request_id, event_id, severity ve source taşımalı.
- Ham event/log/secret UI tarafına taşınmamalı.
- Panel sadece normalize edilmiş status/action metadata okumalı.
- Gerçek API/UI implementation sonraki adımlarda yapılmalı.

Kapanış hedefi:
WORKFLOW_REALTIME_BASELINE=PASS
WORKFLOW_PREVIOUS_22=PASS
WORKFLOW_DOMAIN_INVENTORY=PASS
WORKFLOW_REALTIME_SIGNAL_CONTRACT=PASS
WORKFLOW_UI_SURFACE_CONTRACT=PASS
WORKFLOW_API_SURFACE_CANDIDATES=PASS
WORKFLOW_NO_RUNTIME_CHANGE=PASS
WORKFLOW_NO_CONFIG_CHANGE=PASS
WORKFLOW_SECRET_SAFE=PASS
FAZ4B_17_1_FINAL_STATUS=PASS
