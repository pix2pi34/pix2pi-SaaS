# FAZ 4B / 22.2 - Metrics / Scrape Target Readiness Policy

## Politika

Bu gate Pix2pi metrics altyapısının scrape target readiness durumunu evidence-only şekilde çıkarır.

## Altın kurallar

- Prometheus config değiştirilmez.
- Prometheus reload/restart yapılmaz.
- Grafana dashboard değiştirilmez.
- Alert rule oluşturulmaz.
- Docker compose up/down/restart çalıştırılmaz.
- Servis/container restart edilmez.
- Firewall / port / Nginx değiştirilmez.
- Metric body rapora basılmaz.
- Prometheus API response body rapora basılmaz.
- Log/trace/body içeriği rapora basılmaz.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.
- Sadece endpoint adı, host, port, path, status code, reachable, readiness ve risk metadata yazılır.

## Metrics hedefleri

- Prometheus readiness / healthy
- Prometheus scrape targets metadata
- Node Exporter metrics readiness
- cAdvisor health / metrics readiness
- NATS monitoring metadata
- API Gateway health scrape candidate
- Identity health scrape candidate
- Docker container metrics candidate
- Host metrics candidate
- DB metrics candidate placeholder
- Event bus metrics candidate placeholder

## Public surface policy

Public olmaması gereken metrics yüzeyleri:
- Prometheus 9090
- Node Exporter 9100 / 9101
- cAdvisor 8080
- Grafana 3000 / 3001
- Loki 3100
- Tempo 3200
- OTEL 4317 / 4318
- NATS monitoring 8222
- DB/cache/event bus internal ports
- Pix2pi internal service health / metrics endpoints

## Safety

SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
PROMETHEUS_CONFIG_CHANGED=NO
PROMETHEUS_RELOAD_EXECUTED=NO
PROMETHEUS_RESTARTED=NO
GRAFANA_DASHBOARD_CHANGED=NO
ALERT_RULE_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
METRIC_BODY_PRINTED=NO
PROMETHEUS_QUERY_BODY_PRINTED=NO
LOG_CONTENT_PRINTED=NO
TRACE_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
