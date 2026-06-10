# FAZ 4B / 17.1 - Workflow / Realtime UI Baseline Report

Generated at: 2026-04-29 19:36:21 

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
UI_CODE_CHANGED=NO
API_ROUTE_CREATED=NO
API_IMPLEMENTATION_CHANGED=NO
WEBSOCKET_SERVER_STARTED=NO
SSE_SERVER_STARTED=NO
WORKFLOW_RUNTIME_CHANGED=NO
EVENT_PUBLISHED=NO
EVENT_CONSUMED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
TOKEN_PRINTED=NO
VALIDATION_MODE=WORKFLOW_REALTIME_BASELINE_CONTRACT_ONLY
PREVIOUS_22_FINAL_STATUS=PASS
PREVIOUS_22_OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE=PASS
PREVIOUS_22_8_FINAL_STATUS=PASS
PREVIOUS_20_FINAL_STATUS=PASS
PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE=PASS
PREVIOUS_21_FINAL_STATUS=PASS
PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE=PASS
WORKFLOW_DOMAIN_COUNT=15
WORKFLOW_REALTIME_SIGNAL_COUNT=15
WORKFLOW_UI_SURFACE_COUNT=12
WORKFLOW_API_CANDIDATE_COUNT=13
WORKFLOW_EXISTING_SURFACE_MARKER_COUNT=120
WORKFLOW_CRITICAL_SIGNAL_COUNT=1
WORKFLOW_HIGH_SIGNAL_COUNT=4
WORKFLOW_AUDIT_REQUIRED_UI_COUNT=12
WORKFLOW_PREVIOUS_22=PASS
WORKFLOW_DOMAIN_INVENTORY=PASS
WORKFLOW_REALTIME_SIGNAL_CONTRACT=PASS
WORKFLOW_UI_SURFACE_CONTRACT=PASS
WORKFLOW_API_SURFACE_CANDIDATES=PASS
WORKFLOW_NO_RUNTIME_CHANGE=PASS
WORKFLOW_NO_CONFIG_CHANGE=PASS
WORKFLOW_SECRET_SAFE=PASS
WORKFLOW_REALTIME_BASELINE=PASS
FAZ4B_17_1_FINAL_STATUS=PASS
FAIL_COUNT=0
WARN_COUNT=0
WORKFLOW_REALTIME_BASELINE=PASS
FAZ4B_17_1_FINAL_STATUS=PASS

## Tool Status
TOOL_python3=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND

## Matrix
MATRIX_FILE=docs/phase4/17_1_workflow_realtime_baseline_matrix.tsv
gate	status	note
previous_22	PASS	observability ops console prerequisite
workflow_domain_inventory	PASS	domains=15
realtime_signal_contract	PASS	signals=15 critical=1 high=4
ui_surface_contract	PASS	ui_surfaces=12 audit_required=12
api_surface_candidates	PASS	api_candidates=13 existing_markers=120
no_runtime_change	PASS	no service/container/ui/api/runtime changed
no_config_change	PASS	no config/env/nginx/firewall changed
secret_safe	PASS	no secrets printed
service_restarted	NO	evidence only
container_restarted	NO	evidence only
docker_compose_executed	NO	evidence only
nginx_reload_executed	NO	evidence only
firewall_changed	NO	evidence only
port_changed	NO	evidence only
config_changed	NO	evidence only
env_changed	NO	evidence only
ui_code_changed	NO	contract only
api_route_created	NO	contract only
api_implementation_changed	NO	contract only
websocket_server_started	NO	contract only
sse_server_started	NO	contract only
workflow_runtime_changed	NO	contract only
event_published	NO	contract only
event_consumed	NO	contract only
db_mutation	NO	evidence only
db_apply_executed	NO	evidence only
migration_created	NO	evidence only
migration_apply_executed	NO	evidence only
raw_dsn_printed	NO	secret-safe report
secret_value_printed	NO	secret-safe report
token_printed	NO	secret-safe report

## Inventories
WORKFLOW_DOMAIN_INVENTORY_FILE=docs/phase4/17_1_workflow_domain_inventory.tsv
REALTIME_SIGNAL_CONTRACT_FILE=docs/phase4/17_1_realtime_signal_contract.tsv
UI_SURFACE_CONTRACT_FILE=docs/phase4/17_1_ui_surface_contract.tsv
API_SURFACE_CANDIDATE_INVENTORY_FILE=docs/phase4/17_1_api_surface_candidate_inventory.tsv
NOTE=Contract only. No UI/API/runtime/DB/config change executed.

## Safety Decision
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
UI_CODE_CHANGED=NO
API_ROUTE_CREATED=NO
API_IMPLEMENTATION_CHANGED=NO
WEBSOCKET_SERVER_STARTED=NO
SSE_SERVER_STARTED=NO
WORKFLOW_RUNTIME_CHANGED=NO
EVENT_PUBLISHED=NO
EVENT_CONSUMED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
TOKEN_PRINTED=NO

## Issues
OK ✅ issue yok
