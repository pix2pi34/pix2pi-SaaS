# FAZ 4B / 17.3 - Workflow Action / Approval Contract Policy

## Politika

Bu gate workflow action ve approval için sadece contract / inventory üretir.

## Altın kurallar

- Runtime kodu yazılmaz.
- Approval engine yazılmaz.
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

## Action contract minimum alanları

- action_name
- action_category
- from_state
- to_state
- actor_type
- required_permission
- approval_required
- reason_required
- idempotency_required
- audit_required
- realtime_signal
- event_binding
- notification_binding
- tenant_scope
- implementation_status

## Approval rule contract minimum alanları

- rule_name
- category
- severity
- condition_hint
- enforcement_hint
- required_permission
- audit_required
- realtime_signal
- implementation_status

## Invariant kuralları

- approve / reject sadece waiting_approval state üzerinde çalışmalı.
- reject reason_required=YES olmalı.
- cancel reason_required=YES olmalı.
- retry sadece failed state üzerinde çalışmalı.
- archive sadece terminal state üzerinde çalışmalı.
- her mutating action audit_required=YES olmalı.
- her action tenant_scope=tenant_scoped veya platform_scoped olmalı.
- her action event_binding placeholder taşımalı.
- approval actionları approval permission ister.
- idempotency key readiness action sözleşmesinde görünmelidir.

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
APPROVAL_RUNTIME_CHANGED=NO
ACTION_RUNTIME_CREATED=NO
EVENT_PUBLISHED=NO
EVENT_CONSUMED=NO
NOTIFICATION_SENT=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
TOKEN_PRINTED=NO
