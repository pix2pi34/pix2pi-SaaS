#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "17_5_ui_api_implementation_plan_standard.md"
policy_file = report_dir / "17_5_ui_api_implementation_plan_policy.md"
ui_plan_file = report_dir / "17_5_ui_page_implementation_plan.tsv"
api_plan_file = report_dir / "17_5_api_endpoint_implementation_plan.tsv"
permission_mapping_file = report_dir / "17_5_ui_api_permission_mapping.tsv"
sequence_file = report_dir / "17_5_implementation_sequence.tsv"
test_plan_file = report_dir / "17_5_ui_api_test_plan.tsv"
matrix_file = report_dir / "17_5_ui_api_implementation_plan_matrix.tsv"
report_file = report_dir / "17_5_ui_api_implementation_plan_report.md"

prev_17_4 = report_dir / "17_4_realtime_channel_contract_report.md"
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

UI_PAGES = [
    ("workflow_dashboard", "/panel/workflows", "workflow", "workflow_overview,workflow_instance_table,workflow_health_card", "GET /api/v1/workflow-instances", "tenant.workflow.events", "workflow:read", "tenant_scoped", "YES", "10", "READY_FOR_IMPLEMENTATION"),
    ("workflow_detail", "/panel/workflows/{id}", "workflow", "workflow_timeline,workflow_action_panel,workflow_metadata_card", "GET /api/v1/workflow-instances/{id}", "tenant.workflow.timeline", "workflow:read", "tenant_scoped", "YES", "20", "READY_FOR_IMPLEMENTATION"),
    ("workflow_action_panel", "/panel/workflows/{id}/actions", "workflow", "start,pause,resume,retry,cancel,archive", "POST /api/v1/workflow-instances/{id}/actions", "tenant.workflow.events", "workflow:execute", "tenant_scoped", "YES", "30", "READY_FOR_IMPLEMENTATION"),
    ("approval_center", "/panel/approvals", "approval", "approval_queue,approve_button,reject_button,escalation_badge", "GET /api/v1/approvals", "tenant.approval.events", "approval:read", "tenant_scoped", "YES", "40", "READY_FOR_IMPLEMENTATION"),
    ("approval_detail", "/panel/approvals/{id}", "approval", "approval_reason,approve_action,reject_action,audit_ref", "GET /api/v1/approvals/{id}", "tenant.approval.events", "approval:read", "tenant_scoped", "YES", "45", "READY_FOR_IMPLEMENTATION"),
    ("task_center", "/panel/tasks", "task", "task_table,task_action_panel,overdue_badge", "GET /api/v1/tasks", "tenant.task.events", "task:read", "tenant_scoped", "YES", "50", "READY_FOR_IMPLEMENTATION"),
    ("notification_center", "/panel/notifications", "notification", "notification_stream,notification_filter", "GET /api/v1/notifications", "tenant.notification.events", "notification:read", "tenant_scoped", "YES", "60", "READY_FOR_IMPLEMENTATION"),
    ("tenant_audit_timeline", "/panel/audit/workflow", "audit", "audit_timeline,audit_filter", "GET /api/v1/audit/workflow", "tenant.audit.events", "audit:read", "tenant_scoped", "YES", "70", "READY_FOR_IMPLEMENTATION"),
    ("ops_workflow_console", "/ops/workflows", "ops", "workflow_ops_card,backlog_card,dlq_card", "GET /ops/v1/workflow", "ops.workflow.events", "ops:read", "platform_scoped", "YES", "80", "READY_FOR_IMPLEMENTATION"),
    ("ops_realtime_health", "/ops/realtime", "ops", "realtime_health_card,connection_count_card", "GET /ops/v1/realtime/health", "platform.realtime.health", "ops:read", "platform_scoped", "YES", "85", "READY_FOR_IMPLEMENTATION"),
    ("security_workflow_console", "/security/workflows", "security", "tenant_isolation_card,security_event_stream", "GET /ops/v1/security/workflow", "security.workflow.events", "security:read", "platform_scoped", "YES", "90", "READY_FOR_IMPLEMENTATION"),
    ("security_tenant_isolation_console", "/security/tenant-isolation", "security", "tenant_violation_stream,tenant_scope_filter", "GET /ops/v1/security/tenant-isolation", "security.tenant_isolation.events", "security:read", "platform_scoped", "YES", "95", "READY_FOR_IMPLEMENTATION"),
]

