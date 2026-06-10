# FAZ 4B / 17.2 - Workflow State Machine Contract

Amaç:
Pix2pi Workflow / Realtime UI bloğu için workflow durum makinesi sözleşmesini kurmak.

Bu adım:
- Workflow engine runtime yazmaz.
- Workflow runtime değiştirmez.
- UI kodu yazmaz.
- API route oluşturmaz.
- Backend implementation yapmaz.
- WebSocket / SSE server başlatmaz.
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
- Sadece state catalog, transition catalog, permission matrix, invariant catalog ve safety metadata üretir.

Ön koşul:
- 17.1 Workflow / Realtime UI baseline PASS olmalı.
- FAZ 4B / 22 Observability / Ops Console final closure PASS olmalı.
- 20 Infra Cleanup / Production Hardening PASS olmalı.
- 21 Security / RBAC / Audit PASS olmalı.

Durum makinesi hedefi:
- draft
- active
- running
- paused
- waiting_approval
- waiting_external
- completed
- failed
- cancelled
- archived

Transition hedefi:
- draft -> active
- active -> running
- running -> waiting_approval
- waiting_approval -> running
- waiting_approval -> cancelled
- running -> waiting_external
- waiting_external -> running
- running -> paused
- paused -> running
- running -> completed
- running -> failed
- failed -> running
- failed -> cancelled
- completed -> archived
- cancelled -> archived

Production prensipleri:
- Her workflow tenant scoped olmalı.
- Her state transition audit event üretmeye hazır olmalı.
- Terminal state’lerden active/running state’e izinsiz dönüş olmamalı.
- Manual action ile system action ayrılmalı.
- Approval gerektiren geçişler ayrı permission ile korunmalı.
- Realtime UI ham payload değil normalize edilmiş state metadata görmeli.
- Event Bus binding sadece sözleşme olarak tutulmalı; bu adım publish/consume yapmamalı.

Kapanış hedefi:
WORKFLOW_STATE_MACHINE_CONTRACT=PASS
WORKFLOW_STATE_PREVIOUS_17_1=PASS
WORKFLOW_STATE_CATALOG=PASS
WORKFLOW_TRANSITION_CATALOG=PASS
WORKFLOW_STATE_PERMISSION_MATRIX=PASS
WORKFLOW_STATE_INVARIANT_CATALOG=PASS
WORKFLOW_STATE_NO_RUNTIME_CHANGE=PASS
WORKFLOW_STATE_NO_CONFIG_CHANGE=PASS
WORKFLOW_STATE_SECRET_SAFE=PASS
FAZ4B_17_2_FINAL_STATUS=PASS
