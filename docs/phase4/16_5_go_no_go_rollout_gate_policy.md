# FAZ 4B / 16.5 - Go / No-Go Rollout Policy

## Politika

Bu gate sadece Go / No-Go rollout karar sözleşmesi üretir. Gerçek canlıya alma yapmaz.

## Altın kurallar

- Gerçek rollout çalıştırılmaz.
- Canlı trafik değiştirilmez.
- Tenant live moda alınmaz.
- Gerçek müşteri bildirimi gönderilmez.
- Gerçek veri oluşturulmaz.
- Gerçek UAT çalıştırılmaz.
- DB mutate edilmez.
- Config/env değiştirilmez.
- Kod yazılmaz.
- UI dosyası oluşturulmaz.
- API route oluşturulmaz.
- Event publish/consume yapılmaz.
- Notification gönderilmez.
- Servis/container restart edilmez.
- Docker compose up/down/restart çalıştırılmaz.
- Firewall / port / Nginx değiştirilmez.
- Secret, raw DSN, token, private key, password veya müşteri hassas verisi rapora basılmaz.

## Decision matrix minimum alanları

- gate_name
- category
- priority
- required_status
- blocker_if_failed
- decision_if_failed
- evidence_source
- owner_role
- implementation_status

## Blocker policy minimum alanları

- blocker_code
- priority
- failure_area
- rollout_decision
- escalation_owner
- required_action
- can_continue_with_workaround
- implementation_status

## Security / tenant gate minimum alanları

- gate_name
- security_area
- required_status
- blocker_if_failed
- evidence_source
- owner_role
- implementation_status

## Business chain gate minimum alanları

- chain_name
- business_area
- required_status
- blocker_if_failed
- evidence_source
- owner_role
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
ROLLOUT_EXECUTED=NO
GO_LIVE_SWITCHED=NO
PRODUCTION_TRAFFIC_CHANGED=NO
TENANT_ENABLED_FOR_LIVE=NO
REAL_CUSTOMER_NOTIFIED=NO
UAT_EXECUTED=NO
SAMPLE_DATA_INSERTED=NO
REAL_CUSTOMER_DATA_CREATED=NO
REAL_PRODUCT_CREATED=NO
REAL_STOCK_MUTATED=NO
REAL_SALE_CREATED=NO
REAL_ACCOUNTING_ENTRY_CREATED=NO
DATA_IMPORT_EXECUTED=NO
FILE_EXPORT_EXECUTED=NO
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
