# FAZ 4B / 22.1 - Observability Baseline / Signal Inventory

Amaç:
Pilot / production öncesi Pix2pi platformunun gözlemlenebilirlik temelini evidence-only olarak çıkarmak.

Bu adım:
- Servis restart etmez.
- Container restart etmez.
- Docker compose up/down/restart çalıştırmaz.
- Nginx reload/restart yapmaz.
- Firewall değiştirmez.
- Config/env değiştirmez.
- Dosya chmod/chown değiştirmez.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Prometheus config değiştirmez.
- Grafana dashboard değiştirmez.
- Loki/Tempo config değiştirmez.
- Alert rule oluşturmaz.
- Log içeriği basmaz.
- Metric body basmaz.
- Trace body basmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece servis, endpoint, port, container, sinyal ve alert-readiness metadata evidence üretir.

Ön koşul:
- FAZ 4B / 20 Infra Cleanup / Production Hardening final closure PASS olmalı.
- FAZ 4B / 21 Security / RBAC / Audit final closure PASS olmalı.

Kontrol alanları:
- Prometheus readiness
- Grafana health
- Loki readiness
- Tempo readiness
- Node Exporter metrics endpoint
- cAdvisor health / metrics endpoint
- Docker container observability evidence
- systemd observability service evidence
- public/internal port evidence
- service health signal inventory
- DB health signal placeholder
- Event bus backlog signal placeholder
- API Gateway health signal placeholder
- Mission Control / Ops Console signal placeholder
- alert readiness matrix
- no-restart / no-deploy / no-secret safety

Production hedef prensibi:
- Observability stack public yüzeyde açık olmamalı.
- Metrics/log/trace endpointleri auth / private network / VPN / allowlist arkasında olmalı.
- Service health, DB health, event backlog, queue depth, DLQ, retry, latency ve error-rate sinyalleri Ops Console'a bağlanmalı.
- Alert kuralları önce evidence olarak modellenmeli, sonra ayrı execution adımında uygulanmalı.
- Log/metric/trace içerikleri rapora basılmamalı; sadece endpoint status metadata yazılmalı.

Kapanış hedefi:
OBSERVABILITY_BASELINE=PASS
OBSERVABILITY_PREVIOUS_20=PASS
OBSERVABILITY_PREVIOUS_21=PASS
OBSERVABILITY_SIGNAL_INVENTORY=PASS
OBSERVABILITY_TARGET_INVENTORY=PASS
OBSERVABILITY_ENDPOINT_PROBE=PASS
OBSERVABILITY_ALERT_READINESS=PASS
OBSERVABILITY_NO_RESTART=PASS
OBSERVABILITY_NO_DEPLOY=PASS
OBSERVABILITY_SECRET_SAFE=PASS
FAZ4B_22_1_FINAL_STATUS=PASS
