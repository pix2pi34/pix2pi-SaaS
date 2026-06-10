# FAZ 4B / 16.2 - Pilot Tenant Readiness Policy

## Politika

Bu gate sadece pilot tenant readiness / role / onboarding contract üretir.

## Altın kurallar

- Gerçek tenant oluşturulmaz.
- Gerçek kullanıcı oluşturulmaz.
- Şifre/token üretilmez.
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

## Readiness minimum alanları

- readiness_item
- category
- owner_role
- tenant_scope
- required_before_uat
- required_before_go_live
- acceptance_signal
- risk_level
- implementation_status

## Role matrix minimum alanları

- role_name
- actor_type
- allowed_modules
- forbidden_modules
- required_permissions
- tenant_scope
- audit_required
- onboarding_required
- implementation_status

## Evidence minimum alanları

- evidence_name
- category
- owner_role
- required_for_uat
- required_for_go_live
- acceptance_format
- blocker_if_missing
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
