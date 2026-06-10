# FAZ 4B / 17.5 - UI Surface + API Implementation Plan

Amaç:
Pix2pi Workflow / Realtime UI bloğu için UI sayfaları, widget yüzeyleri, API endpoint planı, permission mapping, implementation sırası ve test planını netleştirmek.

Bu adım:
- UI kodu yazmaz.
- React / frontend dosyası oluşturmaz.
- API route oluşturmaz.
- Backend implementation yapmaz.
- DTO / handler / middleware kodu yazmaz.
- WebSocket server başlatmaz.
- SSE server başlatmaz.
- Workflow runtime değiştirmez.
- Approval runtime değiştirmez.
- Realtime runtime değiştirmez.
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
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece UI/API implementation plan metadata üretir.

Ön koşul:
- 17.1 Workflow / Realtime UI baseline PASS olmalı.
- 17.2 Workflow state machine contract PASS olmalı.
- 17.3 Workflow action / approval contract PASS olmalı.
- 17.4 Realtime channel contract PASS olmalı.
- FAZ 4B / 22 Observability / Ops Console final closure PASS olmalı.
- 20 Infra Cleanup / Production Hardening PASS olmalı.
- 21 Security / RBAC / Audit PASS olmalı.

Plan kapsamı:
- UI page implementation plan
- UI widget surface plan
- API endpoint implementation plan
- Permission / RBAC mapping
- Tenant scope mapping
- Realtime channel mapping
- Audit requirement mapping
- Implementation sequence
- Test plan
- No-runtime-change / no-config-change / no-secret safety

Production prensipleri:
- Önce contract ve envelope sabitlenir.
- Sonra API DTO/handler/route uygulaması yapılır.
- Sonra UI page/widget bağlanır.
- Sonra realtime SSE/WebSocket bağlanır.
- En son test, RBAC, tenant isolation ve audit gate çalıştırılır.
- Tenant kullanıcıları platform/ops/security kanallarını göremez.
- UI ham payload, secret, raw log, raw event body veya stacktrace göstermez.
- API endpointleri tenant_id, permission, audit ve request_id standardı taşır.

Kapanış hedefi:
UI_API_IMPLEMENTATION_PLAN=PASS
UI_API_PREVIOUS_17_4=PASS
UI_PAGE_IMPLEMENTATION_PLAN=PASS
API_ENDPOINT_IMPLEMENTATION_PLAN=PASS
UI_API_PERMISSION_MAPPING=PASS
UI_API_SEQUENCE_PLAN=PASS
UI_API_TEST_PLAN=PASS
UI_API_NO_RUNTIME_CHANGE=PASS
UI_API_NO_CONFIG_CHANGE=PASS
UI_API_SECRET_SAFE=PASS
FAZ4B_17_5_FINAL_STATUS=PASS
