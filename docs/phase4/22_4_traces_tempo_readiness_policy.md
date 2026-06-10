# FAZ 4B / 22.4 - Traces / Tempo Readiness Policy

## Politika

Bu gate Pix2pi traces / Tempo / OTEL altyapısının readiness durumunu evidence-only şekilde çıkarır.

## Altın kurallar

- Tempo config değiştirilmez.
- Tempo reload/restart yapılmaz.
- OTEL collector config değiştirilmez.
- OTEL collector reload/restart yapılmaz.
- Docker compose up/down/restart çalıştırılmaz.
- Servis/container restart edilmez.
- Firewall / port / Nginx değiştirilmez.
- Tempo query body rapora basılmaz.
- Trace body rapora basılmaz.
- OTEL payload rapora basılmaz.
- Span attribute içeriği rapora basılmaz.
- Metric body rapora basılmaz.
- Log body rapora basılmaz.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.
- Sadece endpoint adı, host, port, path, status code, TCP reachability, config marker ve risk metadata yazılır.

## Trace hedefleri

- Tempo readiness
- Tempo metrics metadata
- Tempo search/status metadata
- OTEL HTTP 4318 readiness metadata
- OTEL gRPC 4317 TCP metadata
- Grafana Tempo datasource readiness placeholder
- service trace marker inventory
- request_id / trace_id / correlation_id marker inventory
- tenant trace isolation marker inventory
- public trace surface policy
- trace signal contract

## Public surface policy

Public olmaması gereken trace yüzeyleri:
- Tempo 3200
- OTEL gRPC 4317
- OTEL HTTP 4318
- Grafana trace explore surface
- Pix2pi internal trace/debug endpoints
- Any raw trace endpoint

## Trace signal standardı

Minimum hedef field / label seti:
- trace_id
- span_id
- parent_span_id
- request_id
- correlation_id
- tenant_id / tenant_uuid
- service_name
- component
- route
- method
- status_code
- error_code
- event_type

## Safety

SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
TEMPO_CONFIG_CHANGED=NO
TEMPO_RELOAD_EXECUTED=NO
TEMPO_RESTARTED=NO
OTEL_CONFIG_CHANGED=NO
OTEL_RELOAD_EXECUTED=NO
OTEL_RESTARTED=NO
GRAFANA_DASHBOARD_CHANGED=NO
ALERT_RULE_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
TRACE_BODY_PRINTED=NO
TEMPO_QUERY_BODY_PRINTED=NO
OTEL_PAYLOAD_PRINTED=NO
SPAN_ATTRIBUTE_PRINTED=NO
METRIC_BODY_PRINTED=NO
LOG_CONTENT_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
