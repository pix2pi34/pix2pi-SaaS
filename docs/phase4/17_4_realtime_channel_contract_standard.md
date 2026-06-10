# FAZ 4B / 17.4 - Realtime Channel Contract

Amaç:
Pix2pi Workflow / Realtime UI bloğu için SSE/WebSocket kanal sözleşmesini kurmak.

Bu adım:
- Realtime runtime yazmaz.
- WebSocket server başlatmaz.
- SSE server başlatmaz.
- UI kodu yazmaz.
- API route oluşturmaz.
- Backend implementation yapmaz.
- Workflow runtime değiştirmez.
- Approval runtime değiştirmez.
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
- Sadece realtime channel catalog, payload envelope, delivery policy, RBAC/tenant matrix, reconnect/heartbeat policy ve safety metadata üretir.

Ön koşul:
- 17.1 Workflow / Realtime UI baseline PASS olmalı.
- 17.2 Workflow state machine contract PASS olmalı.
- 17.3 Workflow action / approval contract PASS olmalı.
- FAZ 4B / 22 Observability / Ops Console final closure PASS olmalı.
- 20 Infra Cleanup / Production Hardening PASS olmalı.
- 21 Security / RBAC / Audit PASS olmalı.

Kanal hedefleri:
- tenant.workflow.events
- tenant.approval.events
- tenant.task.events
- tenant.notification.events
- tenant.audit.events
- tenant.workflow.timeline
- tenant.workflow.health
- ops.workflow.events
- ops.workflow.backlog
- ops.workflow.dlq
- security.workflow.events
- security.tenant_isolation.events
- platform.realtime.health

Production prensipleri:
- Tenant kanalları tenant_id / tenant_uuid ile izole edilmelidir.
- Platform / ops / security kanalları tenant kullanıcılarına açık olmamalıdır.
- Payload metadata-only olmalıdır.
- Secret, raw DSN, token, stacktrace, raw log, raw event body ve kişisel hassas veri payload içine taşınmamalıdır.
- Event envelope request_id, event_id, trace_id, actor_id, tenant_id, severity ve occurred_at taşımalıdır.
- Reconnect / heartbeat / backoff sözleşmesi olmalıdır.
- Her kanal RBAC permission ile korunmalıdır.
- Rate-limit ve connection-limit sözleşmesi olmalıdır.
- Bu adım sadece contract üretir; gerçek SSE/WS implementation sonraki adımlarda yapılır.

Kapanış hedefi:
REALTIME_CHANNEL_CONTRACT=PASS
REALTIME_PREVIOUS_17_3=PASS
REALTIME_CHANNEL_CATALOG=PASS
REALTIME_PAYLOAD_ENVELOPE=PASS
REALTIME_DELIVERY_POLICY=PASS
REALTIME_RBAC_TENANT_MATRIX=PASS
REALTIME_RECONNECT_HEARTBEAT_POLICY=PASS
REALTIME_NO_RUNTIME_CHANGE=PASS
REALTIME_NO_CONFIG_CHANGE=PASS
REALTIME_SECRET_SAFE=PASS
FAZ4B_17_4_FINAL_STATUS=PASS
