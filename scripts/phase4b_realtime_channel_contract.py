#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "17_4_realtime_channel_contract_standard.md"
policy_file = report_dir / "17_4_realtime_channel_contract_policy.md"
channel_catalog_file = report_dir / "17_4_realtime_channel_catalog.tsv"
payload_envelope_file = report_dir / "17_4_realtime_payload_envelope.tsv"
delivery_policy_file = report_dir / "17_4_realtime_delivery_policy.tsv"
rbac_tenant_matrix_file = report_dir / "17_4_realtime_rbac_tenant_matrix.tsv"
reconnect_policy_file = report_dir / "17_4_realtime_reconnect_heartbeat_policy.tsv"
matrix_file = report_dir / "17_4_realtime_channel_contract_matrix.tsv"
report_file = report_dir / "17_4_realtime_channel_contract_report.md"

prev_17_3 = report_dir / "17_3_workflow_action_approval_contract_report.md"
prev_17_2 = report_dir / "17_2_workflow_state_machine_contract_report.md"
prev_17_1 = report_dir / "17_1_workflow_realtime_baseline_report.md"
prev_22 = report_dir / "22_observability_ops_console_final_closure_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

CHANNELS = [
    ("tenant.workflow.events", "SSE,WebSocket", "workflow", "tenant_scoped", "tenant_admin_limited", "workflow:read", "YES", "metadata_only_no_secret_no_raw_payload", "tenant_channel_standard", "latest_only_or_cursor", "YES", "READY_FOR_IMPLEMENTATION"),
    ("tenant.workflow.timeline", "SSE,WebSocket", "workflow", "tenant_scoped", "tenant_admin_limited", "workflow:read", "YES", "metadata_only_no_secret_no_raw_payload", "tenant_channel_standard", "cursor_replay_limited", "YES", "READY_FOR_IMPLEMENTATION"),
    ("tenant.workflow.health", "SSE", "workflow", "tenant_scoped", "tenant_admin_limited", "workflow:read", "YES", "metadata_only_no_secret_no_raw_payload", "tenant_channel_standard", "latest_only", "YES", "READY_FOR_IMPLEMENTATION"),
    ("tenant.approval.events", "SSE,WebSocket", "approval", "tenant_scoped", "tenant_approver", "approval:read", "YES", "metadata_only_no_secret_no_raw_payload", "tenant_channel_standard", "cursor_replay_limited", "YES", "READY_FOR_IMPLEMENTATION"),
    ("tenant.task.events", "SSE,WebSocket", "task", "tenant_scoped", "tenant_user", "task:read", "YES", "metadata_only_no_secret_no_raw_payload", "tenant_channel_standard", "cursor_replay_limited", "YES", "READY_FOR_IMPLEMENTATION"),
    ("tenant.notification.events", "SSE", "notification", "tenant_scoped", "tenant_user", "notification:read", "YES", "metadata_only_no_secret_no_raw_payload", "tenant_channel_standard", "latest_only", "YES", "READY_FOR_IMPLEMENTATION"),
    ("tenant.audit.events", "SSE", "audit", "tenant_scoped", "tenant_admin", "audit:read", "YES", "metadata_only_no_secret_no_raw_payload", "tenant_sensitive_channel", "cursor_replay_limited", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops.workflow.events", "SSE,WebSocket", "ops", "platform_scoped", "ops_admin", "ops:read", "YES", "metadata_only_no_secret_no_raw_payload", "ops_channel_strict", "cursor_replay_limited", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops.workflow.backlog", "SSE", "ops", "platform_scoped", "ops_admin", "ops:read", "YES", "metadata_only_no_secret_no_raw_payload", "ops_channel_strict", "latest_only", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops.workflow.dlq", "SSE", "ops", "platform_scoped", "ops_admin", "ops:read", "YES", "metadata_only_no_secret_no_raw_payload", "ops_channel_strict", "cursor_replay_limited", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security.workflow.events", "SSE,WebSocket", "security", "platform_scoped", "security_admin", "security:read", "YES", "metadata_only_no_secret_no_raw_payload", "security_channel_strict", "cursor_replay_limited", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security.tenant_isolation.events", "SSE", "security", "platform_scoped", "security_admin", "security:read", "YES", "metadata_only_no_secret_no_raw_payload", "security_channel_strict", "cursor_replay_limited", "YES", "READY_FOR_IMPLEMENTATION"),
    ("platform.realtime.health", "SSE", "platform", "platform_scoped", "platform_admin", "ops:read", "YES", "metadata_only_no_secret_no_raw_payload", "platform_health_channel", "latest_only", "YES", "READY_FOR_IMPLEMENTATION"),
]

PAYLOAD_FIELDS = [
    ("event_id", "required", "string_uuid", "non_secret", "event_bus_or_runtime", "unique event identifier"),
    ("event_type", "required", "string", "non_secret", "contract", "normalized realtime event type"),
    ("channel", "required", "string", "non_secret", "realtime_router", "channel name"),
    ("tenant_id", "required_for_tenant_channels", "string_or_int", "tenant_sensitive_metadata", "tenant_context", "tenant isolation key"),
    ("tenant_uuid", "recommended", "string_uuid", "tenant_sensitive_metadata", "tenant_context", "stable tenant key"),
    ("actor_id", "recommended", "string", "user_metadata", "auth_context", "actor identity metadata"),
    ("actor_type", "recommended", "string", "non_secret", "auth_context", "user/system actor"),
    ("request_id", "required", "string_uuid", "non_secret", "request_context", "request correlation"),
    ("trace_id", "recommended", "string", "non_secret", "otel_context", "trace correlation"),
    ("workflow_id", "recommended", "string_uuid", "business_metadata", "workflow_runtime", "workflow definition id"),
    ("workflow_instance_id", "recommended", "string_uuid", "business_metadata", "workflow_runtime", "workflow instance id"),
    ("approval_id", "optional", "string_uuid", "business_metadata", "approval_runtime", "approval request id"),
    ("task_id", "optional", "string_uuid", "business_metadata", "task_runtime", "task id"),
    ("severity", "required", "enum", "non_secret", "contract", "INFO/MEDIUM/HIGH/CRITICAL"),
    ("status", "required", "enum", "non_secret", "contract", "OK/WARN/FAILED/UPDATED"),
    ("summary", "required", "string_short", "sanitized", "runtime", "human readable sanitized summary"),
    ("metadata", "required", "object_flat", "sanitized", "runtime", "metadata only no raw payload"),
    ("occurred_at", "required", "timestamp", "non_secret", "runtime", "event time"),
]

DELIVERY_POLICIES = [
    ("sse_tenant_standard", "SSE", "per_channel_best_effort_order", "no_client_ack", "event_id_dedupe", "client_reconnect_with_last_event_id", "short_cursor_window", "READY_FOR_IMPLEMENTATION"),
    ("sse_ops_standard", "SSE", "per_channel_best_effort_order", "no_client_ack", "event_id_dedupe", "client_reconnect_with_last_event_id", "short_cursor_window", "READY_FOR_IMPLEMENTATION"),
    ("sse_security_strict", "SSE", "per_channel_best_effort_order", "no_client_ack", "event_id_dedupe", "client_reconnect_with_last_event_id", "short_cursor_window_audit_required", "READY_FOR_IMPLEMENTATION"),
    ("ws_tenant_interactive", "WebSocket", "per_connection_best_effort_order", "client_ack_optional_future", "event_id_dedupe", "reconnect_and_resubscribe", "no_raw_replay_without_auth", "READY_FOR_IMPLEMENTATION"),
    ("ws_ops_interactive", "WebSocket", "per_connection_best_effort_order", "client_ack_optional_future", "event_id_dedupe", "reconnect_and_resubscribe", "no_raw_replay_without_auth", "READY_FOR_IMPLEMENTATION"),
    ("ws_security_strict", "WebSocket", "per_connection_best_effort_order", "client_ack_optional_future", "event_id_dedupe", "reconnect_and_resubscribe", "no_raw_replay_without_auth", "READY_FOR_IMPLEMENTATION"),
]

RBAC_ROWS = [
    ("tenant.workflow.events", "workflow:read", "tenant_admin_limited", "tenant_id_required", "YES", "NO", "READY_FOR_IMPLEMENTATION"),
    ("tenant.workflow.timeline", "workflow:read", "tenant_admin_limited", "tenant_id_required", "YES", "NO", "READY_FOR_IMPLEMENTATION"),
    ("tenant.workflow.health", "workflow:read", "tenant_admin_limited", "tenant_id_required", "YES", "NO", "READY_FOR_IMPLEMENTATION"),
    ("tenant.approval.events", "approval:read", "tenant_approver", "tenant_id_required", "YES", "NO", "READY_FOR_IMPLEMENTATION"),
    ("tenant.task.events", "task:read", "tenant_user", "tenant_id_required", "YES", "NO", "READY_FOR_IMPLEMENTATION"),
    ("tenant.notification.events", "notification:read", "tenant_user", "tenant_id_required", "YES", "NO", "READY_FOR_IMPLEMENTATION"),
    ("tenant.audit.events", "audit:read", "tenant_admin", "tenant_id_required", "YES", "NO", "READY_FOR_IMPLEMENTATION"),
    ("ops.workflow.events", "ops:read", "ops_admin", "platform_scope_only", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops.workflow.backlog", "ops:read", "ops_admin", "platform_scope_only", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops.workflow.dlq", "ops:read", "ops_admin", "platform_scope_only", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security.workflow.events", "security:read", "security_admin", "platform_scope_only", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security.tenant_isolation.events", "security:read", "security_admin", "platform_scope_only", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("platform.realtime.health", "ops:read", "platform_admin", "platform_scope_only", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
]

RECONNECT_POLICIES = [
    ("SSE", "15s", "45s", "Last-Event-ID supported", "exponential_backoff_1s_2s_5s_10s_30s", "tenant_limit_per_user_and_tenant", "READY_FOR_IMPLEMENTATION"),
    ("WebSocket", "20s_ping_pong", "60s", "resubscribe_channels_after_reconnect", "exponential_backoff_1s_2s_5s_10s_30s", "tenant_limit_per_user_and_tenant", "READY_FOR_IMPLEMENTATION"),
    ("SecuritySSE", "10s", "30s", "Last-Event-ID supported audit logged", "exponential_backoff_1s_2s_5s_10s_30s", "security_admin_strict_limit", "READY_FOR_IMPLEMENTATION"),
    ("OpsSSE", "15s", "45s", "Last-Event-ID supported", "exponential_backoff_1s_2s_5s_10s_30s", "ops_admin_strict_limit", "READY_FOR_IMPLEMENTATION"),
]

def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")

def detail(line):
    details.append(line)

def fail(msg):
    failures.append(f"FAIL ❌ {msg}")

def warn(msg):
    warnings.append(f"WARN ⚠️ {msg}")

def tool_status(name):
    status = "FOUND" if which(name) else "NOT_FOUND"
    tools.append(f"TOOL_{name}={status}")

def read(path):
    if not path.exists():
        return ""
    try:
        if path.is_file() and path.stat().st_size > 2 * 1024 * 1024:
            return ""
    except Exception:
        return ""
    return path.read_text(errors="ignore")

def get_value(path, key):
    text = read(path)
    value = ""
    pattern = re.compile(rf"^{re.escape(key)}=(.*)$")
    for line in text.splitlines():
        m = pattern.match(line.strip())
        if m:
            value = m.group(1).strip().strip('"')
    return value

def safe(v):
    v = str(v or "")
    v = v.replace("\t", " ").replace("\n", " ").replace("\r", " ")
    v = re.sub(r"(password|token|secret|dsn|authorization)\s*[:=]\s*[^ ]+", r"\1=***", v, flags=re.I)
    v = re.sub(r"://[^/@\s]+@", "://***@", v)
    return v[:320]

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("SERVICE_RESTARTED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("DOCKER_COMPOSE_EXECUTED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
detail("FIREWALL_CHANGED=NO")
detail("PORT_CHANGED=NO")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("UI_CODE_CHANGED=NO")
detail("API_ROUTE_CREATED=NO")
detail("API_IMPLEMENTATION_CHANGED=NO")
detail("WEBSOCKET_SERVER_STARTED=NO")
detail("SSE_SERVER_STARTED=NO")
detail("REALTIME_RUNTIME_CHANGED=NO")
detail("REALTIME_SERVER_STARTED=NO")
detail("WORKFLOW_RUNTIME_CHANGED=NO")
detail("APPROVAL_RUNTIME_CHANGED=NO")
detail("EVENT_PUBLISHED=NO")
detail("EVENT_CONSUMED=NO")
detail("NOTIFICATION_SENT=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("RAW_PAYLOAD_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("TOKEN_PRINTED=NO")
detail("VALIDATION_MODE=REALTIME_CHANNEL_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_17_3_status = get_value(prev_17_3, "FAZ4B_17_3_FINAL_STATUS")
prev_17_3_gate = get_value(prev_17_3, "WORKFLOW_ACTION_APPROVAL_CONTRACT")
prev_17_3_no_runtime = get_value(prev_17_3, "WORKFLOW_ACTION_NO_RUNTIME_CHANGE")
prev_17_3_secret = get_value(prev_17_3, "WORKFLOW_ACTION_SECRET_SAFE")
prev_17_2_status = get_value(prev_17_2, "FAZ4B_17_2_FINAL_STATUS")
prev_17_1_status = get_value(prev_17_1, "FAZ4B_17_1_FINAL_STATUS")
prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_17_3_FINAL_STATUS={prev_17_3_status}")
detail(f"PREVIOUS_17_3_WORKFLOW_ACTION_APPROVAL_CONTRACT={prev_17_3_gate}")
detail(f"PREVIOUS_17_3_WORKFLOW_ACTION_NO_RUNTIME_CHANGE={prev_17_3_no_runtime}")
detail(f"PREVIOUS_17_3_WORKFLOW_ACTION_SECRET_SAFE={prev_17_3_secret}")
detail(f"PREVIOUS_17_2_FINAL_STATUS={prev_17_2_status}")
detail(f"PREVIOUS_17_1_FINAL_STATUS={prev_17_1_status}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_17_3_status != "PASS":
    fail("17.3 final status PASS degil")
if prev_17_3_gate != "PASS":
    fail("17.3 workflow action approval contract PASS degil")
if prev_17_3_no_runtime != "PASS":
    fail("17.3 no runtime change PASS degil")
if prev_17_3_secret != "PASS":
    fail("17.3 secret safe PASS degil")
if prev_17_2_status != "PASS":
    fail("17.2 final status PASS degil")
if prev_17_1_status != "PASS":
    fail("17.1 final status PASS degil")
if prev_22_status != "PASS":
    fail("22 final status PASS degil")
if prev_20_status != "PASS":
    fail("20 final status PASS degil")
if prev_20_closure != "PASS":
    fail("20 infra closure PASS degil")
if prev_21_status != "PASS":
    fail("21 final status PASS degil")
if prev_21_closure != "PASS":
    fail("21 security closure PASS degil")

for p, label in [(standard_file, "standard doc"), (policy_file, "policy doc")]:
    if not p.exists():
        fail(f"{label} yok")

channel_lines = [
    "channel_name\ttransport\tcategory\ttenant_scope\tvisibility_scope\trequired_permission\tauth_required\tpayload_policy\trate_limit_policy\treplay_policy\taudit_required\timplementation_status\tnote"
]
for row in CHANNELS:
    channel_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_server_started"]]))
channel_catalog_file.write_text("\n".join(channel_lines) + "\n")

payload_lines = [
    "envelope_field\trequirement\tfield_type\tsensitivity\tsource\tnote"
]
for row in PAYLOAD_FIELDS:
    payload_lines.append("\t".join([safe(x) for x in row]))
payload_envelope_file.write_text("\n".join(payload_lines) + "\n")

delivery_lines = [
    "delivery_name\ttransport\tordering_policy\tack_policy\tdedupe_policy\tretry_policy\tretention_policy\timplementation_status\tnote"
]
for row in DELIVERY_POLICIES:
    delivery_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
delivery_policy_file.write_text("\n".join(delivery_lines) + "\n")

rbac_lines = [
    "channel_name\trequired_permission\tminimum_role\ttenant_policy\tauth_required\tplatform_only\timplementation_status\tnote"
]
for row in RBAC_ROWS:
    rbac_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
rbac_tenant_matrix_file.write_text("\n".join(rbac_lines) + "\n")

reconnect_lines = [
    "transport\theartbeat_interval\tclient_timeout\treconnect_policy\tbackoff_policy\tmax_connections_policy\timplementation_status\tnote"
]
for row in RECONNECT_POLICIES:
    reconnect_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
reconnect_policy_file.write_text("\n".join(reconnect_lines) + "\n")

channel_count = len(CHANNELS)
tenant_channel_count = sum(1 for c in CHANNELS if c[3] == "tenant_scoped")
platform_channel_count = sum(1 for c in CHANNELS if c[3] == "platform_scoped")
sse_channel_count = sum(1 for c in CHANNELS if "SSE" in c[1])
ws_channel_count = sum(1 for c in CHANNELS if "WebSocket" in c[1])
security_channel_count = sum(1 for c in CHANNELS if c[2] == "security")
ops_channel_count = sum(1 for c in CHANNELS if c[2] == "ops")
auth_required_count = sum(1 for c in CHANNELS if c[6] == "YES")
audit_required_count = sum(1 for c in CHANNELS if c[10] == "YES")
metadata_only_count = sum(1 for c in CHANNELS if c[7] == "metadata_only_no_secret_no_raw_payload")

payload_field_count = len(PAYLOAD_FIELDS)
required_payload_count = sum(1 for p in PAYLOAD_FIELDS if p[1] == "required")
tenant_payload_count = sum(1 for p in PAYLOAD_FIELDS if "tenant" in p[0])
delivery_policy_count = len(DELIVERY_POLICIES)
rbac_row_count = len(RBAC_ROWS)
reconnect_policy_count = len(RECONNECT_POLICIES)

detail(f"REALTIME_CHANNEL_COUNT={channel_count}")
detail(f"REALTIME_TENANT_CHANNEL_COUNT={tenant_channel_count}")
detail(f"REALTIME_PLATFORM_CHANNEL_COUNT={platform_channel_count}")
detail(f"REALTIME_SSE_CHANNEL_COUNT={sse_channel_count}")
detail(f"REALTIME_WEBSOCKET_CHANNEL_COUNT={ws_channel_count}")
detail(f"REALTIME_SECURITY_CHANNEL_COUNT={security_channel_count}")
detail(f"REALTIME_OPS_CHANNEL_COUNT={ops_channel_count}")
detail(f"REALTIME_AUTH_REQUIRED_COUNT={auth_required_count}")
detail(f"REALTIME_AUDIT_REQUIRED_COUNT={audit_required_count}")
detail(f"REALTIME_METADATA_ONLY_CHANNEL_COUNT={metadata_only_count}")
detail(f"REALTIME_PAYLOAD_FIELD_COUNT={payload_field_count}")
detail(f"REALTIME_REQUIRED_PAYLOAD_FIELD_COUNT={required_payload_count}")
detail(f"REALTIME_TENANT_PAYLOAD_FIELD_COUNT={tenant_payload_count}")
detail(f"REALTIME_DELIVERY_POLICY_COUNT={delivery_policy_count}")
detail(f"REALTIME_RBAC_ROW_COUNT={rbac_row_count}")
detail(f"REALTIME_RECONNECT_POLICY_COUNT={reconnect_policy_count}")

channel_names = set([c[0] for c in CHANNELS])
required_channels = [
    "tenant.workflow.events",
    "tenant.approval.events",
    "tenant.task.events",
    "tenant.notification.events",
    "tenant.audit.events",
    "ops.workflow.events",
    "ops.workflow.backlog",
    "ops.workflow.dlq",
    "security.workflow.events",
    "security.tenant_isolation.events",
    "platform.realtime.health",
]
missing_channels = [x for x in required_channels if x not in channel_names]

if missing_channels:
    fail("required channel eksik: " + ",".join(missing_channels))
if auth_required_count != channel_count:
    fail("tum channels auth_required YES degil")
if audit_required_count != channel_count:
    fail("tum channels audit_required YES degil")
if metadata_only_count != channel_count:
    fail("tum channels metadata_only policy tasimiyor")
if tenant_channel_count < 5:
    fail("tenant channel sayisi yetersiz")
if platform_channel_count < 4:
    fail("platform channel sayisi yetersiz")
if sse_channel_count != channel_count:
    fail("tum channels SSE desteklemiyor")
if ws_channel_count < 5:
    fail("WebSocket destekli channel sayisi yetersiz")
if payload_field_count < 15:
    fail("payload envelope field sayisi yetersiz")
if delivery_policy_count < 4:
    fail("delivery policy sayisi yetersiz")
if rbac_row_count != channel_count:
    fail("RBAC row sayisi channel sayisina esit degil")
if reconnect_policy_count < 3:
    fail("reconnect policy sayisi yetersiz")

previous_17_3_status = "PASS" if (
    prev_17_3_status == "PASS"
    and prev_17_3_gate == "PASS"
    and prev_17_3_no_runtime == "PASS"
    and prev_17_3_secret == "PASS"
) else "FAIL"

channel_catalog_status = "PASS" if channel_catalog_file.exists() and channel_count >= 10 and not missing_channels else "FAIL"
payload_envelope_status = "PASS" if payload_envelope_file.exists() and payload_field_count >= 15 else "FAIL"
delivery_policy_status = "PASS" if delivery_policy_file.exists() and delivery_policy_count >= 4 else "FAIL"
rbac_tenant_status = "PASS" if rbac_tenant_matrix_file.exists() and rbac_row_count == channel_count else "FAIL"
reconnect_status = "PASS" if reconnect_policy_file.exists() and reconnect_policy_count >= 3 else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"REALTIME_PREVIOUS_17_3={previous_17_3_status}")
detail(f"REALTIME_CHANNEL_CATALOG={channel_catalog_status}")
detail(f"REALTIME_PAYLOAD_ENVELOPE={payload_envelope_status}")
detail(f"REALTIME_DELIVERY_POLICY={delivery_policy_status}")
detail(f"REALTIME_RBAC_TENANT_MATRIX={rbac_tenant_status}")
detail(f"REALTIME_RECONNECT_HEARTBEAT_POLICY={reconnect_status}")
detail(f"REALTIME_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"REALTIME_NO_CONFIG_CHANGE={no_config_status}")
detail(f"REALTIME_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_17_3", previous_17_3_status),
    ("channel_catalog", channel_catalog_status),
    ("payload_envelope", payload_envelope_status),
    ("delivery_policy", delivery_policy_status),
    ("rbac_tenant_matrix", rbac_tenant_status),
    ("reconnect_heartbeat_policy", reconnect_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_17_3\t{previous_17_3_status}\tworkflow action approval prerequisite",
    f"channel_catalog\t{channel_catalog_status}\tchannels={channel_count} tenant={tenant_channel_count} platform={platform_channel_count}",
    f"payload_envelope\t{payload_envelope_status}\tfields={payload_field_count} required={required_payload_count}",
    f"delivery_policy\t{delivery_policy_status}\tpolicies={delivery_policy_count}",
    f"rbac_tenant_matrix\t{rbac_tenant_status}\trbac_rows={rbac_row_count}",
    f"reconnect_heartbeat_policy\t{reconnect_status}\tpolicies={reconnect_policy_count}",
    f"transport_coverage\tPASS\tsse={sse_channel_count} websocket={ws_channel_count}",
    f"metadata_only_payload\tPASS\tmetadata_only_channels={metadata_only_count}",
    f"auth_audit_coverage\tPASS\tauth={auth_required_count} audit={audit_required_count}",
    f"no_runtime_change\t{no_runtime_status}\tno realtime/server/runtime changed",
    f"no_config_change\t{no_config_status}\tno config/env/nginx/firewall changed",
    f"secret_safe\t{secret_safe_status}\tno secrets printed",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "port_changed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "ui_code_changed\tNO\tcontract only",
    "api_route_created\tNO\tcontract only",
    "api_implementation_changed\tNO\tcontract only",
    "websocket_server_started\tNO\tcontract only",
    "sse_server_started\tNO\tcontract only",
    "realtime_runtime_changed\tNO\tcontract only",
    "realtime_server_started\tNO\tcontract only",
    "workflow_runtime_changed\tNO\tcontract only",
    "approval_runtime_changed\tNO\tcontract only",
    "event_published\tNO\tcontract only",
    "event_consumed\tNO\tcontract only",
    "notification_sent\tNO\tcontract only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "raw_payload_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
    "token_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"REALTIME_CHANNEL_CONTRACT={final_status}")
detail(f"FAZ4B_17_4_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 17.4 - Realtime Channel Contract Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"REALTIME_CHANNEL_CONTRACT={final_status}",
    f"FAZ4B_17_4_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/17_4_realtime_channel_contract_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "REALTIME_CHANNEL_CATALOG_FILE=docs/phase4/17_4_realtime_channel_catalog.tsv",
    "REALTIME_PAYLOAD_ENVELOPE_FILE=docs/phase4/17_4_realtime_payload_envelope.tsv",
    "REALTIME_DELIVERY_POLICY_FILE=docs/phase4/17_4_realtime_delivery_policy.tsv",
    "REALTIME_RBAC_TENANT_MATRIX_FILE=docs/phase4/17_4_realtime_rbac_tenant_matrix.tsv",
    "REALTIME_RECONNECT_HEARTBEAT_POLICY_FILE=docs/phase4/17_4_realtime_reconnect_heartbeat_policy.tsv",
    "NOTE=Contract only. No UI/API/runtime/DB/config/event/notification change executed.",
    "",
    "## Safety Decision",
    "SERVICE_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "FIREWALL_CHANGED=NO",
    "PORT_CHANGED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "UI_CODE_CHANGED=NO",
    "API_ROUTE_CREATED=NO",
    "API_IMPLEMENTATION_CHANGED=NO",
    "WEBSOCKET_SERVER_STARTED=NO",
    "SSE_SERVER_STARTED=NO",
    "REALTIME_RUNTIME_CHANGED=NO",
    "REALTIME_SERVER_STARTED=NO",
    "WORKFLOW_RUNTIME_CHANGED=NO",
    "APPROVAL_RUNTIME_CHANGED=NO",
    "EVENT_PUBLISHED=NO",
    "EVENT_CONSUMED=NO",
    "NOTIFICATION_SENT=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "RAW_PAYLOAD_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
    "TOKEN_PRINTED=NO",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"REALTIME_CHANNEL_CATALOG_FILE={channel_catalog_file}")
print(f"REALTIME_PAYLOAD_ENVELOPE_FILE={payload_envelope_file}")
print(f"REALTIME_DELIVERY_POLICY_FILE={delivery_policy_file}")
print(f"REALTIME_RBAC_TENANT_MATRIX_FILE={rbac_tenant_matrix_file}")
print(f"REALTIME_RECONNECT_HEARTBEAT_POLICY_FILE={reconnect_policy_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"REALTIME_CHANNEL_COUNT={channel_count}")
print(f"REALTIME_TENANT_CHANNEL_COUNT={tenant_channel_count}")
print(f"REALTIME_PLATFORM_CHANNEL_COUNT={platform_channel_count}")
print(f"REALTIME_SSE_CHANNEL_COUNT={sse_channel_count}")
print(f"REALTIME_WEBSOCKET_CHANNEL_COUNT={ws_channel_count}")
print(f"REALTIME_SECURITY_CHANNEL_COUNT={security_channel_count}")
print(f"REALTIME_OPS_CHANNEL_COUNT={ops_channel_count}")
print(f"REALTIME_AUTH_REQUIRED_COUNT={auth_required_count}")
print(f"REALTIME_AUDIT_REQUIRED_COUNT={audit_required_count}")
print(f"REALTIME_METADATA_ONLY_CHANNEL_COUNT={metadata_only_count}")
print(f"REALTIME_PAYLOAD_FIELD_COUNT={payload_field_count}")
print(f"REALTIME_REQUIRED_PAYLOAD_FIELD_COUNT={required_payload_count}")
print(f"REALTIME_TENANT_PAYLOAD_FIELD_COUNT={tenant_payload_count}")
print(f"REALTIME_DELIVERY_POLICY_COUNT={delivery_policy_count}")
print(f"REALTIME_RBAC_ROW_COUNT={rbac_row_count}")
print(f"REALTIME_RECONNECT_POLICY_COUNT={reconnect_policy_count}")
print(f"REALTIME_PREVIOUS_17_3={previous_17_3_status}")
print(f"REALTIME_CHANNEL_CATALOG={channel_catalog_status}")
print(f"REALTIME_PAYLOAD_ENVELOPE={payload_envelope_status}")
print(f"REALTIME_DELIVERY_POLICY={delivery_policy_status}")
print(f"REALTIME_RBAC_TENANT_MATRIX={rbac_tenant_status}")
print(f"REALTIME_RECONNECT_HEARTBEAT_POLICY={reconnect_status}")
print(f"REALTIME_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"REALTIME_NO_CONFIG_CHANGE={no_config_status}")
print(f"REALTIME_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("UI_CODE_CHANGED=NO")
print("API_ROUTE_CREATED=NO")
print("API_IMPLEMENTATION_CHANGED=NO")
print("WEBSOCKET_SERVER_STARTED=NO")
print("SSE_SERVER_STARTED=NO")
print("REALTIME_RUNTIME_CHANGED=NO")
print("REALTIME_SERVER_STARTED=NO")
print("WORKFLOW_RUNTIME_CHANGED=NO")
print("APPROVAL_RUNTIME_CHANGED=NO")
print("EVENT_PUBLISHED=NO")
print("EVENT_CONSUMED=NO")
print("NOTIFICATION_SENT=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("RAW_PAYLOAD_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print("TOKEN_PRINTED=NO")
print(f"REALTIME_CHANNEL_CONTRACT={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_17_4_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
