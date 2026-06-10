# FAZ 4B / 22.5 - Alert Rule Catalog Policy

## Politika

Bu gate alert kural kataloğunu ve severity/escalation matrisini evidence-only şekilde üretir.

## Altın kurallar

- Alert rule dosyası aktif sisteme yazılmaz.
- Prometheus config değiştirilmez.
- Prometheus reload/restart yapılmaz.
- Alertmanager config değiştirilmez.
- Alertmanager reload/restart yapılmaz.
- Grafana dashboard/alert değiştirilmez.
- Servis/container restart edilmez.
- Docker compose up/down/restart çalıştırılmaz.
- Firewall / port / Nginx değiştirilmez.
- Metric/log/trace/query body rapora basılmaz.
- Secret, raw DSN, token, private key veya password değeri rapora basılmaz.
- Sadece alert metadata, signal mapping, severity ve escalation evidence yazılır.

## Severity standardı

CRITICAL:
- Canlı sistemi durdurur.
- Veri kaybı / güvenlik ihlali / ödeme / DB / event bus kritik etkisi vardır.
- Hemen müdahale ister.

HIGH:
- Kısa sürede kullanıcı etkisine dönüşebilir.
- Backlog, DLQ, error-rate, public surface, restore/backup riski gibi konuları kapsar.

MEDIUM:
- Performans düşüşü, kapasite baskısı, readiness dalgalanması gibi izlenmesi gereken alandır.

LOW:
- Bilgilendirme / hygiene / tuning / evidence uyarısıdır.

## Alert contract

Her alert şunları içermelidir:
- alert_name
- category
- signal_source
- severity
- condition_hint
- threshold_hint
- duration_hint
- owner
- channel
- escalation_level
- runbook_placeholder
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
PROMETHEUS_CONFIG_CHANGED=NO
PROMETHEUS_RELOAD_EXECUTED=NO
PROMETHEUS_RESTARTED=NO
ALERTMANAGER_CONFIG_CHANGED=NO
ALERTMANAGER_RELOAD_EXECUTED=NO
ALERTMANAGER_RESTARTED=NO
GRAFANA_DASHBOARD_CHANGED=NO
GRAFANA_ALERT_CHANGED=NO
ALERT_RULE_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
METRIC_BODY_PRINTED=NO
LOG_CONTENT_PRINTED=NO
TRACE_BODY_PRINTED=NO
PROMETHEUS_QUERY_BODY_PRINTED=NO
LOKI_QUERY_BODY_PRINTED=NO
TEMPO_QUERY_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
