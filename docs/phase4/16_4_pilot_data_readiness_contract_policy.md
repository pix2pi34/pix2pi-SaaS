# FAZ 4B / 16.4 - Pilot Data Readiness Policy

## Politika

Bu gate sadece pilot sample dataset contract üretir. Gerçek veri oluşturma / import / DB write yapmaz.

## Altın kurallar

- Gerçek veri eklenmez.
- Gerçek müşteri bilgisi kullanılmaz.
- Gerçek vergi no / telefon / email rapora basılmaz.
- Gerçek ürün / stok / cari / satış / kasa / muhasebe kaydı oluşturulmaz.
- Data import çalıştırılmaz.
- File export çalıştırılmaz.
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

## Product dataset minimum alanları

- product_code
- category
- unit
- barcode_policy
- vat_rate
- stock_tracking
- price_policy
- uat_scenario_ref
- acceptance_signal
- implementation_status

## Stock dataset minimum alanları

- stock_case
- product_ref
- warehouse_ref
- movement_type
- quantity_policy
- expected_balance_policy
- uat_scenario_ref
- blocker_if_failed
- implementation_status

## Party dataset minimum alanları

- party_code
- party_type
- required_fields
- sensitive_data_policy
- tax_field_policy
- uat_scenario_ref
- acceptance_signal
- implementation_status

## Sales / accounting dataset minimum alanları

- flow_code
- flow_type
- payment_type
- stock_effect
- accounting_effect
- expected_tdhp_lines
- uat_scenario_ref
- blocker_if_failed
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
