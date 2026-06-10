# FAZ 4B / 17.5 - UI Surface + API Implementation Plan Policy

## Politika

Bu gate sadece UI/API implementation plan üretir. Gerçek kodlama sonraki execution adımlarında yapılır.

## Altın kurallar

- UI kodu yazılmaz.
- API route oluşturulmaz.
- Backend implementation yapılmaz.
- DTO / handler / middleware kodu yazılmaz.
- WebSocket / SSE server başlatılmaz.
- DB tablo / migration oluşturulmaz.
- DB mutate edilmez.
- Event publish/consume yapılmaz.
- Notification gönderilmez.
- Servis/container restart edilmez.
- Docker compose up/down/restart çalıştırılmaz.
- Firewall / port / Nginx değiştirilmez.
- Config/env değiştirilmez.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.

## UI page plan minimum alanları

- page_name
- route_candidate
- category
- widgets
- data_source
- realtime_channel
- required_permission
- tenant_scope
- audit_required
- implementation_order
- implementation_status

## API endpoint plan minimum alanları

- method
- path
- category
- handler_candidate
- request_contract
- response_contract
- required_permission
- tenant_scope
- audit_required
- realtime_binding
- implementation_order
- implementation_status

## Test plan minimum alanları

- test_name
- category
- target
- expected_result
- tenant_check
- rbac_check
- audit_check
- realtime_check
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
FRONTEND_FILE_CREATED=NO
API_ROUTE_CREATED=NO
API_IMPLEMENTATION_CHANGED=NO
DTO_CODE_CREATED=NO
HANDLER_CODE_CREATED=NO
MIDDLEWARE_CHANGED=NO
WEBSOCKET_SERVER_STARTED=NO
SSE_SERVER_STARTED=NO
REALTIME_RUNTIME_CHANGED=NO
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
