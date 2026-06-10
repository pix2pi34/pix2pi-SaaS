# FAZ 4B / 17.6 - Workflow / Realtime Tests

Amaç:
FAZ 4B / 17 altında 17.1-17.5 arasında üretilen workflow, state machine, action/approval, realtime channel ve UI/API implementation plan artifact'larını tek test gate altında doğrulamak.

Bu adım:
- UI kodu yazmaz.
- Frontend dosyası oluşturmaz.
- API route oluşturmaz.
- Backend implementation yapmaz.
- DTO / handler / middleware kodu yazmaz.
- Workflow runtime değiştirmez.
- Approval runtime değiştirmez.
- Realtime runtime değiştirmez.
- WebSocket server başlatmaz.
- SSE server başlatmaz.
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
- Secret değeri, raw DSN, token, password, raw payload veya query text rapora basmaz.

Kapsam:
- 17.1 Workflow / Realtime UI baseline / surface inventory
- 17.2 Workflow state machine contract
- 17.3 Workflow action / approval contract
- 17.4 Realtime channel contract
- 17.5 UI surface + API implementation plan

Test hedefleri:
- 17.1-17.5 final status değerleri PASS olmalı.
- 17.1-17.5 domain gate değerleri PASS olmalı.
- Artifact coverage eksiksiz olmalı.
- Tenant scope / RBAC / audit / realtime / idempotency evidence korunmalı.
- No-runtime-change / no-config-change / no-secret safety korunmalı.
- 17.7 final closure öncesi tek birleşik test raporu üretilmeli.

Kapanış hedefi:
WORKFLOW_REALTIME_TESTS=PASS
WORKFLOW_TEST_BASELINE=PASS
WORKFLOW_TEST_STATE_MACHINE=PASS
WORKFLOW_TEST_ACTION_APPROVAL=PASS
WORKFLOW_TEST_REALTIME_CHANNEL=PASS
WORKFLOW_TEST_UI_API_PLAN=PASS
WORKFLOW_TEST_ARTIFACT_COVERAGE=PASS
WORKFLOW_TEST_NO_RUNTIME_CHANGE=PASS
WORKFLOW_TEST_NO_CONFIG_CHANGE=PASS
WORKFLOW_TEST_SECRET_SAFE=PASS
FAZ4B_17_6_FINAL_STATUS=PASS
