# FAZ 4B / 22.1 - Observability Baseline Policy

## Politika

Bu gate Pix2pi observability altyapısının başlangıç sinyal envanterini evidence-only şekilde çıkarır.

## Altın kurallar

- systemctl restart/start/stop/reload çalıştırılmaz.
- docker restart/start/stop/rm çalıştırılmaz.
- docker compose up/down/restart çalıştırılmaz.
- nginx reload/restart çalıştırılmaz.
- prometheus/grafana/loki/tempo config değiştirilmez.
- dashboard import/export yapılmaz.
- alert rule oluşturulmaz.
- log içeriği rapora basılmaz.
- metric body rapora basılmaz.
- trace body rapora basılmaz.
- /proc/*/environ okunmaz.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.
- Sadece metadata, status code, endpoint adı, port, servis adı ve readiness evidence yazılır.

## Baseline sinyalleri

- service_health
- container_health
- metrics_endpoint
- logs_signal
- traces_signal
- db_health
- event_bus_health
- queue_backlog
- dlq_signal
- api_gateway_health
- mission_control_health
- ops_console_health
- alert_readiness
- public_surface_observability_risk
- tenant_security_observability

## Alert readiness adayları

- service_down
- container_down
- high_public_surface_risk
- db_connection_error
- event_bus_backlog_high
- dlq_growth
- api_error_rate_high
- latency_high
- disk_usage_high
- memory_high
- cpu_high
- backup_stale
- secret_leak_attempt
- audit_gap

## Safety

SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
DASHBOARD_CHANGED=NO
ALERT_RULE_CHANGED=NO
PROMETHEUS_CONFIG_CHANGED=NO
GRAFANA_CONFIG_CHANGED=NO
LOKI_CONFIG_CHANGED=NO
TEMPO_CONFIG_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
LOG_CONTENT_PRINTED=NO
METRIC_BODY_PRINTED=NO
TRACE_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
