# FAZ 4B / 16.1 - Pilot / UAT / Onboarding Policy

## Politika

Bu gate sadece pilot / UAT / onboarding başlangıç sözleşmesi üretir.

## Altın kurallar

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

## Pilot minimum alanları

- pilot_area
- owner_role
- tenant_scope
- readiness_target
- acceptance_signal
- risk_level
- implementation_status

## UAT minimum alanları

- scenario_name
- module
- actor
- precondition
- action_flow
- expected_result
- acceptance_criteria
- priority
- implementation_status

## Onboarding minimum alanları

- checklist_item
- owner_role
- required_before_go_live
- evidence_required
- risk_if_missing
- implementation_status

## Rollout gate minimum alanları

- gate_name
- category
- required_status
- blocker_if_failed
- evidence_source
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
