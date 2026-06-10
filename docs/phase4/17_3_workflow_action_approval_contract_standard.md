# FAZ 4B / 17.3 - Workflow Action / Approval Contract

Amaç:
Pix2pi Workflow / Realtime UI bloğu için action, approval, permission, audit ve realtime signal sözleşmesini kurmak.

Bu adım:
- Workflow action runtime yazmaz.
- Approval runtime yazmaz.
- Workflow runtime değiştirmez.
- UI kodu yazmaz.
- API route oluşturmaz.
- Backend implementation yapmaz.
- WebSocket / SSE server başlatmaz.
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
- Sadece action catalog, approval rule catalog, permission matrix, audit/realtime binding ve safety metadata üretir.

Ön koşul:
- 17.1 Workflow / Realtime UI baseline PASS olmalı.
- 17.2 Workflow state machine contract PASS olmalı.
- FAZ 4B / 22 Observability / Ops Console final closure PASS olmalı.
- 20 Infra Cleanup / Production Hardening PASS olmalı.
- 21 Security / RBAC / Audit PASS olmalı.

Action hedefleri:
- start
- pause
- resume
- request_approval
- approve
- reject
- retry
- cancel
- complete
- fail
- assign_task
- complete_task
- notify
- archive
- external_resume
- escalate_approval

Approval hedefleri:
- tenant scoped approval
- approver role required
- cannot approve own request
- approval reason / reject reason policy
- approval timeout / escalation
- idempotency key readiness
- audit required
- realtime signal required
- state compatibility required
- permission enforcement required

Production prensipleri:
- Her action tenant scoped olmalı.
- Her mutating action audit_required=YES taşımalı.
- Approval actionları approval:write permission ister.
- System action ve user action ayrılmalı.
- Realtime UI ham payload değil normalize edilmiş action metadata görmeli.
- Reject / cancel / fail reason policy ile takip edilmeli.
- Notification binding sadece sözleşme olarak tutulmalı; bu adım notification göndermez.
- Event Bus binding sadece sözleşme olarak tutulmalı; bu adım publish/consume yapmaz.

Kapanış hedefi:
WORKFLOW_ACTION_APPROVAL_CONTRACT=PASS
WORKFLOW_ACTION_PREVIOUS_17_2=PASS
WORKFLOW_ACTION_CATALOG=PASS
WORKFLOW_APPROVAL_RULE_CATALOG=PASS
WORKFLOW_ACTION_PERMISSION_MATRIX=PASS
WORKFLOW_ACTION_AUDIT_REALTIME_BINDING=PASS
WORKFLOW_ACTION_NO_RUNTIME_CHANGE=PASS
WORKFLOW_ACTION_NO_CONFIG_CHANGE=PASS
WORKFLOW_ACTION_SECRET_SAFE=PASS
FAZ4B_17_3_FINAL_STATUS=PASS
