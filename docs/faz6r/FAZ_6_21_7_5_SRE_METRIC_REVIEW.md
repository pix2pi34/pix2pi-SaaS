# FAZ 6-R / 289 — FAZ 6-21.7.5 SRE Metric Review

## Amaç

Pix2pi SRE / Edge / Release operasyonları için kritik metric review standardını kurar.

Bu adım canlı Prometheus/Grafana/alert provider üzerinde değişiklik yapmaz. Önce metric katalog, SLI/SLO review, threshold standardı, dashboard mapping, dry-run metric snapshot ve evidence üretir.

## Bağımlılık

- FAZ 6-21.7.4 Escalation zinciri

## Required Controls

- escalation_dependency_gate
- sli_slo_metric_catalog
- golden_signals_policy
- edge_security_metrics
- api_gateway_metrics
- db_metrics
- event_queue_metrics
- cache_metrics
- release_health_metrics
- incident_readiness_metrics
- alert_threshold_policy
- dashboard_mapping_policy
- dry_run_metric_snapshot
- provider_closed_policy
- evidence_capture_policy
- final_status_policy

## SRE Metric Review İlkeleri

1. Metric seti golden signals ile başlar: latency, traffic, errors, saturation.
2. Edge security metricleri WAF/bot/TLS edge kapanışlarıyla ilişkilidir.
3. API gateway, DB, event queue, cache ve release health ayrı takip edilir.
4. P0/P1 threshold'ları escalation zinciriyle uyumlu olmalıdır.
5. Dashboard mapping olmadan metric review tamam sayılmaz.
6. Alert provider bu adımda açılmaz.
7. Runtime sadece dry-run snapshot üretir.
8. Evidence olmadan sonraki DR / cost / tuning bloğuna geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- METRIC_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

