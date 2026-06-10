# FAZ 4B / 22.6 - Ops Console Signal Contract

Amaç:
Pix2pi Ops Console'un okuyacağı metrik, log, trace, alert, güvenlik, DB, event bus, backup ve public surface sinyallerini tek standart sözleşmeye bağlamak.

Bu adım:
- Ops Console UI kodu yazmaz.
- Ops Console API implementation yazmaz.
- Backend route oluşturmaz.
- DB tablo / migration oluşturmaz.
- DB apply yapmaz.
- DB mutate etmez.
- Prometheus alert rule oluşturmaz.
- Prometheus config değiştirmez.
- Alertmanager config değiştirmez.
- Grafana dashboard / alert değiştirmez.
- Loki / Tempo / OTEL config değiştirmez.
- Docker compose up/down/restart çalıştırmaz.
- Servis/container restart etmez.
- Nginx reload/restart yapmaz.
- Firewall değiştirmez.
- Port kapatmaz/açmaz.
- Config/env değiştirmez.
- Metric body rapora basmaz.
- Log body rapora basmaz.
- Trace body rapora basmaz.
- Query body rapora basmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece contract, widget, API endpoint taslağı, alert binding ve runbook binding metadata üretir.

Ön koşul:
- 22.1 Observability baseline / signal inventory PASS olmalı.
- 22.2 Metrics / scrape target readiness PASS olmalı.
- 22.3 Logs / Loki readiness PASS olmalı.
- 22.4 Traces / Tempo readiness PASS olmalı.
- 22.5 Alert rule catalog / severity matrix PASS olmalı.
- 20 Infra Cleanup / Production Hardening final closure PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Kontrol alanları:
- platform overview signal contract
- service status signal contract
- container status signal contract
- DB health signal contract
- Redis health signal contract
- Event bus / NATS health signal contract
- queue backlog signal contract
- DLQ signal contract
- API Gateway health signal contract
- metrics health signal contract
- Loki logs health signal contract
- Tempo traces health signal contract
- public surface risk signal contract
- tenant security / audit signal contract
- backup / restore drill signal contract
- alert severity binding
- runbook binding
- Ops Console widget contract
- Ops Console API contract
- no-runtime-change / no-config-change / no-secret safety

Production hedef prensibi:
- Ops Console ham log/metric/trace gövdesi değil, normalize edilmiş sinyal metadata okumalı.
- Her sinyal severity, status, source, observed_at, tenant_scope, runbook_ref ve evidence_ref taşımalı.
- Critical/High alertler Ops Console üzerinde ayrı görünmeli.
- Her alert runbook placeholder ile bağlanmalı.
- Tenant/security sinyalleri RBAC kontrollü gösterilmeli.
- Public surface riskleri production öncesi remediation queue’ya taşınmalı.
- Bu adım contract-only kalmalı; gerçek API/UI implementation 22.7 sonrası veya ayrı execution adımında yapılmalı.

Kapanış hedefi:
OPS_CONSOLE_SIGNAL_CONTRACT=PASS
OPS_PREVIOUS_22_5=PASS
OPS_SIGNAL_CONTRACT=PASS
OPS_WIDGET_CONTRACT=PASS
OPS_API_CONTRACT=PASS
OPS_ALERT_BINDING=PASS
OPS_RUNBOOK_BINDING=PASS
OPS_CONTRACT_COVERAGE=PASS
OPS_NO_RUNTIME_CHANGE=PASS
OPS_NO_CONFIG_CHANGE=PASS
OPS_BODY_NOT_PRINTED=PASS
OPS_SECRET_SAFE=PASS
FAZ4B_22_6_FINAL_STATUS=PASS
