# FAZ 4B / 22.7 - Observability / Ops Console Tests

Amaç:
FAZ 4B / 22 altında 22.1-22.6 arasında üretilen observability, metrics, logs, traces, alert catalog ve Ops Console contract artifact'larını tek test gate altında doğrulamak.

Bu adım:
- Servis restart etmez.
- Container restart etmez.
- Docker compose up/down/restart çalıştırmaz.
- Nginx reload/restart yapmaz.
- Firewall değiştirmez.
- Port kapatmaz/açmaz.
- Config/env değiştirmez.
- Prometheus config değiştirmez.
- Prometheus reload/restart yapmaz.
- Alertmanager config değiştirmez.
- Grafana dashboard/alert değiştirmez.
- Loki / Tempo / OTEL config değiştirmez.
- Ops Console UI/API implementation yazmaz.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Metric body rapora basmaz.
- Log body rapora basmaz.
- Trace body rapora basmaz.
- Query body rapora basmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.

Kapsam:
- 22.1 Observability baseline / signal inventory
- 22.2 Metrics / scrape target readiness
- 22.3 Logs / Loki readiness
- 22.4 Traces / Tempo readiness
- 22.5 Alert rule catalog / severity matrix
- 22.6 Ops Console signal contract

Test hedefleri:
- 22.1-22.6 final status değerleri PASS olmalı.
- 22.1-22.6 domain gate değerleri PASS olmalı.
- Artifact coverage eksiksiz olmalı.
- No-runtime-change / no-config-change / no-secret safety korunmalı.
- Metrics, logs, traces, alerts ve Ops Console contract sayıları kaybolmamalı.
- 22.8 final closure öncesi tek birleşik test raporu üretilmeli.

Kapanış hedefi:
OBS_OPS_TESTS=PASS
OBS_TEST_BASELINE=PASS
OBS_TEST_METRICS=PASS
OBS_TEST_LOGS=PASS
OBS_TEST_TRACES=PASS
OBS_TEST_ALERTS=PASS
OBS_TEST_OPS_CONSOLE=PASS
OBS_TEST_ARTIFACT_COVERAGE=PASS
OBS_TEST_NO_RUNTIME_CHANGE=PASS
OBS_TEST_NO_CONFIG_CHANGE=PASS
OBS_TEST_BODY_NOT_PRINTED=PASS
OBS_TEST_SECRET_SAFE=PASS
FAZ4B_22_7_FINAL_STATUS=PASS
