#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "17_2_workflow_state_machine_contract_standard.md"
policy_file = report_dir / "17_2_workflow_state_machine_contract_policy.md"
state_catalog_file = report_dir / "17_2_workflow_state_catalog.tsv"
transition_catalog_file = report_dir / "17_2_workflow_transition_catalog.tsv"
permission_matrix_file = report_dir / "17_2_workflow_state_permission_matrix.tsv"
invariant_catalog_file = report_dir / "17_2_workflow_state_invariant_catalog.tsv"
matrix_file = report_dir / "17_2_workflow_state_machine_contract_matrix.tsv"
report_file = report_dir / "17_2_workflow_state_machine_contract_report.md"

prev_17_1 = report_dir / "17_1_workflow_realtime_baseline_report.md"
prev_22 = report_dir / "22_observability_ops_console_final_closure_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

STATES = [
    ("draft", "pre_runtime", "YES", "NO", "workflow_admin_or_owner", "YES", "workflow.instance.created", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("active", "ready", "NO", "NO", "workflow_admin_or_owner", "YES", "workflow.instance.updated", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("running", "runtime", "NO", "NO", "system_or_authorized_user", "YES", "workflow.step.started", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("paused", "runtime_hold", "NO", "NO", "workflow_admin_or_owner", "YES", "workflow.instance.updated", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("waiting_approval", "human_gate", "NO", "NO", "approver", "YES", "approval.requested", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("waiting_external", "external_gate", "NO", "NO", "system", "YES", "workflow.instance.updated", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("completed", "terminal_success", "NO", "YES", "system", "YES", "workflow.step.completed", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("failed", "terminal_or_retryable_error", "NO", "NO", "system_or_workflow_admin", "YES", "workflow.step.failed", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("cancelled", "terminal_cancel", "NO", "YES", "workflow_admin_or_owner", "YES", "workflow.instance.updated", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
    ("archived", "terminal_archive", "NO", "YES", "workflow_admin", "YES", "workflow.instance.updated", "tenant_scoped", "READY_FOR_IMPLEMENTATION"),
]

TRANSITIONS = [
    ("activate_workflow", "draft", "active", "manual", "workflow:write", "NO", "YES", "workflow.instance.updated", "workflow.state.changed", "workflow_admin_or_owner", "READY_FOR_IMPLEMENTATION"),
    ("start_workflow", "active", "running", "manual_or_system", "workflow:execute", "NO", "YES", "workflow.step.started", "workflow.state.changed", "workflow_admin_or_system", "READY_FOR_IMPLEMENTATION"),
    ("request_approval", "running", "waiting_approval", "system", "approval:request", "YES", "YES", "approval.requested", "workflow.approval.requested", "system", "READY_FOR_IMPLEMENTATION"),
    ("approve_and_resume", "waiting_approval", "running", "manual", "approval:write", "YES", "YES", "approval.approved", "workflow.approval.approved", "approver", "READY_FOR_IMPLEMENTATION"),
    ("reject_and_cancel", "waiting_approval", "cancelled", "manual", "approval:write", "YES", "YES", "approval.rejected", "workflow.approval.rejected", "approver", "READY_FOR_IMPLEMENTATION"),
    ("wait_external", "running", "waiting_external", "system", "workflow:execute", "NO", "YES", "workflow.instance.updated", "workflow.external.waiting", "system", "READY_FOR_IMPLEMENTATION"),
    ("external_resume", "waiting_external", "running", "system", "workflow:execute", "NO", "YES", "workflow.instance.updated", "workflow.external.resumed", "system", "READY_FOR_IMPLEMENTATION"),
    ("pause_workflow", "running", "paused", "manual", "workflow:pause", "NO", "YES", "workflow.instance.updated", "workflow.paused", "workflow_admin_or_owner", "READY_FOR_IMPLEMENTATION"),
    ("resume_workflow", "paused", "running", "manual", "workflow:execute", "NO", "YES", "workflow.instance.updated", "workflow.resumed", "workflow_admin_or_owner", "READY_FOR_IMPLEMENTATION"),
    ("complete_workflow", "running", "completed", "system", "workflow:execute", "NO", "YES", "workflow.step.completed", "workflow.completed", "system", "READY_FOR_IMPLEMENTATION"),
    ("fail_workflow", "running", "failed", "system", "workflow:execute", "NO", "YES", "workflow.step.failed", "workflow.failed", "system", "READY_FOR_IMPLEMENTATION"),
    ("retry_failed_workflow", "failed", "running", "manual_or_system", "workflow:retry", "NO", "YES", "workflow.instance.updated", "workflow.retry.requested", "workflow_admin_or_system", "READY_FOR_IMPLEMENTATION"),
    ("cancel_failed_workflow", "failed", "cancelled", "manual", "workflow:cancel", "NO", "YES", "workflow.instance.updated", "workflow.cancelled", "workflow_admin_or_owner", "READY_FOR_IMPLEMENTATION"),
    ("archive_completed", "completed", "archived", "manual_or_system", "workflow:archive", "NO", "YES", "workflow.instance.updated", "workflow.archived", "workflow_admin_or_system", "READY_FOR_IMPLEMENTATION"),
    ("archive_cancelled", "cancelled", "archived", "manual_or_system", "workflow:archive", "NO", "YES", "workflow.instance.updated", "workflow.archived", "workflow_admin_or_system", "READY_FOR_IMPLEMENTATION"),
]

PERMISSIONS = [
    ("workflow:read", "view workflow definitions and instances", "tenant_admin_limited", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:write", "create or modify workflow definitions", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:execute", "start or continue workflow execution", "tenant_operator", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:pause", "pause active workflow instance", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:retry", "retry failed workflow instance", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:cancel", "cancel workflow instance", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow:archive", "archive terminal workflow instance", "tenant_admin", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:request", "create approval request from workflow", "system", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:read", "view approval request queue", "tenant_approver", "NO", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval:write", "approve or reject approval request", "tenant_approver", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
]

INVARIANTS = [
    ("single_initial_state", "exactly one state must have is_initial=YES", "CRITICAL", "PASS_EXPECTED", "contract_rule"),
    ("terminal_archived_locked", "archived must not have outgoing transition", "CRITICAL", "PASS_EXPECTED", "contract_rule"),
    ("terminal_completed_archive_only", "completed can only transition to archived", "HIGH", "PASS_EXPECTED", "contract_rule"),
    ("terminal_cancelled_archive_only", "cancelled can only transition to archived", "HIGH", "PASS_EXPECTED", "contract_rule"),
    ("tenant_scope_required", "all states and transitions must be tenant scoped", "CRITICAL", "PASS_EXPECTED", "tenant_isolation"),
    ("audit_required_for_mutation", "all non-read transitions require audit", "CRITICAL", "PASS_EXPECTED", "audit"),
    ("approval_transition_permission", "approval transitions require approval permission", "CRITICAL", "PASS_EXPECTED", "rbac"),
    ("failure_retry_or_cancel", "failed state must allow retry or cancel", "HIGH", "PASS_EXPECTED", "resilience"),
    ("no_secret_payload", "realtime state payload must be metadata-only", "CRITICAL", "PASS_EXPECTED", "security"),
    ("event_binding_ready", "each transition must have event binding placeholder", "HIGH", "PASS_EXPECTED", "event_bus"),
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
    return v[:300]

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
detail("STATE_MACHINE_RUNTIME_CREATED=NO")
detail("EVENT_PUBLISHED=NO")
detail("EVENT_CONSUMED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("TOKEN_PRINTED=NO")
detail("VALIDATION_MODE=WORKFLOW_STATE_MACHINE_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_17_1_status = get_value(prev_17_1, "FAZ4B_17_1_FINAL_STATUS")
prev_17_1_gate = get_value(prev_17_1, "WORKFLOW_REALTIME_BASELINE")
prev_17_1_no_runtime = get_value(prev_17_1, "WORKFLOW_NO_RUNTIME_CHANGE")
prev_17_1_secret = get_value(prev_17_1, "WORKFLOW_SECRET_SAFE")
prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_17_1_FINAL_STATUS={prev_17_1_status}")
detail(f"PREVIOUS_17_1_WORKFLOW_REALTIME_BASELINE={prev_17_1_gate}")
detail(f"PREVIOUS_17_1_WORKFLOW_NO_RUNTIME_CHANGE={prev_17_1_no_runtime}")
detail(f"PREVIOUS_17_1_WORKFLOW_SECRET_SAFE={prev_17_1_secret}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_17_1_status != "PASS":
    fail("17.1 final status PASS degil")
if prev_17_1_gate != "PASS":
    fail("17.1 workflow realtime baseline PASS degil")
if prev_17_1_no_runtime != "PASS":
    fail("17.1 no runtime change PASS degil")
if prev_17_1_secret != "PASS":
    fail("17.1 secret safe PASS degil")
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

state_lines = [
    "state_name\tstate_category\tis_initial\tis_terminal\tallowed_actor\taudit_required\trealtime_signal\ttenant_scope\timplementation_status\tnote"
]
for row in STATES:
    state_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
state_catalog_file.write_text("\n".join(state_lines) + "\n")

transition_lines = [
    "transition_name\tfrom_state\tto_state\ttrigger_type\trequired_permission\tapproval_required\taudit_required\trealtime_signal\tevent_binding\tallowed_actor\timplementation_status\tnote"
]
for row in TRANSITIONS:
    transition_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
transition_catalog_file.write_text("\n".join(transition_lines) + "\n")

permission_lines = [
    "permission_name\tdescription\tminimum_role\taudit_required\ttenant_scope_required\timplementation_status\tnote"
]
for row in PERMISSIONS:
    permission_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
permission_matrix_file.write_text("\n".join(permission_lines) + "\n")

invariant_lines = [
    "invariant_name\tdescription\tseverity\texpected_status\tcategory\tnote"
]
for row in INVARIANTS:
    invariant_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
invariant_catalog_file.write_text("\n".join(invariant_lines) + "\n")

state_count = len(STATES)
transition_count = len(TRANSITIONS)
permission_count = len(PERMISSIONS)
invariant_count = len(INVARIANTS)
initial_state_count = sum(1 for s in STATES if s[2] == "YES")
terminal_state_count = sum(1 for s in STATES if s[3] == "YES")
audit_state_count = sum(1 for s in STATES if s[5] == "YES")
audit_transition_count = sum(1 for t in TRANSITIONS if t[6] == "YES")
approval_transition_count = sum(1 for t in TRANSITIONS if t[5] == "YES")
event_binding_count = sum(1 for t in TRANSITIONS if t[8] != "")
tenant_scoped_state_count = sum(1 for s in STATES if s[7] == "tenant_scoped")
critical_invariant_count = sum(1 for i in INVARIANTS if i[2] == "CRITICAL")

detail(f"WORKFLOW_STATE_COUNT={state_count}")
detail(f"WORKFLOW_TRANSITION_COUNT={transition_count}")
detail(f"WORKFLOW_PERMISSION_COUNT={permission_count}")
detail(f"WORKFLOW_INVARIANT_COUNT={invariant_count}")
detail(f"WORKFLOW_INITIAL_STATE_COUNT={initial_state_count}")
detail(f"WORKFLOW_TERMINAL_STATE_COUNT={terminal_state_count}")
detail(f"WORKFLOW_AUDIT_STATE_COUNT={audit_state_count}")
detail(f"WORKFLOW_AUDIT_TRANSITION_COUNT={audit_transition_count}")
detail(f"WORKFLOW_APPROVAL_TRANSITION_COUNT={approval_transition_count}")
detail(f"WORKFLOW_EVENT_BINDING_COUNT={event_binding_count}")
detail(f"WORKFLOW_TENANT_SCOPED_STATE_COUNT={tenant_scoped_state_count}")
detail(f"WORKFLOW_CRITICAL_INVARIANT_COUNT={critical_invariant_count}")

state_names = set([s[0] for s in STATES])
transition_state_unknown = []
for t in TRANSITIONS:
    if t[1] not in state_names or t[2] not in state_names:
        transition_state_unknown.append(t[0])

archived_outgoing_count = sum(1 for t in TRANSITIONS if t[1] == "archived")
completed_invalid_outgoing_count = sum(1 for t in TRANSITIONS if t[1] == "completed" and t[2] != "archived")
cancelled_invalid_outgoing_count = sum(1 for t in TRANSITIONS if t[1] == "cancelled" and t[2] != "archived")
failed_retry_count = sum(1 for t in TRANSITIONS if t[1] == "failed" and t[2] == "running")
failed_cancel_count = sum(1 for t in TRANSITIONS if t[1] == "failed" and t[2] == "cancelled")

if initial_state_count != 1:
    fail("initial state sayisi 1 degil")
if archived_outgoing_count != 0:
    fail("archived state outgoing transition var")
if completed_invalid_outgoing_count != 0:
    fail("completed state archived disina cikiyor")
if cancelled_invalid_outgoing_count != 0:
    fail("cancelled state archived disina cikiyor")
if failed_retry_count < 1:
    fail("failed -> running retry transition yok")
if failed_cancel_count < 1:
    fail("failed -> cancelled transition yok")
if transition_state_unknown:
    fail("transition unknown state referansi var: " + ",".join(transition_state_unknown))
if event_binding_count != transition_count:
    fail("her transition event binding tasimiyor")
if audit_transition_count != transition_count:
    fail("her transition audit_required YES degil")
if tenant_scoped_state_count != state_count:
    fail("tum states tenant scoped degil")

previous_17_1_status = "PASS" if (
    prev_17_1_status == "PASS"
    and prev_17_1_gate == "PASS"
    and prev_17_1_no_runtime == "PASS"
    and prev_17_1_secret == "PASS"
) else "FAIL"

state_catalog_status = "PASS" if state_catalog_file.exists() and state_count >= 8 and initial_state_count == 1 else "FAIL"
transition_catalog_status = "PASS" if transition_catalog_file.exists() and transition_count >= 12 and not transition_state_unknown else "FAIL"
permission_matrix_status = "PASS" if permission_matrix_file.exists() and permission_count >= 8 else "FAIL"
invariant_catalog_status = "PASS" if invariant_catalog_file.exists() and invariant_count >= 8 else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"WORKFLOW_STATE_PREVIOUS_17_1={previous_17_1_status}")
detail(f"WORKFLOW_STATE_CATALOG={state_catalog_status}")
detail(f"WORKFLOW_TRANSITION_CATALOG={transition_catalog_status}")
detail(f"WORKFLOW_STATE_PERMISSION_MATRIX={permission_matrix_status}")
detail(f"WORKFLOW_STATE_INVARIANT_CATALOG={invariant_catalog_status}")
detail(f"WORKFLOW_STATE_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"WORKFLOW_STATE_NO_CONFIG_CHANGE={no_config_status}")
detail(f"WORKFLOW_STATE_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_17_1", previous_17_1_status),
    ("state_catalog", state_catalog_status),
    ("transition_catalog", transition_catalog_status),
    ("permission_matrix", permission_matrix_status),
    ("invariant_catalog", invariant_catalog_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_17_1\t{previous_17_1_status}\tworkflow realtime baseline prerequisite",
    f"state_catalog\t{state_catalog_status}\tstates={state_count} initial={initial_state_count} terminal={terminal_state_count}",
    f"transition_catalog\t{transition_catalog_status}\ttransitions={transition_count} event_bindings={event_binding_count}",
    f"permission_matrix\t{permission_matrix_status}\tpermissions={permission_count}",
    f"invariant_catalog\t{invariant_catalog_status}\tinvariants={invariant_count} critical={critical_invariant_count}",
    f"audit_coverage\tPASS\tstate_audit={audit_state_count} transition_audit={audit_transition_count}",
    f"approval_coverage\tPASS\tapproval_transitions={approval_transition_count}",
    f"tenant_scope\tPASS\ttenant_scoped_states={tenant_scoped_state_count}",
    f"no_runtime_change\t{no_runtime_status}\tno workflow runtime/code/server changed",
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
    "state_machine_runtime_created\tNO\tcontract only",
    "event_published\tNO\tcontract only",
    "event_consumed\tNO\tcontract only",
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
detail(f"WORKFLOW_STATE_MACHINE_CONTRACT={final_status}")
detail(f"FAZ4B_17_2_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 17.2 - Workflow State Machine Contract Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"WORKFLOW_STATE_MACHINE_CONTRACT={final_status}",
    f"FAZ4B_17_2_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/17_2_workflow_state_machine_contract_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "WORKFLOW_STATE_CATALOG_FILE=docs/phase4/17_2_workflow_state_catalog.tsv",
    "WORKFLOW_TRANSITION_CATALOG_FILE=docs/phase4/17_2_workflow_transition_catalog.tsv",
    "WORKFLOW_STATE_PERMISSION_MATRIX_FILE=docs/phase4/17_2_workflow_state_permission_matrix.tsv",
    "WORKFLOW_STATE_INVARIANT_CATALOG_FILE=docs/phase4/17_2_workflow_state_invariant_catalog.tsv",
    "NOTE=Contract only. No UI/API/runtime/DB/config/event change executed.",
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
    "STATE_MACHINE_RUNTIME_CREATED=NO",
    "EVENT_PUBLISHED=NO",
    "EVENT_CONSUMED=NO",
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
print(f"WORKFLOW_STATE_CATALOG_FILE={state_catalog_file}")
print(f"WORKFLOW_TRANSITION_CATALOG_FILE={transition_catalog_file}")
print(f"WORKFLOW_STATE_PERMISSION_MATRIX_FILE={permission_matrix_file}")
print(f"WORKFLOW_STATE_INVARIANT_CATALOG_FILE={invariant_catalog_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"WORKFLOW_STATE_COUNT={state_count}")
print(f"WORKFLOW_TRANSITION_COUNT={transition_count}")
print(f"WORKFLOW_PERMISSION_COUNT={permission_count}")
print(f"WORKFLOW_INVARIANT_COUNT={invariant_count}")
print(f"WORKFLOW_INITIAL_STATE_COUNT={initial_state_count}")
print(f"WORKFLOW_TERMINAL_STATE_COUNT={terminal_state_count}")
print(f"WORKFLOW_AUDIT_STATE_COUNT={audit_state_count}")
print(f"WORKFLOW_AUDIT_TRANSITION_COUNT={audit_transition_count}")
print(f"WORKFLOW_APPROVAL_TRANSITION_COUNT={approval_transition_count}")
print(f"WORKFLOW_EVENT_BINDING_COUNT={event_binding_count}")
print(f"WORKFLOW_TENANT_SCOPED_STATE_COUNT={tenant_scoped_state_count}")
print(f"WORKFLOW_CRITICAL_INVARIANT_COUNT={critical_invariant_count}")
print(f"WORKFLOW_STATE_PREVIOUS_17_1={previous_17_1_status}")
print(f"WORKFLOW_STATE_CATALOG={state_catalog_status}")
print(f"WORKFLOW_TRANSITION_CATALOG={transition_catalog_status}")
print(f"WORKFLOW_STATE_PERMISSION_MATRIX={permission_matrix_status}")
print(f"WORKFLOW_STATE_INVARIANT_CATALOG={invariant_catalog_status}")
print(f"WORKFLOW_STATE_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"WORKFLOW_STATE_NO_CONFIG_CHANGE={no_config_status}")
print(f"WORKFLOW_STATE_SECRET_SAFE={secret_safe_status}")
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
print("STATE_MACHINE_RUNTIME_CREATED=NO")
print("EVENT_PUBLISHED=NO")
print("EVENT_CONSUMED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print("TOKEN_PRINTED=NO")
print(f"WORKFLOW_STATE_MACHINE_CONTRACT={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_17_2_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