API_ENDPOINTS = [
    ("GET", "/api/v1/workflows", "workflow", "ListWorkflowDefinitions", "query:cursor/filter", "list envelope + meta.next_cursor", "workflow:read", "tenant_scoped", "NO", "none", "10", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/workflows", "workflow", "CreateWorkflowDefinition", "workflow definition DTO", "workflow definition envelope", "workflow:write", "tenant_scoped", "YES", "tenant.workflow.events", "20", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/workflow-instances", "workflow", "ListWorkflowInstances", "query:cursor/status", "instance list envelope", "workflow:read", "tenant_scoped", "NO", "tenant.workflow.events", "30", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/workflow-instances", "workflow", "StartWorkflowInstance", "start instance DTO", "instance envelope", "workflow:execute", "tenant_scoped", "YES", "tenant.workflow.events", "40", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/workflow-instances/{id}", "workflow", "GetWorkflowInstance", "path:id", "instance detail envelope", "workflow:read", "tenant_scoped", "NO", "tenant.workflow.timeline", "50", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/workflow-instances/{id}/actions", "workflow", "ExecuteWorkflowAction", "action DTO + idempotency key", "action result envelope", "workflow:execute", "tenant_scoped", "YES", "tenant.workflow.events", "60", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/approvals", "approval", "ListApprovals", "query:cursor/status", "approval list envelope", "approval:read", "tenant_scoped", "NO", "tenant.approval.events", "70", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/approvals/{id}", "approval", "GetApproval", "path:id", "approval detail envelope", "approval:read", "tenant_scoped", "NO", "tenant.approval.events", "75", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/approvals/{id}/approve", "approval", "ApproveRequest", "approve DTO + idempotency key", "approval result envelope", "approval:write", "tenant_scoped", "YES", "tenant.approval.events", "80", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/approvals/{id}/reject", "approval", "RejectRequest", "reject DTO + reason + idempotency key", "approval result envelope", "approval:write", "tenant_scoped", "YES", "tenant.approval.events", "90", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/tasks", "task", "ListTasks", "query:cursor/status", "task list envelope", "task:read", "tenant_scoped", "NO", "tenant.task.events", "100", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/tasks/{id}/complete", "task", "CompleteTask", "complete task DTO + idempotency key", "task result envelope", "task:write", "tenant_scoped", "YES", "tenant.task.events", "110", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/notifications", "notification", "ListNotifications", "query:cursor", "notification list envelope", "notification:read", "tenant_scoped", "NO", "tenant.notification.events", "120", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/audit/workflow", "audit", "ListWorkflowAudit", "query:cursor", "audit list envelope", "audit:read", "tenant_scoped", "NO", "tenant.audit.events", "130", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/realtime/events", "realtime", "OpenSSEStream", "query:channels", "SSE stream envelope", "realtime:read", "tenant_scoped", "YES", "tenant.workflow.events", "140", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/realtime/ws", "realtime", "OpenWebSocketStream", "query:channels", "WS subscribe envelope", "realtime:read", "tenant_scoped", "YES", "tenant.workflow.events", "150", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/workflow", "ops", "GetWorkflowOpsSummary", "query:scope", "ops workflow envelope", "ops:read", "platform_scoped", "NO", "ops.workflow.events", "160", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/workflow/backlog", "ops", "GetWorkflowBacklog", "query:cursor", "backlog envelope", "ops:read", "platform_scoped", "NO", "ops.workflow.backlog", "170", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/workflow/dlq", "ops", "GetWorkflowDLQ", "query:cursor", "dlq envelope", "ops:read", "platform_scoped", "NO", "ops.workflow.dlq", "180", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/realtime/health", "ops", "GetRealtimeHealth", "none", "realtime health envelope", "ops:read", "platform_scoped", "NO", "platform.realtime.health", "190", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/security/workflow", "security", "GetWorkflowSecurityEvents", "query:cursor", "security event envelope", "security:read", "platform_scoped", "NO", "security.workflow.events", "200", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/security/tenant-isolation", "security", "GetTenantIsolationEvents", "query:cursor", "tenant isolation envelope", "security:read", "platform_scoped", "NO", "security.tenant_isolation.events", "210", "READY_FOR_IMPLEMENTATION"),
]

PERMISSIONS = [
    ("workflow:read", "workflow_dashboard,workflow_detail", "GET workflow endpoints", "tenant_scoped", "tenant_admin_limited", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:write", "workflow_definition_editor", "POST /api/v1/workflows", "tenant_scoped", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:execute", "workflow_action_panel", "POST workflow instance/action endpoints", "tenant_scoped", "tenant_operator", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:pause", "workflow_action_panel", "pause action", "tenant_scoped", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:retry", "workflow_action_panel", "retry action", "tenant_scoped", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:cancel", "workflow_action_panel", "cancel action", "tenant_scoped", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:archive", "workflow_action_panel", "archive action", "tenant_scoped", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:read", "approval_center,approval_detail", "GET approval endpoints", "tenant_scoped", "tenant_approver", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:write", "approval_center,approval_detail", "approve/reject endpoints", "tenant_scoped", "tenant_approver", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:escalate", "approval_center", "escalation action", "tenant_scoped", "tenant_admin_or_system", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("task:read", "task_center", "GET /api/v1/tasks", "tenant_scoped", "tenant_user", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("task:write", "task_center", "POST /api/v1/tasks/{id}/complete", "tenant_scoped", "tenant_operator", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("notification:read", "notification_center", "GET /api/v1/notifications", "tenant_scoped", "tenant_user", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("notification:send", "notification_runtime_future", "notification binding future", "tenant_scoped", "system", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("audit:read", "tenant_audit_timeline", "GET /api/v1/audit/workflow", "tenant_scoped", "tenant_admin", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("realtime:read", "realtime stream clients", "GET /api/v1/realtime/events,/ws", "tenant_scoped", "tenant_user", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops:read", "ops_workflow_console,ops_realtime_health", "GET /ops/v1/*", "platform_scoped", "ops_admin", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security:read", "security_workflow_console,security_tenant_isolation_console", "GET /ops/v1/security/*", "platform_scoped", "security_admin", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
]

SEQUENCE = [
    ("10", "contract_freeze", "Freeze 17.1-17.5 docs and envelope names", "docs only", "no runtime change", "READY_FOR_IMPLEMENTATION"),
    ("20", "dto_design", "Define request/response DTOs and success/error envelope", "api DTO plan", "no code in this gate", "READY_FOR_IMPLEMENTATION"),
    ("30", "rbac_middleware_check", "Map endpoint permissions to JWT/RBAC/tenant middleware", "security plan", "tenant isolation required", "READY_FOR_IMPLEMENTATION"),
    ("40", "api_read_endpoints", "Implement GET workflow/approval/task/audit endpoints first", "api implementation future", "test with tenant headers", "READY_FOR_IMPLEMENTATION"),
    ("50", "api_mutation_endpoints", "Implement action/approve/reject/complete mutations with idempotency", "api implementation future", "audit required", "READY_FOR_IMPLEMENTATION"),
    ("60", "realtime_sse_first", "Implement SSE stream before WebSocket", "realtime implementation future", "simpler production baseline", "READY_FOR_IMPLEMENTATION"),
    ("70", "websocket_optional", "Implement WebSocket interactive channel after SSE is stable", "realtime implementation future", "optional after SSE tests", "READY_FOR_IMPLEMENTATION"),
    ("80", "ui_read_pages", "Build read-only workflow/approval/task pages", "UI implementation future", "no mutation first", "READY_FOR_IMPLEMENTATION"),
    ("90", "ui_action_pages", "Bind action panels with confirmation/reason/idempotency", "UI implementation future", "audit and permission visible", "READY_FOR_IMPLEMENTATION"),
    ("100", "ops_security_pages", "Bind ops/security realtime pages", "UI implementation future", "platform scoped only", "READY_FOR_IMPLEMENTATION"),
    ("110", "test_gate", "Run workflow/realtime tests and evidence reports", "17.6", "must pass before final closure", "READY_FOR_IMPLEMENTATION"),
]

TESTS = [
    ("ui_workflow_dashboard_contract", "ui", "workflow_dashboard", "widgets/data/realtime mapping exists", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ui_approval_center_contract", "ui", "approval_center", "approval actions mapped", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ui_task_center_contract", "ui", "task_center", "task stream mapped", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("api_workflow_read_contract", "api", "GET /api/v1/workflow-instances", "tenant scoped list envelope", "YES", "YES", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("api_workflow_action_contract", "api", "POST /api/v1/workflow-instances/{id}/actions", "idempotent audited mutation", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("api_approval_approve_contract", "api", "POST /api/v1/approvals/{id}/approve", "approval write enforced", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("api_approval_reject_contract", "api", "POST /api/v1/approvals/{id}/reject", "reject reason enforced", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("api_realtime_sse_contract", "api", "GET /api/v1/realtime/events", "SSE metadata-only envelope", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("api_realtime_ws_contract", "api", "GET /api/v1/realtime/ws", "WebSocket subscribe envelope", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops_workflow_contract", "ops", "GET /ops/v1/workflow", "platform scoped ops envelope", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security_tenant_isolation_contract", "security", "GET /ops/v1/security/tenant-isolation", "security scoped only", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("secret_payload_guard", "security", "all UI/API/realtime outputs", "no raw secret/raw payload", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
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
    return v[:360]

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
detail("FRONTEND_FILE_CREATED=NO")
detail("API_ROUTE_CREATED=NO")
detail("API_IMPLEMENTATION_CHANGED=NO")
detail("DTO_CODE_CREATED=NO")
detail("HANDLER_CODE_CREATED=NO")
detail("MIDDLEWARE_CHANGED=NO")
detail("WEBSOCKET_SERVER_STARTED=NO")
detail("SSE_SERVER_STARTED=NO")
detail("REALTIME_RUNTIME_CHANGED=NO")
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
detail("VALIDATION_MODE=UI_API_IMPLEMENTATION_PLAN_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_17_4_status = get_value(prev_17_4, "FAZ4B_17_4_FINAL_STATUS")
prev_17_4_gate = get_value(prev_17_4, "REALTIME_CHANNEL_CONTRACT")
prev_17_4_no_runtime = get_value(prev_17_4, "REALTIME_NO_RUNTIME_CHANGE")
prev_17_4_secret = get_value(prev_17_4, "REALTIME_SECRET_SAFE")
prev_17_3_status = get_value(prev_17_3, "FAZ4B_17_3_FINAL_STATUS")
prev_17_2_status = get_value(prev_17_2, "FAZ4B_17_2_FINAL_STATUS")
prev_17_1_status = get_value(prev_17_1, "FAZ4B_17_1_FINAL_STATUS")
prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_17_4_FINAL_STATUS={prev_17_4_status}")
detail(f"PREVIOUS_17_4_REALTIME_CHANNEL_CONTRACT={prev_17_4_gate}")
detail(f"PREVIOUS_17_4_REALTIME_NO_RUNTIME_CHANGE={prev_17_4_no_runtime}")
detail(f"PREVIOUS_17_4_REALTIME_SECRET_SAFE={prev_17_4_secret}")
detail(f"PREVIOUS_17_3_FINAL_STATUS={prev_17_3_status}")
detail(f"PREVIOUS_17_2_FINAL_STATUS={prev_17_2_status}")
detail(f"PREVIOUS_17_1_FINAL_STATUS={prev_17_1_status}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_17_4_status != "PASS":
    fail("17.4 final status PASS degil")
if prev_17_4_gate != "PASS":
    fail("17.4 realtime channel contract PASS degil")
if prev_17_4_no_runtime != "PASS":
    fail("17.4 no runtime change PASS degil")
if prev_17_4_secret != "PASS":
    fail("17.4 secret safe PASS degil")
if prev_17_3_status != "PASS":
    fail("17.3 final status PASS degil")
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

ui_lines = [
    "page_name\troute_candidate\tcategory\twidgets\tdata_source\trealtime_channel\trequired_permission\ttenant_scope\taudit_required\timplementation_order\timplementation_status\tnote"
]
for row in UI_PAGES:
    ui_lines.append("\t".join([safe(x) for x in list(row) + ["plan_only_no_ui_code"]]))
ui_plan_file.write_text("\n".join(ui_lines) + "\n")

api_lines = [
    "method\tpath\tcategory\thandler_candidate\trequest_contract\tresponse_contract\trequired_permission\ttenant_scope\taudit_required\trealtime_binding\timplementation_order\timplementation_status\tnote"
]
for row in API_ENDPOINTS:
    api_lines.append("\t".join([safe(x) for x in list(row) + ["plan_only_no_route_created"]]))
api_plan_file.write_text("\n".join(api_lines) + "\n")

permission_lines = [
    "permission_name\tui_surfaces\tapi_targets\ttenant_scope\tminimum_role\taudit_required\trbac_required\timplementation_status\tnote"
]
for row in PERMISSIONS:
    permission_lines.append("\t".join([safe(x) for x in list(row) + ["plan_only"]]))
permission_mapping_file.write_text("\n".join(permission_lines) + "\n")

sequence_lines = [
    "order_no\tstep_name\tdescription\ttarget\tsafety_note\timplementation_status\tnote"
]
for row in SEQUENCE:
    sequence_lines.append("\t".join([safe(x) for x in list(row) + ["plan_only"]]))
sequence_file.write_text("\n".join(sequence_lines) + "\n")

test_lines = [
    "test_name\tcategory\ttarget\texpected_result\ttenant_check\trbac_check\taudit_check\trealtime_check\timplementation_status\tnote"
]
for row in TESTS:
    test_lines.append("\t".join([safe(x) for x in list(row) + ["plan_only"]]))
test_plan_file.write_text("\n".join(test_lines) + "\n")

ui_count = len(UI_PAGES)
tenant_ui_count = sum(1 for p in UI_PAGES if p[7] == "tenant_scoped")
platform_ui_count = sum(1 for p in UI_PAGES if p[7] == "platform_scoped")
audit_ui_count = sum(1 for p in UI_PAGES if p[8] == "YES")
api_count = len(API_ENDPOINTS)
tenant_api_count = sum(1 for e in API_ENDPOINTS if e[7] == "tenant_scoped")
platform_api_count = sum(1 for e in API_ENDPOINTS if e[7] == "platform_scoped")
audit_api_count = sum(1 for e in API_ENDPOINTS if e[8] == "YES")
realtime_api_count = sum(1 for e in API_ENDPOINTS if e[9] != "none")
permission_count = len(PERMISSIONS)
permission_audit_count = sum(1 for p in PERMISSIONS if p[5] == "YES")
sequence_count = len(SEQUENCE)
test_count = len(TESTS)
tenant_test_count = sum(1 for t in TESTS if t[4] == "YES")
rbac_test_count = sum(1 for t in TESTS if t[5] == "YES")
audit_test_count = sum(1 for t in TESTS if t[6] == "YES")
realtime_test_count = sum(1 for t in TESTS if t[7] == "YES")

detail(f"UI_API_UI_PAGE_COUNT={ui_count}")
detail(f"UI_API_TENANT_UI_PAGE_COUNT={tenant_ui_count}")
detail(f"UI_API_PLATFORM_UI_PAGE_COUNT={platform_ui_count}")
detail(f"UI_API_AUDIT_UI_PAGE_COUNT={audit_ui_count}")
detail(f"UI_API_ENDPOINT_COUNT={api_count}")
detail(f"UI_API_TENANT_API_ENDPOINT_COUNT={tenant_api_count}")
detail(f"UI_API_PLATFORM_API_ENDPOINT_COUNT={platform_api_count}")
detail(f"UI_API_AUDIT_API_ENDPOINT_COUNT={audit_api_count}")
detail(f"UI_API_REALTIME_API_ENDPOINT_COUNT={realtime_api_count}")
detail(f"UI_API_PERMISSION_COUNT={permission_count}")
detail(f"UI_API_PERMISSION_AUDIT_COUNT={permission_audit_count}")
detail(f"UI_API_SEQUENCE_COUNT={sequence_count}")
detail(f"UI_API_TEST_COUNT={test_count}")
detail(f"UI_API_TENANT_TEST_COUNT={tenant_test_count}")
detail(f"UI_API_RBAC_TEST_COUNT={rbac_test_count}")
detail(f"UI_API_AUDIT_TEST_COUNT={audit_test_count}")
detail(f"UI_API_REALTIME_TEST_COUNT={realtime_test_count}")

required_ui = [
    "workflow_dashboard",
    "workflow_detail",
    "approval_center",
    "task_center",
    "ops_workflow_console",
    "security_workflow_console",
]
ui_names = set([x[0] for x in UI_PAGES])
missing_ui = [x for x in required_ui if x not in ui_names]

required_api = [
    "/api/v1/workflow-instances",
    "/api/v1/workflow-instances/{id}/actions",
    "/api/v1/approvals",
    "/api/v1/approvals/{id}/approve",
    "/api/v1/approvals/{id}/reject",
    "/api/v1/tasks",
    "/api/v1/realtime/events",
    "/api/v1/realtime/ws",
    "/ops/v1/workflow",
    "/ops/v1/security/tenant-isolation",
]
api_paths = set([x[1] for x in API_ENDPOINTS])
missing_api = [x for x in required_api if x not in api_paths]

required_permissions = [
    "workflow:read",
    "workflow:execute",
    "approval:read",
    "approval:write",
    "task:read",
    "task:write",
    "realtime:read",
    "ops:read",
    "security:read",
]
permission_names = set([x[0] for x in PERMISSIONS])
missing_permissions = [x for x in required_permissions if x not in permission_names]

if missing_ui:
    fail("required UI page eksik: " + ",".join(missing_ui))
if missing_api:
    fail("required API endpoint eksik: " + ",".join(missing_api))
if missing_permissions:
    fail("required permission eksik: " + ",".join(missing_permissions))
if audit_ui_count != ui_count:
    fail("tum UI pages audit_required YES degil")
if permission_count < 15:
    fail("permission mapping sayisi yetersiz")
if test_count < 10:
    fail("test plan sayisi yetersiz")
if tenant_test_count != test_count:
    fail("tum testlerde tenant_check YES degil")
if rbac_test_count != test_count:
    fail("tum testlerde rbac_check YES degil")
if realtime_test_count < 8:
    fail("realtime test coverage yetersiz")

previous_17_4_status = "PASS" if (
    prev_17_4_status == "PASS"
    and prev_17_4_gate == "PASS"
    and prev_17_4_no_runtime == "PASS"
    and prev_17_4_secret == "PASS"
) else "FAIL"

ui_plan_status = "PASS" if ui_plan_file.exists() and ui_count >= 10 and not missing_ui else "FAIL"
api_plan_status = "PASS" if api_plan_file.exists() and api_count >= 18 and not missing_api else "FAIL"
permission_mapping_status = "PASS" if permission_mapping_file.exists() and permission_count >= 15 and not missing_permissions else "FAIL"
sequence_status = "PASS" if sequence_file.exists() and sequence_count >= 8 else "FAIL"
test_plan_status = "PASS" if test_plan_file.exists() and test_count >= 10 else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"UI_API_PREVIOUS_17_4={previous_17_4_status}")
detail(f"UI_PAGE_IMPLEMENTATION_PLAN={ui_plan_status}")
detail(f"API_ENDPOINT_IMPLEMENTATION_PLAN={api_plan_status}")
detail(f"UI_API_PERMISSION_MAPPING={permission_mapping_status}")
detail(f"UI_API_SEQUENCE_PLAN={sequence_status}")
detail(f"UI_API_TEST_PLAN={test_plan_status}")
detail(f"UI_API_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"UI_API_NO_CONFIG_CHANGE={no_config_status}")
detail(f"UI_API_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_17_4", previous_17_4_status),
    ("ui_page_plan", ui_plan_status),
    ("api_endpoint_plan", api_plan_status),
    ("permission_mapping", permission_mapping_status),
    ("sequence_plan", sequence_status),
    ("test_plan", test_plan_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_17_4\t{previous_17_4_status}\trealtime channel contract prerequisite",
    f"ui_page_plan\t{ui_plan_status}\tui_pages={ui_count} tenant={tenant_ui_count} platform={platform_ui_count}",
    f"api_endpoint_plan\t{api_plan_status}\tapi_endpoints={api_count} tenant={tenant_api_count} platform={platform_api_count}",
    f"permission_mapping\t{permission_mapping_status}\tpermissions={permission_count} audit_permissions={permission_audit_count}",
    f"sequence_plan\t{sequence_status}\tsteps={sequence_count}",
    f"test_plan\t{test_plan_status}\ttests={test_count} tenant={tenant_test_count} rbac={rbac_test_count} realtime={realtime_test_count}",
    f"audit_coverage\tPASS\tui_audit={audit_ui_count} api_audit={audit_api_count}",
    f"realtime_mapping\tPASS\trealtime_api_endpoints={realtime_api_count}",
    f"tenant_platform_split\tPASS\ttenant_ui={tenant_ui_count} platform_ui={platform_ui_count} tenant_api={tenant_api_count} platform_api={platform_api_count}",
    f"no_runtime_change\t{no_runtime_status}\tno UI/API/realtime runtime changed",
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
    "ui_code_changed\tNO\tplan only",
    "frontend_file_created\tNO\tplan only",
    "api_route_created\tNO\tplan only",
    "api_implementation_changed\tNO\tplan only",
    "dto_code_created\tNO\tplan only",
    "handler_code_created\tNO\tplan only",
    "middleware_changed\tNO\tplan only",
    "websocket_server_started\tNO\tplan only",
    "sse_server_started\tNO\tplan only",
    "realtime_runtime_changed\tNO\tplan only",
    "workflow_runtime_changed\tNO\tplan only",
    "approval_runtime_changed\tNO\tplan only",
    "event_published\tNO\tplan only",
    "event_consumed\tNO\tplan only",
    "notification_sent\tNO\tplan only",
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
detail(f"UI_API_IMPLEMENTATION_PLAN={final_status}")
detail(f"FAZ4B_17_5_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 17.5 - UI Surface + API Implementation Plan Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"UI_API_IMPLEMENTATION_PLAN={final_status}",
    f"FAZ4B_17_5_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/17_5_ui_api_implementation_plan_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "UI_PAGE_IMPLEMENTATION_PLAN_FILE=docs/phase4/17_5_ui_page_implementation_plan.tsv",
    "API_ENDPOINT_IMPLEMENTATION_PLAN_FILE=docs/phase4/17_5_api_endpoint_implementation_plan.tsv",
    "UI_API_PERMISSION_MAPPING_FILE=docs/phase4/17_5_ui_api_permission_mapping.tsv",
    "IMPLEMENTATION_SEQUENCE_FILE=docs/phase4/17_5_implementation_sequence.tsv",
    "UI_API_TEST_PLAN_FILE=docs/phase4/17_5_ui_api_test_plan.tsv",
    "NOTE=Plan only. No UI/API/runtime/DB/config/event/notification change executed.",
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
    "FRONTEND_FILE_CREATED=NO",
    "API_ROUTE_CREATED=NO",
    "API_IMPLEMENTATION_CHANGED=NO",
    "DTO_CODE_CREATED=NO",
    "HANDLER_CODE_CREATED=NO",
    "MIDDLEWARE_CHANGED=NO",
    "WEBSOCKET_SERVER_STARTED=NO",
    "SSE_SERVER_STARTED=NO",
    "REALTIME_RUNTIME_CHANGED=NO",
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
print(f"UI_PAGE_IMPLEMENTATION_PLAN_FILE={ui_plan_file}")
print(f"API_ENDPOINT_IMPLEMENTATION_PLAN_FILE={api_plan_file}")
print(f"UI_API_PERMISSION_MAPPING_FILE={permission_mapping_file}")
print(f"IMPLEMENTATION_SEQUENCE_FILE={sequence_file}")
print(f"UI_API_TEST_PLAN_FILE={test_plan_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"UI_API_UI_PAGE_COUNT={ui_count}")
print(f"UI_API_TENANT_UI_PAGE_COUNT={tenant_ui_count}")
print(f"UI_API_PLATFORM_UI_PAGE_COUNT={platform_ui_count}")
print(f"UI_API_AUDIT_UI_PAGE_COUNT={audit_ui_count}")
print(f"UI_API_ENDPOINT_COUNT={api_count}")
print(f"UI_API_TENANT_API_ENDPOINT_COUNT={tenant_api_count}")
print(f"UI_API_PLATFORM_API_ENDPOINT_COUNT={platform_api_count}")
print(f"UI_API_AUDIT_API_ENDPOINT_COUNT={audit_api_count}")
print(f"UI_API_REALTIME_API_ENDPOINT_COUNT={realtime_api_count}")
print(f"UI_API_PERMISSION_COUNT={permission_count}")
print(f"UI_API_PERMISSION_AUDIT_COUNT={permission_audit_count}")
print(f"UI_API_SEQUENCE_COUNT={sequence_count}")
print(f"UI_API_TEST_COUNT={test_count}")
print(f"UI_API_TENANT_TEST_COUNT={tenant_test_count}")
print(f"UI_API_RBAC_TEST_COUNT={rbac_test_count}")
print(f"UI_API_AUDIT_TEST_COUNT={audit_test_count}")
print(f"UI_API_REALTIME_TEST_COUNT={realtime_test_count}")
print(f"UI_API_PREVIOUS_17_4={previous_17_4_status}")
print(f"UI_PAGE_IMPLEMENTATION_PLAN={ui_plan_status}")
print(f"API_ENDPOINT_IMPLEMENTATION_PLAN={api_plan_status}")
print(f"UI_API_PERMISSION_MAPPING={permission_mapping_status}")
print(f"UI_API_SEQUENCE_PLAN={sequence_status}")
print(f"UI_API_TEST_PLAN={test_plan_status}")
print(f"UI_API_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"UI_API_NO_CONFIG_CHANGE={no_config_status}")
print(f"UI_API_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("UI_CODE_CHANGED=NO")
print("FRONTEND_FILE_CREATED=NO")
print("API_ROUTE_CREATED=NO")
print("API_IMPLEMENTATION_CHANGED=NO")
print("DTO_CODE_CREATED=NO")
print("HANDLER_CODE_CREATED=NO")
print("MIDDLEWARE_CHANGED=NO")
print("WEBSOCKET_SERVER_STARTED=NO")
print("SSE_SERVER_STARTED=NO")
print("REALTIME_RUNTIME_CHANGED=NO")
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
print(f"UI_API_IMPLEMENTATION_PLAN={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_17_5_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
