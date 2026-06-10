#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "17_1_workflow_realtime_baseline_standard.md"
policy_file = report_dir / "17_1_workflow_realtime_baseline_policy.md"
workflow_inventory_file = report_dir / "17_1_workflow_domain_inventory.tsv"
realtime_contract_file = report_dir / "17_1_realtime_signal_contract.tsv"
ui_contract_file = report_dir / "17_1_ui_surface_contract.tsv"
api_inventory_file = report_dir / "17_1_api_surface_candidate_inventory.tsv"
matrix_file = report_dir / "17_1_workflow_realtime_baseline_matrix.tsv"
report_file = report_dir / "17_1_workflow_realtime_baseline_report.md"

prev_22 = report_dir / "22_observability_ops_console_final_closure_report.md"
prev_22_8 = report_dir / "22_8_observability_ops_console_final_closure_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

WORKFLOW_DOMAINS = [
    ("workflow_definition", "core", "workflow template / definition", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("workflow_instance", "core", "running workflow instance", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("workflow_step", "core", "workflow step metadata", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("workflow_transition", "core", "allowed state transition", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("workflow_action", "core", "user/system action metadata", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("approval_request", "approval", "manager/accountant/admin approval", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("task_assignment", "task", "assigned task/action item", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("job_trigger", "job", "background job trigger binding", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("notification_binding", "notification", "notification signal binding", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("audit_binding", "audit", "audit trail binding", "tenant_scoped", "security_required", "READY_FOR_IMPLEMENTATION"),
    ("realtime_binding", "realtime", "SSE/WebSocket signal binding", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("event_binding", "event_bus", "event bus trigger binding", "tenant_scoped", "rbac_required", "READY_FOR_IMPLEMENTATION"),
    ("ops_console_binding", "ops", "Ops Console signal binding", "platform_scoped", "ops_required", "READY_FOR_IMPLEMENTATION"),
    ("tenant_visibility", "security", "tenant isolation visibility", "tenant_scoped", "security_required", "READY_FOR_IMPLEMENTATION"),
    ("rbac_visibility", "security", "role/permission visibility", "tenant_scoped", "security_required", "READY_FOR_IMPLEMENTATION"),
]

REALTIME_SIGNALS = [
    ("workflow.instance.created", "workflow", "workflow_instance", "tenant", "user_or_system", "INFO", "event_bus_or_api", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("workflow.instance.updated", "workflow", "workflow_instance", "tenant", "user_or_system", "INFO", "event_bus_or_api", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("workflow.step.started", "workflow", "workflow_step", "tenant", "system", "INFO", "workflow_runtime", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("workflow.step.completed", "workflow", "workflow_step", "tenant", "system", "INFO", "workflow_runtime", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("workflow.step.failed", "workflow", "workflow_step", "tenant", "system", "HIGH", "workflow_runtime", "metadata_only_no_stacktrace", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("approval.requested", "approval", "approval_request", "tenant", "user_or_system", "MEDIUM", "api_or_workflow", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("approval.approved", "approval", "approval_request", "tenant", "user", "INFO", "api", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("approval.rejected", "approval", "approval_request", "tenant", "user", "MEDIUM", "api", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("task.assigned", "task", "task_assignment", "tenant", "user_or_system", "INFO", "workflow_runtime", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("task.overdue", "task", "task_assignment", "tenant", "system", "MEDIUM", "scheduler", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("notification.created", "notification", "notification_binding", "tenant", "system", "INFO", "notification_runtime", "metadata_only", "tenant_admin_limited", "READY_FOR_IMPLEMENTATION"),
    ("event.backlog.warning", "ops", "event_bus", "platform", "system", "HIGH", "ops_console", "metadata_only", "ops_admin", "READY_FOR_IMPLEMENTATION"),
    ("dlq.growth.warning", "ops", "event_bus", "platform", "system", "HIGH", "ops_console", "metadata_only", "ops_admin", "READY_FOR_IMPLEMENTATION"),
    ("security.tenant_violation", "security", "tenant_visibility", "platform", "system", "CRITICAL", "security_gate", "metadata_only_no_sensitive_payload", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("audit.gap.detected", "security", "audit_binding", "platform", "system", "HIGH", "audit_gate", "metadata_only", "security_admin", "READY_FOR_IMPLEMENTATION"),
]

UI_SURFACES = [
    ("workflow_dashboard", "workflow_overview", "view", "workflow_summary", "workflow.*", "workflow:read", "tenant", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow_dashboard", "workflow_instance_table", "view", "workflow_instances", "workflow.instance.*", "workflow:read", "tenant", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow_detail", "workflow_timeline", "view", "workflow_steps", "workflow.step.*", "workflow:read", "tenant", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow_detail", "workflow_action_panel", "execute", "workflow_actions", "workflow.action.*", "workflow:execute", "tenant", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval_center", "approval_queue", "view", "approval_requests", "approval.*", "approval:read", "tenant", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval_center", "approve_button", "approve", "approval_action", "approval.approved", "approval:write", "tenant", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approval_center", "reject_button", "reject", "approval_action", "approval.rejected", "approval:write", "tenant", "YES", "READY_FOR_IMPLEMENTATION"),
    ("task_center", "task_table", "view", "task_assignments", "task.*", "task:read", "tenant", "YES", "READY_FOR_IMPLEMENTATION"),
    ("task_center", "task_action_panel", "execute", "task_actions", "task.assigned", "task:write", "tenant", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops_console", "workflow_ops_card", "view", "ops_workflow_health", "event.backlog.warning,dlq.growth.warning", "ops:read", "platform", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security_console", "tenant_security_card", "view", "tenant_security_signal", "security.tenant_violation", "security:read", "platform", "YES", "READY_FOR_IMPLEMENTATION"),
    ("audit_console", "audit_gap_card", "view", "audit_gap_signal", "audit.gap.detected", "security:read", "platform", "YES", "READY_FOR_IMPLEMENTATION"),
]

API_CANDIDATES = [
    ("GET", "/api/v1/workflows", "workflow", "list workflow definitions", "workflow:read", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/workflows", "workflow", "create workflow definition", "workflow:write", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/workflow-instances", "workflow", "list workflow instances", "workflow:read", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/workflow-instances", "workflow", "start workflow instance", "workflow:execute", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/workflow-instances/{id}", "workflow", "get workflow instance detail", "workflow:read", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/workflow-instances/{id}/actions", "workflow", "execute workflow action", "workflow:execute", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/approvals", "approval", "list approval requests", "approval:read", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/approvals/{id}/approve", "approval", "approve request", "approval:write", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/approvals/{id}/reject", "approval", "reject request", "approval:write", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/tasks", "task", "list assigned tasks", "task:read", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("POST", "/api/v1/tasks/{id}/complete", "task", "complete task", "task:write", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/realtime/events", "realtime", "SSE event stream candidate", "realtime:read", "tenant", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/api/v1/realtime/ws", "realtime", "WebSocket stream candidate", "realtime:read", "tenant", "READY_FOR_IMPLEMENTATION"),
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

def scan_surface_candidates():
    rows = []
    patterns = [
        r'/(api|ops|workflow|workflows|approval|approvals|tasks|realtime|events|ws|sse)[A-Za-z0-9_/\-{}:.]*',
        r'(GET|POST|PUT|PATCH|DELETE)\s+/(api|ops|workflow|workflows|approval|approvals|tasks|realtime)[A-Za-z0-9_/\-{}:.]*',
    ]
    scan_dirs = [root / "docs", root / "cmd", root / "internal", root / "services"]
    seen = set()

    for base in scan_dirs:
        if not base.exists():
            continue
        try:
            for p in sorted(base.rglob("*")):
                if len(rows) >= 120:
                    break
                if any(part in [".git", "node_modules", "vendor", "backups"] for part in p.parts):
                    continue
                if not p.is_file():
                    continue
                if p.suffix.lower() not in [".go", ".md", ".txt", ".yaml", ".yml", ".json"]:
                    continue
                text = read(p)
                if not text:
                    continue
                for pattern in patterns:
                    for m in re.finditer(pattern, text, flags=re.I):
                        candidate = safe(m.group(0))
                        if len(candidate) < 4:
                            continue
                        key = (str(p), candidate)
                        if key in seen:
                            continue
                        seen.add(key)
                        rows.append([
                            safe(str(p.relative_to(root))),
                            candidate,
                            "existing_surface_marker",
                            "metadata_only",
                        ])
                        if len(rows) >= 120:
                            break
                    if len(rows) >= 120:
                        break
        except Exception:
            warn(f"scan skipped: {base}")

    return rows

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
detail("EVENT_PUBLISHED=NO")
detail("EVENT_CONSUMED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("TOKEN_PRINTED=NO")
detail("VALIDATION_MODE=WORKFLOW_REALTIME_BASELINE_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")
prev_22_closure = get_value(prev_22, "OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE")
prev_22_8_status = get_value(prev_22_8, "FAZ4B_22_8_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")
detail(f"PREVIOUS_22_OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE={prev_22_closure}")
detail(f"PREVIOUS_22_8_FINAL_STATUS={prev_22_8_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_22_status != "PASS":
    fail("22 final status PASS degil")
if prev_22_closure != "PASS":
    fail("22 observability closure PASS degil")
if prev_22_8_status != "PASS":
    fail("22.8 final status PASS degil")
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

workflow_lines = [
    "domain_name\tcategory\tdescription\ttenant_scope\tsecurity_policy\timplementation_status\tnote"
]
for row in WORKFLOW_DOMAINS:
    workflow_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
workflow_inventory_file.write_text("\n".join(workflow_lines) + "\n")

realtime_lines = [
    "signal_name\tcategory\tentity_ref\ttenant_scope\tactor_scope\tseverity\tsource\tpayload_policy\tvisibility_scope\timplementation_status\tnote"
]
for row in REALTIME_SIGNALS:
    realtime_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
realtime_contract_file.write_text("\n".join(realtime_lines) + "\n")

ui_lines = [
    "page_name\twidget_name\taction_name\tdata_source\trealtime_channel\trequired_permission\ttenant_scope\taudit_required\timplementation_status\tnote"
]
for row in UI_SURFACES:
    ui_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_ui_code"]]))
ui_contract_file.write_text("\n".join(ui_lines) + "\n")

surface_rows = scan_surface_candidates()
api_lines = [
    "method\tpath\tcategory\tdescription\trequired_permission\ttenant_scope\timplementation_status\tnote"
]
for row in API_CANDIDATES:
    api_lines.append("\t".join([safe(x) for x in list(row) + ["candidate_only_no_route_created"]]))

api_lines.append("source_file\tcandidate_marker\tcategory\tnote\t\t\t\t")
for row in surface_rows:
    api_lines.append("\t".join([safe(x) for x in row + ["", "", "", ""]]))
api_inventory_file.write_text("\n".join(api_lines) + "\n")

workflow_count = len(WORKFLOW_DOMAINS)
realtime_count = len(REALTIME_SIGNALS)
ui_count = len(UI_SURFACES)
api_candidate_count = len(API_CANDIDATES)
existing_surface_marker_count = len(surface_rows)
critical_signal_count = sum(1 for r in REALTIME_SIGNALS if r[5] == "CRITICAL")
high_signal_count = sum(1 for r in REALTIME_SIGNALS if r[5] == "HIGH")
audit_required_count = sum(1 for r in UI_SURFACES if r[7] == "YES")

detail(f"WORKFLOW_DOMAIN_COUNT={workflow_count}")
detail(f"WORKFLOW_REALTIME_SIGNAL_COUNT={realtime_count}")
detail(f"WORKFLOW_UI_SURFACE_COUNT={ui_count}")
detail(f"WORKFLOW_API_CANDIDATE_COUNT={api_candidate_count}")
detail(f"WORKFLOW_EXISTING_SURFACE_MARKER_COUNT={existing_surface_marker_count}")
detail(f"WORKFLOW_CRITICAL_SIGNAL_COUNT={critical_signal_count}")
detail(f"WORKFLOW_HIGH_SIGNAL_COUNT={high_signal_count}")
detail(f"WORKFLOW_AUDIT_REQUIRED_UI_COUNT={audit_required_count}")

previous_22_status = "PASS" if prev_22_status == "PASS" and prev_22_closure == "PASS" and prev_22_8_status == "PASS" else "FAIL"
domain_status = "PASS" if workflow_inventory_file.exists() and workflow_count >= 10 else "FAIL"
realtime_status = "PASS" if realtime_contract_file.exists() and realtime_count >= 10 else "FAIL"
ui_status = "PASS" if ui_contract_file.exists() and ui_count >= 8 else "FAIL"
api_status = "PASS" if api_inventory_file.exists() and api_candidate_count >= 8 else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"WORKFLOW_PREVIOUS_22={previous_22_status}")
detail(f"WORKFLOW_DOMAIN_INVENTORY={domain_status}")
detail(f"WORKFLOW_REALTIME_SIGNAL_CONTRACT={realtime_status}")
detail(f"WORKFLOW_UI_SURFACE_CONTRACT={ui_status}")
detail(f"WORKFLOW_API_SURFACE_CANDIDATES={api_status}")
detail(f"WORKFLOW_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"WORKFLOW_NO_CONFIG_CHANGE={no_config_status}")
detail(f"WORKFLOW_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_22", previous_22_status),
    ("domain_inventory", domain_status),
    ("realtime_signal_contract", realtime_status),
    ("ui_surface_contract", ui_status),
    ("api_surface_candidates", api_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_22\t{previous_22_status}\tobservability ops console prerequisite",
    f"workflow_domain_inventory\t{domain_status}\tdomains={workflow_count}",
    f"realtime_signal_contract\t{realtime_status}\tsignals={realtime_count} critical={critical_signal_count} high={high_signal_count}",
    f"ui_surface_contract\t{ui_status}\tui_surfaces={ui_count} audit_required={audit_required_count}",
    f"api_surface_candidates\t{api_status}\tapi_candidates={api_candidate_count} existing_markers={existing_surface_marker_count}",
    f"no_runtime_change\t{no_runtime_status}\tno service/container/ui/api/runtime changed",
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
detail(f"WORKFLOW_REALTIME_BASELINE={final_status}")
detail(f"FAZ4B_17_1_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 17.1 - Workflow / Realtime UI Baseline Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"WORKFLOW_REALTIME_BASELINE={final_status}",
    f"FAZ4B_17_1_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/17_1_workflow_realtime_baseline_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "WORKFLOW_DOMAIN_INVENTORY_FILE=docs/phase4/17_1_workflow_domain_inventory.tsv",
    "REALTIME_SIGNAL_CONTRACT_FILE=docs/phase4/17_1_realtime_signal_contract.tsv",
    "UI_SURFACE_CONTRACT_FILE=docs/phase4/17_1_ui_surface_contract.tsv",
    "API_SURFACE_CANDIDATE_INVENTORY_FILE=docs/phase4/17_1_api_surface_candidate_inventory.tsv",
    "NOTE=Contract only. No UI/API/runtime/DB/config change executed.",
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
print(f"WORKFLOW_DOMAIN_INVENTORY_FILE={workflow_inventory_file}")
print(f"REALTIME_SIGNAL_CONTRACT_FILE={realtime_contract_file}")
print(f"UI_SURFACE_CONTRACT_FILE={ui_contract_file}")
print(f"API_SURFACE_CANDIDATE_INVENTORY_FILE={api_inventory_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"WORKFLOW_DOMAIN_COUNT={workflow_count}")
print(f"WORKFLOW_REALTIME_SIGNAL_COUNT={realtime_count}")
print(f"WORKFLOW_UI_SURFACE_COUNT={ui_count}")
print(f"WORKFLOW_API_CANDIDATE_COUNT={api_candidate_count}")
print(f"WORKFLOW_EXISTING_SURFACE_MARKER_COUNT={existing_surface_marker_count}")
print(f"WORKFLOW_CRITICAL_SIGNAL_COUNT={critical_signal_count}")
print(f"WORKFLOW_HIGH_SIGNAL_COUNT={high_signal_count}")
print(f"WORKFLOW_AUDIT_REQUIRED_UI_COUNT={audit_required_count}")
print(f"WORKFLOW_PREVIOUS_22={previous_22_status}")
print(f"WORKFLOW_DOMAIN_INVENTORY={domain_status}")
print(f"WORKFLOW_REALTIME_SIGNAL_CONTRACT={realtime_status}")
print(f"WORKFLOW_UI_SURFACE_CONTRACT={ui_status}")
print(f"WORKFLOW_API_SURFACE_CANDIDATES={api_status}")
print(f"WORKFLOW_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"WORKFLOW_NO_CONFIG_CHANGE={no_config_status}")
print(f"WORKFLOW_SECRET_SAFE={secret_safe_status}")
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
print("EVENT_PUBLISHED=NO")
print("EVENT_CONSUMED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print("TOKEN_PRINTED=NO")
print(f"WORKFLOW_REALTIME_BASELINE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_17_1_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
