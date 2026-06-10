# FAZ 4B / 22.6 - Ops Console Signal Contract Report

Generated at: 2026-04-29 19:11:20 

## Summary
ROOT_DIR=/root/pix2pi/pix2pi-SaaS
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
OPS_CONSOLE_CODE_CHANGED=NO
OPS_CONSOLE_API_IMPLEMENTED=NO
OPS_CONSOLE_UI_CHANGED=NO
PROMETHEUS_CONFIG_CHANGED=NO
ALERTMANAGER_CONFIG_CHANGED=NO
GRAFANA_DASHBOARD_CHANGED=NO
GRAFANA_ALERT_CHANGED=NO
ALERT_RULE_CHANGED=NO
LOKI_CONFIG_CHANGED=NO
TEMPO_CONFIG_CHANGED=NO
OTEL_CONFIG_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
METRIC_BODY_PRINTED=NO
LOG_CONTENT_PRINTED=NO
TRACE_BODY_PRINTED=NO
QUERY_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
VALIDATION_MODE=OPS_CONSOLE_SIGNAL_CONTRACT_ONLY
PREVIOUS_22_5_FINAL_STATUS=PASS
PREVIOUS_22_5_ALERT_RULE_CATALOG=PASS
PREVIOUS_22_5_SERVICE_RESTARTED=NO
PREVIOUS_22_5_SECRET_VALUE_PRINTED=NO
PREVIOUS_22_4_FINAL_STATUS=PASS
PREVIOUS_22_3_FINAL_STATUS=PASS
PREVIOUS_22_2_FINAL_STATUS=PASS
PREVIOUS_22_1_FINAL_STATUS=PASS
PREVIOUS_20_FINAL_STATUS=PASS
PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE=PASS
PREVIOUS_21_FINAL_STATUS=PASS
PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE=PASS
OPS_SIGNAL_COUNT=22
OPS_CRITICAL_SIGNAL_COUNT=7
OPS_HIGH_SIGNAL_COUNT=12
OPS_MEDIUM_SIGNAL_COUNT=3
OPS_SECURITY_SIGNAL_COUNT=4
OPS_RUNTIME_SIGNAL_COUNT=2
OPS_OBSERVABILITY_SIGNAL_COUNT=3
OPS_WIDGET_COUNT=15
OPS_API_ENDPOINT_COUNT=19
OPS_ALERT_BINDING_COUNT=24
OPS_RUNBOOK_BINDING_COUNT=24
OPS_PREVIOUS_ALERT_COUNT=24
OPS_PREVIOUS_SEVERITY_COUNT=4
OPS_PREVIOUS_SIGNAL_MAPPING_COUNT=24
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
OPS_MATRIX_LINE_COUNT=45
OPS_SIGNAL_CONTRACT_FILE=docs/phase4/22_6_ops_console_signal_contract.tsv
OPS_WIDGET_CONTRACT_FILE=docs/phase4/22_6_ops_console_widget_contract.tsv
OPS_API_CONTRACT_FILE=docs/phase4/22_6_ops_console_api_contract.tsv
OPS_ALERT_BINDING_FILE=docs/phase4/22_6_ops_console_alert_binding.tsv
OPS_RUNBOOK_BINDING_FILE=docs/phase4/22_6_ops_console_runbook_binding.tsv
OPS_CONSOLE_SIGNAL_CONTRACT=PASS
FAZ4B_22_6_FINAL_STATUS=PASS
FAIL_COUNT=0
WARN_COUNT=0
OPS_CONSOLE_SIGNAL_CONTRACT=PASS
FAZ4B_22_6_FINAL_STATUS=PASS

## Tool Status
TOOL_python3=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND

## Matrix
MATRIX_FILE=docs/phase4/22_6_ops_console_signal_contract_matrix.tsv
gate	status	note
previous_22_5	PASS	alert rule catalog prerequisite
signal_contract	PASS	signals=22 critical=7 high=12
widget_contract	PASS	widgets=15
api_contract	PASS	api_endpoints=19
alert_binding	PASS	alert_bindings=24
runbook_binding	PASS	runbook_bindings=24
contract_coverage	PASS	all core contract artifacts ready
security_signals	PASS	count=4
runtime_signals	PASS	count=2
observability_signals	PASS	count=3
no_runtime_change	PASS	no service/container/ui/api implementation changed
no_config_change	PASS	no prometheus/grafana/alertmanager/loki/tempo config changed
body_not_printed	PASS	metric/log/trace/query body not printed
secret_safe	PASS	secret values not printed
service_restarted	NO	evidence only
container_restarted	NO	evidence only
docker_compose_executed	NO	evidence only
nginx_reload_executed	NO	evidence only
firewall_changed	NO	evidence only
port_changed	NO	evidence only
config_changed	NO	evidence only
env_changed	NO	evidence only
ops_console_code_changed	NO	contract only
ops_console_api_implemented	NO	contract only
ops_console_ui_changed	NO	contract only
prometheus_config_changed	NO	evidence only
alertmanager_config_changed	NO	evidence only
grafana_dashboard_changed	NO	evidence only
grafana_alert_changed	NO	evidence only
alert_rule_changed	NO	evidence only
loki_config_changed	NO	evidence only
tempo_config_changed	NO	evidence only
otel_config_changed	NO	evidence only
db_mutation	NO	evidence only
db_apply_executed	NO	evidence only
migration_created	NO	evidence only
migration_apply_executed	NO	evidence only
metric_body_printed	NO	secret-safe report
log_content_printed	NO	secret-safe report
trace_body_printed	NO	secret-safe report
query_body_printed	NO	secret-safe report
query_text_printed	NO	secret-safe report
raw_dsn_printed	NO	secret-safe report
secret_value_printed	NO	secret-safe report

## Inventories
OPS_SIGNAL_CONTRACT_FILE=docs/phase4/22_6_ops_console_signal_contract.tsv
OPS_WIDGET_CONTRACT_FILE=docs/phase4/22_6_ops_console_widget_contract.tsv
OPS_API_CONTRACT_FILE=docs/phase4/22_6_ops_console_api_contract.tsv
OPS_ALERT_BINDING_FILE=docs/phase4/22_6_ops_console_alert_binding.tsv
OPS_RUNBOOK_BINDING_FILE=docs/phase4/22_6_ops_console_runbook_binding.tsv
NOTE=Contract only. No Ops Console UI/API implementation, DB mutation, config change, or service restart is executed.

## Safety Decision
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
OPS_CONSOLE_CODE_CHANGED=NO
OPS_CONSOLE_API_IMPLEMENTED=NO
OPS_CONSOLE_UI_CHANGED=NO
PROMETHEUS_CONFIG_CHANGED=NO
ALERTMANAGER_CONFIG_CHANGED=NO
GRAFANA_DASHBOARD_CHANGED=NO
GRAFANA_ALERT_CHANGED=NO
ALERT_RULE_CHANGED=NO
LOKI_CONFIG_CHANGED=NO
TEMPO_CONFIG_CHANGED=NO
OTEL_CONFIG_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
METRIC_BODY_PRINTED=NO
LOG_CONTENT_PRINTED=NO
TRACE_BODY_PRINTED=NO
QUERY_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
METRIC_BODY_PRINTED=NO
LOG_CONTENT_PRINTED=NO
TRACE_BODY_PRINTED=NO
QUERY_BODY_PRINTED=NO
QUERY_TEXT_PRINTED=NO
SECRET_VALUE_PRINTED=NO
