# FAZ 4B / 17.2 - Workflow State Machine Contract Policy

## Politika

Bu gate workflow state machine için sadece contract / inventory üretir.

## Altın kurallar

- Runtime kodu yazılmaz.
- UI kodu yazılmaz.
- API route oluşturulmaz.
- DB tablo / migration oluşturulmaz.
- DB mutate edilmez.
- Event publish/consume yapılmaz.
- Servis/container restart edilmez.
- Docker compose up/down/restart çalıştırılmaz.
- Firewall / port / Nginx değiştirilmez.
- Config/env değiştirilmez.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.

## State contract minimum alanları

- state_name
- state_category
- is_initial
- is_terminal
- allowed_actor
- audit_required
- realtime_signal
- tenant_scope
- implementation_status

## Transition contract minimum alanları

- transition_name
- from_state
- to_state
- trigger_type
- required_permission
- approval_required
- audit_required
- realtime_signal
- event_binding
- allowed_actor
- implementation_status

## Invariant kuralları

- initial state sadece draft olabilir.
- completed / cancelled / archived terminal state olarak korunmalı.
- archived dışına geçiş olmamalı.
- tenant_id her transition context içinde zorunlu olmalı.
- audit_required YES olan transition audit kaydı üretmeye hazır olmalı.
- approval_required YES olan transition approval permission ister.
- failed state retry veya cancel akışına izin verir.
- secret / raw payload / stacktrace UI signal içine taşınmaz.

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
WORKFLOW_ENGINE_CODE_CHANGED=NO
STATE_MACHINE_RUNTIME_CREATED=NO
EVENT_PUBLISHED=NO
EVENT_CONSUMED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
TOKEN_PRINTED=NO
