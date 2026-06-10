# FAZ 4B / 22.3 - Logs / Loki Readiness Policy

## Politika

Bu gate Pix2pi logs / Loki altyapısının readiness durumunu evidence-only şekilde çıkarır.

## Altın kurallar

- Loki config değiştirilmez.
- Loki reload/restart yapılmaz.
- Promtail/agent config değiştirilmez.
- Docker compose up/down/restart çalıştırılmaz.
- Servis/container restart edilmez.
- Firewall / port / Nginx değiştirilmez.
- Docker logs okunmaz.
- journalctl log body okunmaz.
- Loki query body rapora basılmaz.
- Log gövdesi rapora basılmaz.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.
- Sadece endpoint adı, host, port, path, status code, reachable, config marker, log driver ve risk metadata yazılır.

## Logs hedefleri

- Loki readiness
- Loki metrics metadata
- Loki buildinfo metadata
- Loki labels metadata
- Docker container log driver metadata
- systemd service log source metadata
- promtail / agent marker evidence
- log pipeline marker evidence
- log label readiness
- secret redaction readiness placeholder
- tenant log isolation placeholder

## Public surface policy

Public olmaması gereken log yüzeyleri:
- Loki 3100
- Promtail 9080
- OTEL collector 4317 / 4318
- Grafana log explore surface
- Pix2pi internal service log endpoints
- Any raw log endpoint

## Log label standardı

Minimum hedef label seti:
- environment
- tenant_id / tenant_uuid
- service_name
- component
- severity
- request_id
- trace_id
- event_type
- error_code

## Safety

SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
LOKI_CONFIG_CHANGED=NO
LOKI_RELOAD_EXECUTED=NO
LOKI_RESTARTED=NO
PROMTAIL_CONFIG_CHANGED=NO
LOG_AGENT_CONFIG_CHANGED=NO
GRAFANA_DASHBOARD_CHANGED=NO
ALERT_RULE_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
LOG_CONTENT_PRINTED=NO
LOKI_QUERY_BODY_PRINTED=NO
JOURNAL_LOG_BODY_PRINTED=NO
DOCKER_LOG_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
