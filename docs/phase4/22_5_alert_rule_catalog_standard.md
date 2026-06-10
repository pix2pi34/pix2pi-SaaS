# FAZ 4B / 22.5 - Alert Rule Catalog / Severity Matrix

Amaç:
Pix2pi observability / ops console için alarm kural kataloğu, severity matrisi, sinyal eşlemesi ve escalation modelini evidence-only olarak oluşturmak.

Bu adım:
- Prometheus alert rule dosyası oluşturmaz.
- Prometheus config değiştirmez.
- Prometheus reload/restart yapmaz.
- Alertmanager config değiştirmez.
- Alertmanager reload/restart yapmaz.
- Grafana alert/dashboard değiştirmez.
- Loki / Tempo / OTEL / Promtail config değiştirmez.
- Docker compose up/down/restart çalıştırmaz.
- Servis/container restart etmez.
- Nginx reload/restart yapmaz.
- Firewall değiştirmez.
- Port kapatmaz/açmaz.
- Config/env değiştirmez.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Metric body rapora basmaz.
- Log body rapora basmaz.
- Trace body rapora basmaz.
- Prometheus query body rapora basmaz.
- Loki / Tempo query body rapora basmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece alert adı, sinyal kaynağı, severity, kanal, escalation, owner, runbook placeholder ve readiness metadata üretir.

Ön koşul:
- 22.1 Observability baseline / signal inventory PASS olmalı.
- 22.2 Metrics / scrape target readiness PASS olmalı.
- 22.3 Logs / Loki readiness PASS olmalı.
- 22.4 Traces / Tempo readiness PASS olmalı.
- 20 Infra Cleanup / Production Hardening final closure PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Kontrol alanları:
- service_down alert catalog
- container_down alert catalog
- prometheus_target_down alert catalog
- loki_not_ready alert catalog
- tempo_not_ready alert catalog
- otel_unreachable alert catalog
- public_surface_risk alert catalog
- db_connection_error alert catalog
- event_bus_backlog_high alert catalog
- dlq_growth alert catalog
- api_error_rate_high alert catalog
- latency_high alert catalog
- disk_usage_high alert catalog
- memory_high alert catalog
- cpu_high alert catalog
- backup_stale alert catalog
- secret_leak_attempt alert catalog
- audit_gap alert catalog
- severity matrix
- escalation matrix
- no-config-change / no-restart / no-secret safety

Production hedef prensibi:
- Alert rule önce kataloglanır, sonra ayrı execution adımında Prometheus/Alertmanager/Grafana tarafına uygulanır.
- Critical alertler Ops Console + SMS/telefon/mesajlaşma kanalına bağlanır.
- High alertler Ops Console + mesajlaşma/email kanalına bağlanır.
- Medium alertler Ops Console + daily/periodic review kanalına bağlanır.
- Low alertler dashboard/evidence seviyesinde kalır.
- Alarm gürültüsü üretmemek için threshold, for duration, dedupe ve suppression ayrı uygulama adımında netleştirilir.
- Her alert runbook placeholder’a sahip olmalıdır.

Kapanış hedefi:
ALERT_RULE_CATALOG=PASS
ALERT_PREVIOUS_22_4=PASS
ALERT_RULE_INVENTORY=PASS
ALERT_SEVERITY_MATRIX=PASS
ALERT_SIGNAL_MAPPING=PASS
ALERT_ESCALATION_MATRIX=PASS
ALERT_RUNBOOK_PLACEHOLDER=PASS
ALERT_NO_CONFIG_CHANGE=PASS
ALERT_NO_RESTART=PASS
ALERT_BODY_NOT_PRINTED=PASS
ALERT_SECRET_SAFE=PASS
FAZ4B_22_5_FINAL_STATUS=PASS
