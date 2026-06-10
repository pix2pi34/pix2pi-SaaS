# FAZ 4B / 20.4 - Nginx / Reverse Proxy Hardening Report

Generated at: 2026-04-29 10:53:12 

## Summary
ROOT_DIR=/root/pix2pi/pix2pi-SaaS
NGINX_CONFIG_CHANGED=NO
NGINX_RELOAD_EXECUTED=NO
NGINX_RESTARTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
DOCKER_PORT_CHANGED=NO
DOCKER_COMPOSE_EXECUTED=NO
SERVICE_RESTARTED=NO
DEPLOY_EXECUTED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
FILE_PERMISSION_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
LOG_CONTENT_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
VALIDATION_MODE=NGINX_REVERSE_PROXY_HARDENING_EVIDENCE_ONLY
PREVIOUS_20_3_FINAL_STATUS=PASS
PREVIOUS_20_3_RUNTIME_SERVICE_HARDENING=PASS
PREVIOUS_20_3_SERVICE_RESTARTED=NO
PREVIOUS_20_3_DEPLOY_EXECUTED=NO
PREVIOUS_20_2_FINAL_STATUS=PASS
PREVIOUS_20_1_FINAL_STATUS=PASS
PREVIOUS_21_FINAL_STATUS=PASS
PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE=PASS
NGINX_CONFIG_FILE_COUNT=6
NGINX_PROXY_SURFACE_COUNT=7
NGINX_PUBLIC_PORT_POLICY_COUNT=55
NGINX_ALLOWED_PUBLIC_PORT_COUNT=2
NGINX_MANAGEMENT_PUBLIC_PORT_COUNT=4
NGINX_INTERNAL_SHOULD_NOT_PUBLIC_COUNT=30
NGINX_UNKNOWN_PUBLIC_REVIEW_COUNT=19
NGINX_HIGH_RISK_PUBLIC_PORT_COUNT=49
NGINX_SECURITY_HEADER_MARKER_COUNT=0
NGINX_SSL_MARKER_COUNT=17
NGINX_RATE_LIMIT_MARKER_COUNT=12
NGINX_AUTH_MARKER_COUNT=0
NGINX_REVERSE_PROXY_PREVIOUS_20_3=PASS
NGINX_CONFIG_INVENTORY=PASS
NGINX_PROXY_SURFACE_MANIFEST=PASS
NGINX_PUBLIC_PORT_POLICY=PASS
NGINX_HARDENING_MATRIX=PASS
NGINX_NO_RELOAD=PASS
NGINX_NO_FIREWALL_CHANGE=PASS
NGINX_NO_DEPLOY=PASS
NGINX_SECRET_SAFE=PASS
NGINX_HARDENING_MATRIX_LINE_COUNT=38
NGINX_CONFIG_INVENTORY_FILE=docs/phase4/20_4_nginx_reverse_proxy_config_inventory.tsv
NGINX_PROXY_SURFACE_FILE=docs/phase4/20_4_nginx_reverse_proxy_surface_manifest.tsv
NGINX_PUBLIC_PORT_POLICY_FILE=docs/phase4/20_4_nginx_public_port_policy.tsv
NGINX_REVERSE_PROXY_HARDENING=PASS
FAZ4B_20_4_FINAL_STATUS=PASS
FAIL_COUNT=0
WARN_COUNT=0
NGINX_REVERSE_PROXY_HARDENING=PASS
FAZ4B_20_4_FINAL_STATUS=PASS

## Tool Status
TOOL_python3=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND
TOOL_nginx=FOUND
TOOL_ss=FOUND

## Matrix
MATRIX_FILE=docs/phase4/20_4_nginx_reverse_proxy_hardening_matrix.tsv
gate	status	note
previous_20_3	PASS	runtime service hardening prerequisite
config_inventory	PASS	nginx_config_files=6
proxy_surface_manifest	PASS	proxy_targets=7
public_port_policy	PASS	public_ports=55 high_risk=49
allowed_public_ports	PASS	allowed=2
management_public_ports	PASS	management=4
internal_should_not_public	PASS	count=30
unknown_public_review	PASS	count=19
security_header_markers	PASS	count=0
ssl_markers	PASS	count=17
rate_limit_markers	PASS	count=12
auth_markers	PASS	count=0
hardening_matrix	PASS	evidence only
no_reload	PASS	nginx not reloaded
no_firewall_change	PASS	firewall not changed
no_deploy	PASS	deploy not executed
secret_safe	PASS	no config body or secret values printed
nginx_config_changed	NO	evidence only
nginx_reload_executed	NO	evidence only
nginx_restarted	NO	evidence only
firewall_changed	NO	evidence only
port_changed	NO	evidence only
docker_port_changed	NO	evidence only
docker_compose_executed	NO	evidence only
service_restarted	NO	evidence only
deploy_executed	NO	evidence only
config_changed	NO	evidence only
env_changed	NO	evidence only
file_permission_changed	NO	evidence only
db_mutation	NO	evidence only
db_apply_executed	NO	evidence only
migration_created	NO	evidence only
migration_apply_executed	NO	evidence only
log_content_printed	NO	secret-safe report
query_text_printed	NO	secret-safe report
raw_dsn_printed	NO	secret-safe report
secret_value_printed	NO	secret-safe report

## Inventories
CONFIG_INVENTORY_FILE=docs/phase4/20_4_nginx_reverse_proxy_config_inventory.tsv
PROXY_SURFACE_FILE=docs/phase4/20_4_nginx_reverse_proxy_surface_manifest.tsv
PUBLIC_PORT_POLICY_FILE=docs/phase4/20_4_nginx_public_port_policy.tsv
NOTE=No full config body, logs, raw env values, raw DSN, token, password, or secret values are printed.

## Safety Decision
NGINX_CONFIG_CHANGED=NO
NGINX_RELOAD_EXECUTED=NO
NGINX_RESTARTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
DOCKER_PORT_CHANGED=NO
DOCKER_COMPOSE_EXECUTED=NO
SERVICE_RESTARTED=NO
DEPLOY_EXECUTED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
FILE_PERMISSION_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
LOG_CONTENT_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
QUERY_TEXT_PRINTED=NO
LOG_CONTENT_PRINTED=NO
SECRET_VALUE_PRINTED=NO
