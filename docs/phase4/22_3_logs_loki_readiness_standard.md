# FAZ 4B / 22.3 - Logs / Loki Readiness

Amaç:
Pix2pi observability katmanında log toplama, Loki readiness ve log pipeline temelini evidence-only olarak kontrol etmek.

Bu adım:
- Loki config değiştirmez.
- Loki restart/reload yapmaz.
- Promtail/agent config değiştirmez.
- Grafana dashboard değiştirmez.
- Alert rule oluşturmaz.
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
- Log body rapora basmaz.
- Journal log içeriği rapora basmaz.
- Docker logs çıktısı rapora basmaz.
- Loki query sonucu gövdesi rapora basmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece endpoint, status code, container log driver, config marker, public surface policy ve readiness metadata üretir.

Ön koşul:
- 22.1 Observability baseline / signal inventory PASS olmalı.
- 22.2 Metrics / scrape target readiness PASS olmalı.
- 20 Infra Cleanup / Production Hardening final closure PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Kontrol alanları:
- Loki /ready metadata
- Loki /metrics metadata
- Loki buildinfo metadata
- Loki labels endpoint metadata
- Docker container log driver metadata
- systemd service log source metadata
- log pipeline config marker inventory
- promtail / agent marker inventory
- public Loki / log surface policy
- secret-safe log policy
- no-restart / no-deploy / no-body-print safety

Production hedef prensibi:
- Loki public yüzeyde açık olmamalı.
- Log endpointleri auth / private network / VPN / allowlist arkasında olmalı.
- Log body, secret, token, raw DSN, query text ve stack trace içeriği rapora basılmamalı.
- Log pipeline tenant_id, service_name, environment, severity, request_id, trace_id gibi label standardına bağlanmalı.
- Log retention ve PII/secret redaction ayrı execution adımıyla uygulanmalı.
- Ops Console sadece metadata ve alarm sinyali görmeli; ham log gövdesi kontrollü erişimde kalmalı.

Kapanış hedefi:
LOGS_LOKI_READINESS=PASS
LOGS_PREVIOUS_22_2=PASS
LOGS_LOKI_ENDPOINT_PROBE=PASS
LOGS_SOURCE_INVENTORY=PASS
LOGS_PIPELINE_INVENTORY=PASS
LOGS_PUBLIC_SURFACE_POLICY=PASS
LOGS_BODY_NOT_PRINTED=PASS
LOGS_NO_RESTART=PASS
LOGS_NO_CONFIG_CHANGE=PASS
LOGS_SECRET_SAFE=PASS
FAZ4B_22_3_FINAL_STATUS=PASS
