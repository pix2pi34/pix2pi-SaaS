# FAZ 4B / 22.2 - Metrics / Scrape Target Readiness

Amaç:
Pix2pi observability katmanında metrics ve scrape target readiness durumunu evidence-only olarak kontrol etmek.

Bu adım:
- Prometheus config değiştirmez.
- Prometheus reload/restart yapmaz.
- Grafana dashboard değiştirmez.
- Alert rule oluşturmaz.
- Node Exporter / cAdvisor / NATS / API servislerini restart etmez.
- Docker compose up/down/restart çalıştırmaz.
- Nginx reload/restart yapmaz.
- Firewall değiştirmez.
- Port kapatmaz/açmaz.
- Config/env değiştirmez.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Metric body rapora basmaz.
- Prometheus query sonucu gövdesi rapora basmaz.
- Log/trace/body içeriği basmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece endpoint, status code, target, scrape readiness ve public surface policy metadata üretir.

Ön koşul:
- 22.1 Observability baseline / signal inventory PASS olmalı.
- 20 Infra Cleanup / Production Hardening final closure PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Kontrol alanları:
- Prometheus readiness
- Prometheus healthy
- Prometheus targets API metadata readiness
- Node Exporter metrics endpoint metadata
- cAdvisor health / metrics endpoint metadata
- NATS monitoring endpoint metadata
- API Gateway health scrape candidate
- Identity health scrape candidate
- Previous 22.1 endpoint evidence
- Previous 20 public metrics port risk evidence
- Public metrics surface policy
- Metrics alert readiness candidate
- no-restart / no-deploy / no-secret / no-body-print safety

Production hedef prensibi:
- Metrics endpointleri public olmamalı.
- Prometheus / Node Exporter / cAdvisor / Loki / Tempo / NATS monitoring private network, VPN, auth veya allowlist arkasında olmalı.
- Metric body rapora basılmamalı.
- Scrape target status metadata Ops Console ve alert katmanına bağlanmalı.
- Public port remediation ayrı execution adımında yapılmalı.

Kapanış hedefi:
METRICS_SCRAPE_READINESS=PASS
METRICS_PREVIOUS_22_1=PASS
METRICS_TARGET_INVENTORY=PASS
METRICS_ENDPOINT_PROBE=PASS
METRICS_PROMETHEUS_READINESS=PASS
METRICS_PUBLIC_SURFACE_POLICY=PASS
METRICS_NO_RESTART=PASS
METRICS_NO_CONFIG_CHANGE=PASS
METRICS_BODY_NOT_PRINTED=PASS
METRICS_SECRET_SAFE=PASS
FAZ4B_22_2_FINAL_STATUS=PASS
