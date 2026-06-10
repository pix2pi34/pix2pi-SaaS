# FAZ 4B / 22.4 - Traces / Tempo Readiness

Amaç:
Pix2pi observability katmanında trace / Tempo / OTEL readiness durumunu evidence-only olarak kontrol etmek.

Bu adım:
- Tempo config değiştirmez.
- Tempo restart/reload yapmaz.
- OTEL collector config değiştirmez.
- OTEL collector restart/reload yapmaz.
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
- Trace body rapora basmaz.
- OTEL payload rapora basmaz.
- Tempo query sonucu gövdesi rapora basmaz.
- Log body rapora basmaz.
- Metric body rapora basmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece endpoint, status code, TCP reachability, config marker, trace signal contract ve public surface metadata üretir.

Ön koşul:
- 22.1 Observability baseline / signal inventory PASS olmalı.
- 22.2 Metrics / scrape target readiness PASS olmalı.
- 22.3 Logs / Loki readiness PASS olmalı.
- 20 Infra Cleanup / Production Hardening final closure PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Kontrol alanları:
- Tempo /ready metadata
- Tempo /metrics metadata
- Tempo query/status endpoint metadata
- OTEL HTTP 4318 metadata
- OTEL gRPC 4317 TCP metadata
- Grafana health metadata
- trace_id / request_id / correlation_id marker inventory
- service_name / tenant_id / event_type marker inventory
- OpenTelemetry / OTEL / Tempo config marker inventory
- public trace surface policy
- trace signal contract
- no-restart / no-deploy / no-body-print / no-secret safety

Production hedef prensibi:
- Tempo ve OTEL collector public yüzeyde açık olmamalı.
- Trace endpointleri private network / VPN / auth / allowlist arkasında olmalı.
- Trace payload, span attribute, baggage, token, raw DSN ve secret içeriği rapora basılmamalı.
- request_id, trace_id, tenant_id ve service_name standardı tüm servislerde taşınmalı.
- Trace sampling ve retention ayrı execution adımında uygulanmalı.
- Ops Console trace gövdesi değil, trace health ve correlation metadata görmeli.

Kapanış hedefi:
TRACES_TEMPO_READINESS=PASS
TRACES_PREVIOUS_22_3=PASS
TRACES_TEMPO_ENDPOINT_PROBE=PASS
TRACES_PIPELINE_INVENTORY=PASS
TRACES_SIGNAL_CONTRACT=PASS
TRACES_PUBLIC_SURFACE_POLICY=PASS
TRACES_BODY_NOT_PRINTED=PASS
TRACES_NO_RESTART=PASS
TRACES_NO_CONFIG_CHANGE=PASS
TRACES_SECRET_SAFE=PASS
FAZ4B_22_4_FINAL_STATUS=PASS
