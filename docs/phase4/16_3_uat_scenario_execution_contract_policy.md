# FAZ 4B / 16.3 - UAT Scenario Execution Policy

## Politika

Bu gate sadece UAT scenario execution contract üretir. Gerçek test çalıştırma sonraki adımlarda yapılır.

## Altın kurallar

- Gerçek UAT çalıştırılmaz.
- Gerçek satış/stok/muhasebe işlemi yapılmaz.
- Gerçek tenant oluşturulmaz.
- Gerçek kullanıcı oluşturulmaz.
- Kod yazılmaz.
- UI dosyası oluşturulmaz.
- API route oluşturulmaz.
- DB migration oluşturulmaz.
- DB mutate edilmez.
- Event publish/consume yapılmaz.
- Notification gönderilmez.
- Servis/container restart edilmez.
- Docker compose up/down/restart çalıştırılmaz.
- Firewall / port / Nginx değiştirilmez.
- Config/env değiştirilmez.
- Secret, raw DSN, token, private key, password veya müşteri hassas verisi rapora basılmaz.

## Execution plan minimum alanları

- scenario_name
- module
- priority
- actor_role
- precondition
- execution_steps
- expected_evidence
- acceptance_criteria
- blocker_if_failed
- audit_required
- tenant_check_required
- rbac_check_required
- implementation_status

## Actor matrix minimum alanları

- actor_role
- scenario_count
- p0_count
- allowed_scope
- forbidden_scope
- evidence_owner
- implementation_status

## Evidence matrix minimum alanları

- evidence_name
- scenario_ref
- evidence_type
- required_for_go_live
- owner_role
- acceptance_format
- blocker_if_missing
- implementation_status

## Blocker policy minimum alanları

- priority
- failure_type
- rollout_decision
- escalation_owner
- required_action
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
TENANT_CREATED=NO
USER_CREATED=NO
PASSWORD_CREATED=NO
TOKEN_CREATED=NO
UAT_EXECUTED=NO
REAL_SALE_CREATED=NO
REAL_STOCK_MUTATED=NO
REAL_ACCOUNTING_ENTRY_CREATED=NO
UI_CODE_CHANGED=NO
API_ROUTE_CREATED=NO
API_IMPLEMENTATION_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
EVENT_PUBLISHED=NO
EVENT_CONSUMED=NO
NOTIFICATION_SENT=NO
CUSTOMER_PRIVATE_DATA_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
TOKEN_PRINTED=NO
