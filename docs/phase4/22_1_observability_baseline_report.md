# FAZ 4B / 22.1 - Observability Baseline / Signal Inventory Report

Generated at: 2026-04-29 11:27:02 

## Summary
ROOT_DIR=/root/pix2pi/pix2pi-SaaS
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
DASHBOARD_CHANGED=NO
ALERT_RULE_CHANGED=NO
PROMETHEUS_CONFIG_CHANGED=NO
GRAFANA_CONFIG_CHANGED=NO
LOKI_CONFIG_CHANGED=NO
TEMPO_CONFIG_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
LOG_CONTENT_PRINTED=NO
METRIC_BODY_PRINTED=NO
TRACE_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
VALIDATION_MODE=OBSERVABILITY_BASELINE_EVIDENCE_ONLY
PREVIOUS_20_FINAL_STATUS=PASS
PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE=PASS
PREVIOUS_20_8_FINAL_STATUS=PASS
PREVIOUS_21_FINAL_STATUS=PASS
PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE=PASS
OBSERVABILITY_SIGNAL_COUNT=15
OBSERVABILITY_TARGET_COUNT=41
OBSERVABILITY_ENDPOINT_PROBE_COUNT=12
OBSERVABILITY_ENDPOINT_REACHABLE_COUNT=9
OBSERVABILITY_ENDPOINT_REVIEW_COUNT=5
OBSERVABILITY_ALERT_CANDIDATE_COUNT=14
OBSERVABILITY_CRITICAL_ALERT_COUNT=5
OBSERVABILITY_HIGH_ALERT_COUNT=6
OBSERVABILITY_PREVIOUS_PUBLIC_OBS_RISK_COUNT=24
OBSERVABILITY_PREVIOUS_HIGH_RISK_SERVICE_COUNT=22
OBSERVABILITY_PREVIOUS_HIGH_RISK_CONTAINER_COUNT=13
OBSERVABILITY_PREVIOUS_20=PASS
OBSERVABILITY_PREVIOUS_21=PASS
OBSERVABILITY_SIGNAL_INVENTORY=PASS
OBSERVABILITY_TARGET_INVENTORY=PASS
OBSERVABILITY_ENDPOINT_PROBE=PASS
OBSERVABILITY_ALERT_READINESS=PASS
OBSERVABILITY_NO_RESTART=PASS
OBSERVABILITY_NO_DEPLOY=PASS
OBSERVABILITY_SECRET_SAFE=PASS
OBSERVABILITY_MATRIX_LINE_COUNT=36
OBSERVABILITY_SIGNAL_INVENTORY_FILE=docs/phase4/22_1_observability_signal_inventory.tsv
OBSERVABILITY_TARGET_INVENTORY_FILE=docs/phase4/22_1_observability_target_inventory.tsv
OBSERVABILITY_ENDPOINT_PROBE_FILE=docs/phase4/22_1_observability_endpoint_probe.tsv
OBSERVABILITY_ALERT_READINESS_FILE=docs/phase4/22_1_observability_alert_readiness.tsv
OBSERVABILITY_BASELINE=PASS
FAZ4B_22_1_FINAL_STATUS=PASS
FAIL_COUNT=0
WARN_COUNT=0
OBSERVABILITY_BASELINE=PASS
FAZ4B_22_1_FINAL_STATUS=PASS

## Tool Status
TOOL_python3=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND
TOOL_curl=FOUND
TOOL_docker=FOUND
TOOL_systemctl=FOUND
TOOL_ss=FOUND

## Matrix
MATRIX_FILE=docs/phase4/22_1_observability_baseline_matrix.tsv
gate	status	note
previous_20	PASS	infra production hardening prerequisite
previous_21	PASS	security/rbac/audit prerequisite
signal_inventory	PASS	signals=15
target_inventory	PASS	targets=41
endpoint_probe	PASS	probes=12 reachable=9 review=5
alert_readiness	PASS	alerts=14 critical=5 high=6
public_observability_risk	PASS	previous_public_obs_risk_count=24
service_risk_evidence	PASS	previous_high_risk_service_count=22
container_risk_evidence	PASS	previous_high_risk_container_count=13
no_restart	PASS	service/container not restarted
no_deploy	PASS	deploy/config not changed
secret_safe	PASS	no log/metric/trace/secret body printed
service_restarted	NO	evidence only
container_restarted	NO	evidence only
docker_compose_executed	NO	evidence only
nginx_reload_executed	NO	evidence only
firewall_changed	NO	evidence only
config_changed	NO	evidence only
env_changed	NO	evidence only
dashboard_changed	NO	evidence only
alert_rule_changed	NO	evidence only
prometheus_config_changed	NO	evidence only
grafana_config_changed	NO	evidence only
loki_config_changed	NO	evidence only
tempo_config_changed	NO	evidence only
db_mutation	NO	evidence only
db_apply_executed	NO	evidence only
migration_created	NO	evidence only
migration_apply_executed	NO	evidence only
log_content_printed	NO	secret-safe report
metric_body_printed	NO	secret-safe report
trace_body_printed	NO	secret-safe report
query_text_printed	NO	secret-safe report
raw_dsn_printed	NO	secret-safe report
secret_value_printed	NO	secret-safe report

## Inventories
SIGNAL_INVENTORY_FILE=docs/phase4/22_1_observability_signal_inventory.tsv
TARGET_INVENTORY_FILE=docs/phase4/22_1_observability_target_inventory.tsv
ENDPOINT_PROBE_FILE=docs/phase4/22_1_observability_endpoint_probe.tsv
ALERT_READINESS_FILE=docs/phase4/22_1_observability_alert_readiness.tsv
NOTE=No log content, metric body, trace body, raw DSN, token, password, or secret values are printed.

## Safety Decision
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
DASHBOARD_CHANGED=NO
ALERT_RULE_CHANGED=NO
PROMETHEUS_CONFIG_CHANGED=NO
GRAFANA_CONFIG_CHANGED=NO
LOKI_CONFIG_CHANGED=NO
TEMPO_CONFIG_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
LOG_CONTENT_PRINTED=NO
METRIC_BODY_PRINTED=NO
TRACE_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
LOG_CONTENT_PRINTED=NO
METRIC_BODY_PRINTED=NO
TRACE_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
SECRET_VALUE_PRINTED=NO
