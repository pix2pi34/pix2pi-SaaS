# FAZ 4B / 22.6 - Ops Console Signal Contract Policy

## Politika

Bu gate Ops Console için sinyal sözleşmesini evidence-only olarak üretir.

## Altın kurallar

- UI kodu yazılmaz.
- API implementation yapılmaz.
- Route oluşturulmaz.
- DB tablo / migration oluşturulmaz.
- Prometheus / Alertmanager / Grafana / Loki / Tempo / OTEL config değiştirilmez.
- Servis/container restart edilmez.
- Docker compose up/down/restart çalıştırılmaz.
- Firewall / port / Nginx değiştirilmez.
- Metric/log/trace/query body rapora basılmaz.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.
- Sadece contract metadata, widget metadata, API endpoint taslağı, alert binding ve runbook binding evidence yazılır.

## Ops Console minimum signal envelope

Her sinyal en az şu alanları taşımalıdır:
- signal_name
- category
- status
- severity
- source
- observed_at
- tenant_scope
- summary
- evidence_ref
- runbook_ref
- owner
- refresh_interval
- visibility_scope
- implementation_status

## Status standardı

- OK
- WARN
- CRITICAL
- UNKNOWN
- NOT_CONFIGURED
- READY_FOR_IMPLEMENTATION

## Visibility standardı

- platform_admin
- security_admin
- ops_admin
- tenant_admin_limited
- read_only_observer

## Safety

SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
OPS_CONSOLE_CODE_CHANGED=NO
OPS_CONSOLE_API_IMPLEMENTED=NO
OPS_CONSOLE_UI_CHANGED=NO
PROMETHEUS_CONFIG_CHANGED=NO
ALERTMANAGER_CONFIG_CHANGED=NO
GRAFANA_DASHBOARD_CHANGED=NO
GRAFANA_ALERT_CHANGED=NO
ALERT_RULE_CHANGED=NO
LOKI_CONFIG_CHANGED=NO
TEMPO_CONFIG_CHANGED=NO
OTEL_CONFIG_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
METRIC_BODY_PRINTED=NO
LOG_CONTENT_PRINTED=NO
TRACE_BODY_PRINTED=NO
QUERY_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
