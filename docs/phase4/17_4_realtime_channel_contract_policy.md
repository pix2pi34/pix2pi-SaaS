# FAZ 4B / 17.4 - Realtime Channel Contract Policy

## Politika

Bu gate realtime SSE/WebSocket kanalları için sadece contract / inventory üretir.

## Altın kurallar

- Realtime runtime kodu yazılmaz.
- WebSocket server başlatılmaz.
- SSE server başlatılmaz.
- UI kodu yazılmaz.
- API route oluşturulmaz.
- DB tablo / migration oluşturulmaz.
- DB mutate edilmez.
- Event publish/consume yapılmaz.
- Notification gönderilmez.
- Servis/container restart edilmez.
- Docker compose up/down/restart çalıştırılmaz.
- Firewall / port / Nginx değiştirilmez.
- Config/env değiştirilmez.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.

## Channel contract minimum alanları

- channel_name
- transport
- category
- tenant_scope
- visibility_scope
- required_permission
- auth_required
- payload_policy
- rate_limit_policy
- replay_policy
- audit_required
- implementation_status

## Payload envelope minimum alanları

- envelope_field
- requirement
- field_type
- sensitivity
- source
- note

## Delivery policy minimum alanları

- delivery_name
- transport
- ordering_policy
- ack_policy
- dedupe_policy
- retry_policy
- retention_policy
- implementation_status

## Reconnect / heartbeat minimum alanları

- transport
- heartbeat_interval
- client_timeout
- reconnect_policy
- backoff_policy
- max_connections_policy
- implementation_status

## Safety

SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
UI_CODE_CHANGED=NO
API_ROUTE_CREATED=NO
API_IMPLEMENTATION_CHANGED=NO
WEBSOCKET_SERVER_STARTED=NO
SSE_SERVER_STARTED=NO
REALTIME_RUNTIME_CHANGED=NO
REALTIME_SERVER_STARTED=NO
WORKFLOW_RUNTIME_CHANGED=NO
APPROVAL_RUNTIME_CHANGED=NO
EVENT_PUBLISHED=NO
EVENT_CONSUMED=NO
NOTIFICATION_SENT=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
RAW_PAYLOAD_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
TOKEN_PRINTED=NO
