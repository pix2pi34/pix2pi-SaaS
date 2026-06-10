# LVL11 Correlation Summary

## Correlation
- service_to_service => trace_id/request_id/source_service/target_service
- request_chain => request_id/correlation_id/tenant_id/route
- incident_grouping => fingerprint_window
- noisy_alert_suppression => dedupe_and_cooldown
- root_cause_hints => db_bottleneck_hint,event_backlog_hint,reporting_impact_hint

## Scale Triggers
- DB bottleneck: warn=250ms crit=600ms
- Event backlog: warn=2000 crit=8000
- Reporting impact: warn=400ms crit=900ms
- Single-node risk: warn=75% crit=90%
- Deploy risk growth: warn=2 crit=5
- Cluster transition: warn=70 crit=90
