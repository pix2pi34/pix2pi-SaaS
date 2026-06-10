# FAZ 4B / 17.1 - Workflow / Realtime UI Baseline Policy

## Politika

Bu gate workflow ve realtime UI için sadece contract / inventory üretir.

## Altın kurallar

- UI kodu yazılmaz.
- API implementation yapılmaz.
- Route oluşturulmaz.
- WebSocket / SSE server başlatılmaz.
- Workflow runtime değiştirilmez.
- DB tablo / migration oluşturulmaz.
- DB mutate edilmez.
- Event publish/consume yapılmaz.
- Servis/container restart edilmez.
- Docker compose up/down/restart çalıştırılmaz.
- Firewall / port / Nginx değiştirilmez.
- Config/env değiştirilmez.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.

## Workflow minimum domain modeli

- workflow_definition
- workflow_instance
- workflow_step
- workflow_transition
- workflow_action
- approval_request
- task_assignment
- job_trigger
- notification_binding
- audit_binding
- realtime_binding
- tenant_visibility
- rbac_visibility

## Realtime minimum signal envelope

- signal_name
- channel
- category
- tenant_scope
- actor_scope
- severity
- source
- event_ref
- request_id
- payload_policy
- visibility_scope
- implementation_status

## UI surface minimum contract

- page_name
- widget_name
- action_name
- data_source
- realtime_channel
- required_permission
- tenant_scope
- audit_required
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
WORKFLOW_RUNTIME_CHANGED=NO
EVENT_PUBLISHED=NO
EVENT_CONSUMED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
TOKEN_PRINTED=NO
