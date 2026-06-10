#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "17_3_workflow_action_approval_contract_standard.md"
policy_file = report_dir / "17_3_workflow_action_approval_contract_policy.md"
action_catalog_file = report_dir / "17_3_workflow_action_catalog.tsv"
approval_rule_file = report_dir / "17_3_workflow_approval_rule_catalog.tsv"
permission_matrix_file = report_dir / "17_3_workflow_action_permission_matrix.tsv"
audit_realtime_file = report_dir / "17_3_workflow_action_audit_realtime_binding.tsv"
matrix_file = report_dir / "17_3_workflow_action_approval_contract_matrix.tsv"
report_file = report_dir / "17_3_workflow_action_approval_contract_report.md"

prev_17_2 = report_dir / "17_2_workflow_state_machine_contract_report.md"
prev_17_1 = report_dir / "17_1_workflow_realtime_baseline_report.md"
prev_22 = report_dir / "22_observability_ops_console_final_closure_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

ACTIONS = [
    ("start", "workflow", "active", "running", "manual_or_system", "workflow:execute", "NO", "NO", "YES", "YES", "workflow.step.started", "workflow.started", "NO", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("pause", "workflow", "running", "paused", "manual", "workflow:pause", "NO", "YES", "YES", "YES", "workflow.instance.updated", "workflow.paused", "NO", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("resume", "workflow", "paused", "running", "manual", "workflow:execute", "NO", "NO", "YES", "YES", "workflow.instance.updated", "workflow.resumed", "NO", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("request_approval", "approval", "running", "waiting_approval", "system", "approval:request", "YES", "NO", "YES", "YES", "approval.requested", "workflow.approval.requested", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("approve", "approval", "waiting_approval", "running", "manual", "approval:write", "YES", "NO", "YES", "YES", "approval.approved", "workflow.approval.approved", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("reject", "approval", "waiting_approval", "cancelled", "manual", "approval:write", "YES", "YES", "YES", "YES", "approval.rejected", "workflow.approval.rejected", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("retry", "resilience", "failed", "running", "manual_or_system", "workflow:retry", "NO", "YES", "YES", "YES", "workflow.instance.updated", "workflow.retry.requested", "NO", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("cancel", "workflow", "running_or_failed_or_waiting_approval", "cancelled", "manual", "workflow:cancel", "NO", "YES", "YES", "YES", "workflow.instance.updated", "workflow.cancelled", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("complete", "workflow", "running", "completed", "system", "workflow:execute", "NO", "NO", "YES", "YES", "workflow.step.completed", "workflow.completed", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("fail", "workflow", "running", "failed", "system", "workflow:execute", "NO", "YES", "YES", "YES", "workflow.step.failed", "workflow.failed", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("assign_task", "task", "running", "running", "manual_or_system", "task:assign", "NO", "NO", "YES", "YES", "task.assigned", "workflow.task.assigned", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("complete_task", "task", "running", "running", "manual", "task:write", "NO", "NO", "YES", "YES", "task.completed", "workflow.task.completed", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("notify", "notification", "any_non_terminal", "same_state", "system", "notification:send", "NO", "NO", "YES", "YES", "notification.created", "workflow.notification.created", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("archive", "archive", "completed_or_cancelled", "archived", "manual_or_system", "workflow:archive", "NO", "NO", "YES", "YES", "workflow.instance.updated", "workflow.archived", "NO", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("external_resume", "integration", "waiting_external", "running", "system", "workflow:execute", "NO", "NO", "YES", "YES", "workflow.instance.updated", "workflow.external.resumed", "NO", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("escalate_approval", "approval", "waiting_approval", "waiting_approval", "system", "approval:escalate", "YES", "YES", "YES", "YES", "task.overdue", "workflow.approval.escalated", "YES", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
]

APPROVAL_RULES = [
    ("approver_role_required", "rbac", "CRITICAL", "approval action requires tenant approver role", "approval:write enforced", "approval:write", "YES", "approval.requested", "READY_FOR_IMPLEMENTATION"),
    ("cannot_approve_own_request", "segregation_of_duty", "CRITICAL", "actor cannot approve request created by same actor", "actor_id != requester_id", "approval:write", "YES", "approval.rejected", "READY_FOR_IMPLEMENTATION"),
    ("tenant_scope_required", "tenant_isolation", "CRITICAL", "approval request must stay in tenant scope", "tenant_id must match context", "approval:read", "YES", "approval.requested", "READY_FOR_IMPLEMENTATION"),
    ("approval_reason_optional_on_approve", "approval_policy", "MEDIUM", "approve may include reason but not mandatory", "reason optional", "approval:write", "YES", "approval.approved", "READY_FOR_IMPLEMENTATION"),
    ("reject_reason_required", "approval_policy", "HIGH", "reject must include reason", "reason required", "approval:write", "YES", "approval.rejected", "READY_FOR_IMPLEMENTATION"),
    ("approval_timeout_escalation", "sla", "HIGH", "waiting approval can escalate after timeout", "deadline exceeded triggers escalation", "approval:escalate", "YES", "task.overdue", "READY_FOR_IMPLEMENTATION"),
    ("idempotency_required", "safety", "CRITICAL", "approval action must be idempotent", "idempotency_key required", "approval:write", "YES", "workflow.instance.updated", "READY_FOR_IMPLEMENTATION"),
    ("state_match_required", "state_machine", "CRITICAL", "approve/reject only allowed in waiting_approval", "state == waiting_approval", "approval:write", "YES", "approval.requested", "READY_FOR_IMPLEMENTATION"),
    ("audit_required", "audit", "CRITICAL", "all approval actions require audit", "audit_required=YES", "approval:write", "YES", "approval.approved", "READY_FOR_IMPLEMENTATION"),
    ("metadata_only_realtime", "security", "CRITICAL", "approval realtime signal must not include raw payload", "payload_policy=metadata_only", "realtime:read", "YES", "approval.requested", "READY_FOR_IMPLEMENTATION"),
]

PERMISSIONS = [
    ("workflow:read", "view workflow and actions", "tenant_admin_limited", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:execute", "start/resume/complete workflow", "tenant_operator", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:pause", "pause workflow", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:retry", "retry failed workflow", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:cancel", "cancel workflow", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:archive", "archive workflow", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:request", "create approval request", "system", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:read", "read approval queue", "tenant_approver", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:write", "approve/reject approval", "tenant_approver", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:escalate", "escalate overdue approval", "system_or_tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("task:assign", "assign workflow task", "tenant_operator", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("task:write", "complete/update workflow task", "tenant_operator", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("notification:send", "create notification binding", "system", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("realtime:read", "subscribe realtime workflow signals", "tenant_user", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
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
detail("WORKFLOW_RUNTIME_CHANGED=NO")
detail("WORKFLOW_ENGINE_CODE_CHANGED=NO")
detail("APPROVAL_RUNTIME_CHANGED=NO")
detail("ACTION_RUNTIME_CREATED=NO")
detail("EVENT_PUBLISHED=NO")
detail("EVENT_CONSUMED=NO")
detail("NOTIFICATION_SENT=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("TOKEN_PRINTED=NO")
detail("VALIDATION_MODE=WORKFLOW_ACTION_APPROVAL_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_17_2_status = get_value(prev_17_2, "FAZ4B_17_2_FINAL_STATUS")
prev_17_2_gate = get_value(prev_17_2, "WORKFLOW_STATE_MACHINE_CONTRACT")
prev_17_2_no_runtime = get_value(prev_17_2, "WORKFLOW_STATE_NO_RUNTIME_CHANGE")
prev_17_2_secret = get_value(prev_17_2, "WORKFLOW_STATE_SECRET_SAFE")
prev_17_1_status = get_value(prev_17_1, "FAZ4B_17_1_FINAL_STATUS")
prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_17_2_FINAL_STATUS={prev_17_2_status}")
detail(f"PREVIOUS_17_2_WORKFLOW_STATE_MACHINE_CONTRACT={prev_17_2_gate}")
detail(f"PREVIOUS_17_2_WORKFLOW_STATE_NO_RUNTIME_CHANGE={prev_17_2_no_runtime}")
detail(f"PREVIOUS_17_2_WORKFLOW_STATE_SECRET_SAFE={prev_17_2_secret}")
detail(f"PREVIOUS_17_1_FINAL_STATUS={prev_17_1_status}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_17_2_status != "PASS":
    fail("17.2 final status PASS degil")
if prev_17_2_gate != "PASS":
    fail("17.2 state machine contract PASS degil")
if prev_17_2_no_runtime != "PASS":
    fail("17.2 no runtime change PASS degil")
if prev_17_2_secret != "PASS":
    fail("17.2 secret safe PASS degil")
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

action_lines = [
    "action_name\taction_category\tfrom_state\tto_state\tactor_type\trequired_permission\tapproval_required\treason_required\tidempotency_required\taudit_required\trealtime_signal\tevent_binding\tnotification_binding\ttenant_scope\timplementation_status\tnote"
]
for row in ACTIONS:
    action_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
action_catalog_file.write_text("\n".join(action_lines) + "\n")

approval_lines = [
    "rule_name\tcategory\tseverity\tcondition_hint\tenforcement_hint\trequired_permission\taudit_required\trealtime_signal\timplementation_status\tnote"
]
for row in APPROVAL_RULES:
    approval_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
approval_rule_file.write_text("\n".join(approval_lines) + "\n")

permission_lines = [
    "permission_name\tdescription\tminimum_role\taudit_required\ttenant_scope_required\timplementation_status\tnote"
]
for row in PERMISSIONS:
    permission_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
permission_matrix_file.write_text("\n".join(permission_lines) + "\n")

binding_lines = [
    "action_name\trealtime_signal\tevent_binding\tnotification_binding\taudit_required\tpayload_policy\tvisibility_scope\timplementation_status\tnote"
]
for action in ACTIONS:
    action_name = action[0]
    realtime_signal = action[10]
    event_binding = action[11]
    notification_binding = action[12]
    audit_required = action[9]
    visibility_scope = "tenant_admin_limited"
    if action[1] in ["approval", "resilience"]:
        visibility_scope = "tenant_admin_or_approver"
    if action[1] == "notification":
        visibility_scope = "tenant_admin_limited"
    binding_lines.append("\t".join([safe(x) for x in [
        action_name,
        realtime_signal,
        event_binding,
        notification_binding,
        audit_required,
        "metadata_only_no_secret_no_raw_payload",
        visibility_scope,
        "READY_FOR_IMPLEMENTATION",
        "contract_only_no_event_or_notification_sent",
    ]]))
audit_realtime_file.write_text("\n".join(binding_lines) + "\n")

action_count = len(ACTIONS)
approval_action_count = sum(1 for a in ACTIONS if a[1] == "approval")
system_action_count = sum(1 for a in ACTIONS if "system" in a[4])
manual_action_count = sum(1 for a in ACTIONS if "manual" in a[4])
approval_required_count = sum(1 for a in ACTIONS if a[6] == "YES")
reason_required_count = sum(1 for a in ACTIONS if a[7] == "YES")
idempotency_required_count = sum(1 for a in ACTIONS if a[8] == "YES")
audit_action_count = sum(1 for a in ACTIONS if a[9] == "YES")
event_binding_count = sum(1 for a in ACTIONS if a[11] != "")
notification_binding_count = sum(1 for a in ACTIONS if a[12] == "YES")
tenant_scoped_action_count = sum(1 for a in ACTIONS if a[13] == "tenant_scoped")

approval_rule_count = len(APPROVAL_RULES)
critical_approval_rule_count = sum(1 for r in APPROVAL_RULES if r[2] == "CRITICAL")
permission_count = len(PERMISSIONS)
permission_audit_count = sum(1 for p in PERMISSIONS if p[3] == "YES")
binding_count = action_count

detail(f"WORKFLOW_ACTION_COUNT={action_count}")
detail(f"WORKFLOW_APPROVAL_ACTION_COUNT={approval_action_count}")
detail(f"WORKFLOW_SYSTEM_ACTION_COUNT={system_action_count}")
detail(f"WORKFLOW_MANUAL_ACTION_COUNT={manual_action_count}")
detail(f"WORKFLOW_APPROVAL_REQUIRED_ACTION_COUNT={approval_required_count}")
detail(f"WORKFLOW_REASON_REQUIRED_ACTION_COUNT={reason_required_count}")
detail(f"WORKFLOW_IDEMPOTENCY_REQUIRED_ACTION_COUNT={idempotency_required_count}")
detail(f"WORKFLOW_AUDIT_ACTION_COUNT={audit_action_count}")
detail(f"WORKFLOW_EVENT_BINDING_COUNT={event_binding_count}")
detail(f"WORKFLOW_NOTIFICATION_BINDING_COUNT={notification_binding_count}")
detail(f"WORKFLOW_TENANT_SCOPED_ACTION_COUNT={tenant_scoped_action_count}")
detail(f"WORKFLOW_APPROVAL_RULE_COUNT={approval_rule_count}")
detail(f"WORKFLOW_CRITICAL_APPROVAL_RULE_COUNT={critical_approval_rule_count}")
detail(f"WORKFLOW_ACTION_PERMISSION_COUNT={permission_count}")
detail(f"WORKFLOW_ACTION_PERMISSION_AUDIT_COUNT={permission_audit_count}")
detail(f"WORKFLOW_ACTION_AUDIT_REALTIME_BINDING_COUNT={binding_count}")

action_names = set([a[0] for a in ACTIONS])
required_actions = [
    "start", "pause", "resume", "request_approval", "approve", "reject",
    "retry", "cancel", "complete", "fail", "assign_task", "complete_task",
    "notify", "archive", "external_resume", "escalate_approval"
]
missing_actions = [x for x in required_actions if x not in action_names]

approve_rows = [a for a in ACTIONS if a[0] == "approve"]
reject_rows = [a for a in ACTIONS if a[0] == "reject"]
retry_rows = [a for a in ACTIONS if a[0] == "retry"]
cancel_rows = [a for a in ACTIONS if a[0] == "cancel"]
archive_rows = [a for a in ACTIONS if a[0] == "archive"]

if missing_actions:
    fail("required action eksik: " + ",".join(missing_actions))
if not approve_rows or approve_rows[0][2] != "waiting_approval" or approve_rows[0][5] != "approval:write":
    fail("approve action waiting_approval + approval:write degil")
if not reject_rows or reject_rows[0][2] != "waiting_approval" or reject_rows[0][7] != "YES":
    fail("reject action waiting_approval veya reason_required YES degil")
if not retry_rows or retry_rows[0][2] != "failed":
    fail("retry action failed state uzerinden degil")
if not cancel_rows or cancel_rows[0][7] != "YES":
    fail("cancel action reason_required YES degil")
if not archive_rows or archive_rows[0][2] != "completed_or_cancelled":
    fail("archive action terminal state uzerinden degil")
if audit_action_count != action_count:
    fail("tum action audit_required YES degil")
if event_binding_count != action_count:
    fail("tum action event binding tasimiyor")
if tenant_scoped_action_count != action_count:
    fail("tum action tenant scoped degil")
if idempotency_required_count != action_count:
    fail("tum action idempotency_required YES degil")

previous_17_2_status = "PASS" if (
    prev_17_2_status == "PASS"
    and prev_17_2_gate == "PASS"
    and prev_17_2_no_runtime == "PASS"
    and prev_17_2_secret == "PASS"
) else "FAIL"

action_catalog_status = "PASS" if action_catalog_file.exists() and action_count >= 14 and not missing_actions else "FAIL"
approval_rule_status = "PASS" if approval_rule_file.exists() and approval_rule_count >= 8 else "FAIL"
permission_matrix_status = "PASS" if permission_matrix_file.exists() and permission_count >= 10 else "FAIL"
audit_realtime_status = "PASS" if audit_realtime_file.exists() and binding_count == action_count else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"WORKFLOW_ACTION_PREVIOUS_17_2={previous_17_2_status}")
detail(f"WORKFLOW_ACTION_CATALOG={action_catalog_status}")
detail(f"WORKFLOW_APPROVAL_RULE_CATALOG={approval_rule_status}")
detail(f"WORKFLOW_ACTION_PERMISSION_MATRIX={permission_matrix_status}")
detail(f"WORKFLOW_ACTION_AUDIT_REALTIME_BINDING={audit_realtime_status}")
detail(f"WORKFLOW_ACTION_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"WORKFLOW_ACTION_NO_CONFIG_CHANGE={no_config_status}")
detail(f"WORKFLOW_ACTION_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_17_2", previous_17_2_status),
    ("action_catalog", action_catalog_status),
    ("approval_rule_catalog", approval_rule_status),
    ("permission_matrix", permission_matrix_status),
    ("audit_realtime_binding", audit_realtime_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_17_2\t{previous_17_2_status}\tworkflow state machine prerequisite",
    f"action_catalog\t{action_catalog_status}\tactions={action_count} approval_actions={approval_action_count}",
    f"approval_rule_catalog\t{approval_rule_status}\trules={approval_rule_count} critical={critical_approval_rule_count}",
    f"permission_matrix\t{permission_matrix_status}\tpermissions={permission_count} audit_permissions={permission_audit_count}",
    f"audit_realtime_binding\t{audit_realtime_status}\tbindings={binding_count} event_bindings={event_binding_count} notifications={notification_binding_count}",
    f"idempotency_coverage\tPASS\tidempotency_required={idempotency_required_count}",
    f"reason_policy\tPASS\treason_required={reason_required_count}",
    f"tenant_scope\tPASS\ttenant_scoped_actions={tenant_scoped_action_count}",
    f"no_runtime_change\t{no_runtime_status}\tno workflow/action/approval runtime changed",
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
    "workflow_runtime_changed\tNO\tcontract only",
    "workflow_engine_code_changed\tNO\tcontract only",
    "approval_runtime_changed\tNO\tcontract only",
    "action_runtime_created\tNO\tcontract only",
    "event_published\tNO\tcontract only",
    "event_consumed\tNO\tcontract only",
    "notification_sent\tNO\tcontract only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
    "token_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"WORKFLOW_ACTION_APPROVAL_CONTRACT={final_status}")
detail(f"FAZ4B_17_3_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 17.3 - Workflow Action / Approval Contract Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"WORKFLOW_ACTION_APPROVAL_CONTRACT={final_status}",
    f"FAZ4B_17_3_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/17_3_workflow_action_approval_contract_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "WORKFLOW_ACTION_CATALOG_FILE=docs/phase4/17_3_workflow_action_catalog.tsv",
    "WORKFLOW_APPROVAL_RULE_CATALOG_FILE=docs/phase4/17_3_workflow_approval_rule_catalog.tsv",
    "WORKFLOW_ACTION_PERMISSION_MATRIX_FILE=docs/phase4/17_3_workflow_action_permission_matrix.tsv",
    "WORKFLOW_ACTION_AUDIT_REALTIME_BINDING_FILE=docs/phase4/17_3_workflow_action_audit_realtime_binding.tsv",
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
    "WORKFLOW_RUNTIME_CHANGED=NO",
    "WORKFLOW_ENGINE_CODE_CHANGED=NO",
    "APPROVAL_RUNTIME_CHANGED=NO",
    "ACTION_RUNTIME_CREATED=NO",
    "EVENT_PUBLISHED=NO",
    "EVENT_CONSUMED=NO",
    "NOTIFICATION_SENT=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
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
print(f"WORKFLOW_ACTION_CATALOG_FILE={action_catalog_file}")
print(f"WORKFLOW_APPROVAL_RULE_CATALOG_FILE={approval_rule_file}")
print(f"WORKFLOW_ACTION_PERMISSION_MATRIX_FILE={permission_matrix_file}")
print(f"WORKFLOW_ACTION_AUDIT_REALTIME_BINDING_FILE={audit_realtime_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"WORKFLOW_ACTION_COUNT={action_count}")
print(f"WORKFLOW_APPROVAL_ACTION_COUNT={approval_action_count}")
print(f"WORKFLOW_SYSTEM_ACTION_COUNT={system_action_count}")
print(f"WORKFLOW_MANUAL_ACTION_COUNT={manual_action_count}")
print(f"WORKFLOW_APPROVAL_REQUIRED_ACTION_COUNT={approval_required_count}")
print(f"WORKFLOW_REASON_REQUIRED_ACTION_COUNT={reason_required_count}")
print(f"WORKFLOW_IDEMPOTENCY_REQUIRED_ACTION_COUNT={idempotency_required_count}")
print(f"WORKFLOW_AUDIT_ACTION_COUNT={audit_action_count}")
print(f"WORKFLOW_EVENT_BINDING_COUNT={event_binding_count}")
print(f"WORKFLOW_NOTIFICATION_BINDING_COUNT={notification_binding_count}")
print(f"WORKFLOW_TENANT_SCOPED_ACTION_COUNT={tenant_scoped_action_count}")
print(f"WORKFLOW_APPROVAL_RULE_COUNT={approval_rule_count}")
print(f"WORKFLOW_CRITICAL_APPROVAL_RULE_COUNT={critical_approval_rule_count}")
print(f"WORKFLOW_ACTION_PERMISSION_COUNT={permission_count}")
print(f"WORKFLOW_ACTION_PERMISSION_AUDIT_COUNT={permission_audit_count}")
print(f"WORKFLOW_ACTION_AUDIT_REALTIME_BINDING_COUNT={binding_count}")
print(f"WORKFLOW_ACTION_PREVIOUS_17_2={previous_17_2_status}")
print(f"WORKFLOW_ACTION_CATALOG={action_catalog_status}")
print(f"WORKFLOW_APPROVAL_RULE_CATALOG={approval_rule_status}")
print(f"WORKFLOW_ACTION_PERMISSION_MATRIX={permission_matrix_status}")
print(f"WORKFLOW_ACTION_AUDIT_REALTIME_BINDING={audit_realtime_status}")
print(f"WORKFLOW_ACTION_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"WORKFLOW_ACTION_NO_CONFIG_CHANGE={no_config_status}")
print(f"WORKFLOW_ACTION_SECRET_SAFE={secret_safe_status}")
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
print("WORKFLOW_RUNTIME_CHANGED=NO")
print("WORKFLOW_ENGINE_CODE_CHANGED=NO")
print("APPROVAL_RUNTIME_CHANGED=NO")
print("ACTION_RUNTIME_CREATED=NO")
print("EVENT_PUBLISHED=NO")
print("EVENT_CONSUMED=NO")
print("NOTIFICATION_SENT=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print("TOKEN_PRINTED=NO")
print(f"WORKFLOW_ACTION_APPROVAL_CONTRACT={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_17_3_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
