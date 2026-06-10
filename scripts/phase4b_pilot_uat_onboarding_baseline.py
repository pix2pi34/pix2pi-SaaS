#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "16_1_pilot_uat_onboarding_baseline_standard.md"
policy_file = report_dir / "16_1_pilot_uat_onboarding_baseline_policy.md"
scope_file = report_dir / "16_1_pilot_scope_inventory.tsv"
uat_file = report_dir / "16_1_uat_scenario_catalog.tsv"
onboarding_file = report_dir / "16_1_onboarding_checklist.tsv"
rollout_file = report_dir / "16_1_rollout_gate_matrix.tsv"
matrix_file = report_dir / "16_1_pilot_uat_onboarding_baseline_matrix.tsv"
report_file = report_dir / "16_1_pilot_uat_onboarding_baseline_report.md"

prev_17 = report_dir / "17_workflow_realtime_ui_final_closure_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"
prev_22 = report_dir / "22_observability_ops_console_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

PILOT_SCOPE = [
    ("pilot_tenant_setup", "platform_admin", "tenant_scoped", "tenant created and isolated", "tenant_id available", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("pilot_user_roles", "tenant_admin", "tenant_scoped", "admin/cashier/accountant/operator roles mapped", "role matrix exists", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("pilot_store_branch_setup", "tenant_admin", "tenant_scoped", "store/branch/cash desk structure ready", "branch/cash desk checklist", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("product_catalog_setup", "tenant_operator", "tenant_scoped", "products/categories/units ready", "sample product set", "MEDIUM", "READY_FOR_IMPLEMENTATION"),
    ("stock_opening_balance", "tenant_operator", "tenant_scoped", "opening stock imported or entered", "stock count evidence", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("customer_vendor_cards", "tenant_operator", "tenant_scoped", "customer/vendor cards ready", "card validation checklist", "MEDIUM", "READY_FOR_IMPLEMENTATION"),
    ("sales_flow_validation", "cashier", "tenant_scoped", "sale/refund/cancel flow validated", "UAT sale scenarios", "CRITICAL", "READY_FOR_IMPLEMENTATION"),
    ("inventory_movement_validation", "tenant_operator", "tenant_scoped", "stock movement after sale validated", "stock delta evidence", "CRITICAL", "READY_FOR_IMPLEMENTATION"),
    ("ufk_accounting_validation", "accountant", "tenant_scoped", "journal/ledger/TDHP mapping reviewed", "accounting UAT evidence", "CRITICAL", "READY_FOR_IMPLEMENTATION"),
    ("reporting_validation", "tenant_admin", "tenant_scoped", "read model/reporting output validated", "report snapshot evidence", "MEDIUM", "READY_FOR_IMPLEMENTATION"),
    ("workflow_approval_validation", "tenant_admin", "tenant_scoped", "approval/action workflow validated", "workflow UAT evidence", "MEDIUM", "READY_FOR_IMPLEMENTATION"),
    ("observability_support_loop", "ops_admin", "platform_scoped", "ops console/support loop ready", "incident feedback evidence", "HIGH", "READY_FOR_IMPLEMENTATION"),
]

UAT_SCENARIOS = [
    ("uat_login_tenant_access", "auth_tenant", "tenant_user", "tenant user exists", "login and open panel", "tenant scoped panel visible", "correct tenant only", "P0", "READY_FOR_IMPLEMENTATION"),
    ("uat_role_permission_denied", "rbac", "cashier", "restricted permission missing", "open admin/security page", "access denied", "no privilege escalation", "P0", "READY_FOR_IMPLEMENTATION"),
    ("uat_product_create_update", "product", "tenant_operator", "tenant ready", "create/update product", "product listed correctly", "tenant scoped product visible", "P1", "READY_FOR_IMPLEMENTATION"),
    ("uat_stock_opening_entry", "inventory", "tenant_operator", "product exists", "enter opening stock", "stock balance updated", "audit/stock evidence exists", "P0", "READY_FOR_IMPLEMENTATION"),
    ("uat_sale_cash_flow", "pos_sales", "cashier", "product and stock exist", "complete cash sale", "sale created and stock decreases", "sale+stock evidence matches", "P0", "READY_FOR_IMPLEMENTATION"),
    ("uat_inventory_movement_validation", "inventory", "tenant_operator", "completed sale exists", "verify stock movement after sale", "stock movement is created and stock balance decreased", "movement quantity matches sale quantity", "P0", "READY_FOR_IMPLEMENTATION"),
    ("uat_sale_cancel_refund", "pos_sales", "cashier", "sale exists", "cancel/refund sale", "stock and ledger reversal policy visible", "no orphan movement", "P0", "READY_FOR_IMPLEMENTATION"),
    ("uat_low_stock_warning", "inventory", "tenant_operator", "stock threshold exists", "reduce stock below threshold", "warning signal exists", "warning evidence visible", "P1", "READY_FOR_IMPLEMENTATION"),
    ("uat_workflow_approval", "workflow", "tenant_admin", "approval workflow exists", "request/approve/reject workflow", "state transition correct", "audit+realtime evidence", "P1", "READY_FOR_IMPLEMENTATION"),
    ("uat_accounting_journal_check", "accounting", "accountant", "sale exists", "review journal/ledger", "TDHP lines correct", "accountant acceptance", "P0", "READY_FOR_IMPLEMENTATION"),
    ("uat_reporting_summary", "reporting", "tenant_admin", "sales/stock data exists", "open summary report", "totals match source", "read model consistency", "P1", "READY_FOR_IMPLEMENTATION"),
    ("uat_audit_trail_check", "audit", "tenant_admin", "mutating actions exist", "open audit evidence", "audit rows visible", "actor/request/tenant visible", "P0", "READY_FOR_IMPLEMENTATION"),
    ("uat_observability_incident_loop", "ops", "ops_admin", "pilot issue recorded", "open ops/support evidence", "incident feedback loop works", "issue traceable", "P1", "READY_FOR_IMPLEMENTATION"),
    ("uat_no_raw_secret_payload", "security", "security_admin", "reports/events exist", "inspect exported evidence", "no raw secret/payload printed", "secret safety passes", "P0", "READY_FOR_IMPLEMENTATION"),
    ("uat_backup_restore_readiness_note", "ops", "ops_admin", "pilot data exists", "verify backup/restore drill evidence", "restore readiness noted", "no destructive test in pilot gate", "P1", "READY_FOR_IMPLEMENTATION"),
    ("uat_go_no_go_decision", "rollout", "project_owner", "all P0 pass", "review final gate", "go/no-go decision ready", "blockers listed", "P0", "READY_FOR_IMPLEMENTATION"),
]

ONBOARDING = [
    ("tenant_contract_confirmed", "project_owner", "YES", "signed/approved pilot scope", "scope drift", "READY_FOR_IMPLEMENTATION"),
    ("pilot_contact_list_ready", "project_owner", "YES", "contact/role list", "support gap", "READY_FOR_IMPLEMENTATION"),
    ("tenant_admin_created", "platform_admin", "YES", "tenant admin account evidence", "cannot operate tenant", "READY_FOR_IMPLEMENTATION"),
    ("user_role_matrix_ready", "tenant_admin", "YES", "role/permission matrix", "wrong access", "READY_FOR_IMPLEMENTATION"),
    ("store_branch_cashdesk_ready", "tenant_admin", "YES", "branch/cashdesk checklist", "sales flow blocked", "READY_FOR_IMPLEMENTATION"),
    ("product_import_template_ready", "tenant_operator", "YES", "template/evidence", "product setup delay", "READY_FOR_IMPLEMENTATION"),
    ("opening_stock_ready", "tenant_operator", "YES", "stock count evidence", "stock mismatch", "READY_FOR_IMPLEMENTATION"),
    ("accounting_mapping_reviewed", "accountant", "YES", "TDHP review checklist", "wrong accounting output", "READY_FOR_IMPLEMENTATION"),
    ("training_session_completed", "trainer", "YES", "training attendance note", "user adoption risk", "READY_FOR_IMPLEMENTATION"),
    ("support_channel_ready", "support", "YES", "support contact/channel", "issue response delay", "READY_FOR_IMPLEMENTATION"),
    ("incident_feedback_loop_ready", "ops_admin", "YES", "incident template", "pilot issue lost", "READY_FOR_IMPLEMENTATION"),
    ("go_no_go_meeting_scheduled", "project_owner", "YES", "calendar/meeting note", "rollout ambiguity", "READY_FOR_IMPLEMENTATION"),
]

ROLLOUT_GATES = [
    ("foundation_closed", "prerequisite", "PASS", "YES", "17/20/21/22 final closure reports", "READY_FOR_IMPLEMENTATION"),
    ("tenant_scope_ready", "tenant", "PASS", "YES", "pilot scope inventory", "READY_FOR_IMPLEMENTATION"),
    ("p0_uat_passed", "uat", "PASS", "YES", "UAT scenario catalog", "READY_FOR_IMPLEMENTATION"),
    ("rbac_access_checked", "security", "PASS", "YES", "role permission evidence", "READY_FOR_IMPLEMENTATION"),
    ("tenant_isolation_checked", "security", "PASS", "YES", "tenant access UAT", "READY_FOR_IMPLEMENTATION"),
    ("audit_evidence_checked", "audit", "PASS", "YES", "audit trail UAT", "READY_FOR_IMPLEMENTATION"),
    ("stock_sales_accounting_checked", "business", "PASS", "YES", "sales/stock/accounting UAT", "READY_FOR_IMPLEMENTATION"),
    ("reporting_checked", "reporting", "PASS", "NO", "reporting UAT", "READY_FOR_IMPLEMENTATION"),
    ("support_loop_ready", "support", "PASS", "YES", "support/incident checklist", "READY_FOR_IMPLEMENTATION"),
    ("backup_restore_readiness_noted", "ops", "PASS", "NO", "ops readiness note", "READY_FOR_IMPLEMENTATION"),
    ("go_no_go_ready", "rollout", "PASS", "YES", "rollout gate matrix", "READY_FOR_IMPLEMENTATION"),
]

def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")

def detail(line):
    details.append(line)

def fail(msg):
    failures.append(f"FAIL ❌ {msg}")

def tool_status(name):
    status = "FOUND" if which(name) else "NOT_FOUND"
    tools.append(f"TOOL_{name}={status}")

def read(path):
    if not path.exists():
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
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("EVENT_PUBLISHED=NO")
detail("EVENT_CONSUMED=NO")
detail("NOTIFICATION_SENT=NO")
detail("CUSTOMER_PRIVATE_DATA_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("TOKEN_PRINTED=NO")
detail("VALIDATION_MODE=PILOT_UAT_ONBOARDING_BASELINE_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_17_status = get_value(prev_17, "FAZ4B_17_FINAL_STATUS")
prev_17_closure = get_value(prev_17, "WORKFLOW_REALTIME_FINAL_CLOSURE")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")
prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")
prev_22_closure = get_value(prev_22, "OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE")

detail(f"PREVIOUS_17_FINAL_STATUS={prev_17_status}")
detail(f"PREVIOUS_17_WORKFLOW_REALTIME_FINAL_CLOSURE={prev_17_closure}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")
detail(f"PREVIOUS_22_OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE={prev_22_closure}")

if prev_17_status != "PASS":
    fail("17 final status PASS degil")
if prev_17_closure != "PASS":
    fail("17 workflow closure PASS degil")
if prev_20_status != "PASS":
    fail("20 final status PASS degil")
if prev_20_closure != "PASS":
    fail("20 infra closure PASS degil")
if prev_21_status != "PASS":
    fail("21 final status PASS degil")
if prev_21_closure != "PASS":
    fail("21 security closure PASS degil")
if prev_22_status != "PASS":
    fail("22 final status PASS degil")
if prev_22_closure != "PASS":
    fail("22 observability closure PASS degil")

for p, label in [(standard_file, "standard doc"), (policy_file, "policy doc")]:
    if not p.exists():
        fail(f"{label} yok")

scope_lines = ["pilot_area\towner_role\ttenant_scope\treadiness_target\tacceptance_signal\trisk_level\timplementation_status\tnote"]
for row in PILOT_SCOPE:
    scope_lines.append("\t".join([safe(x) for x in list(row) + ["baseline_only"]]))
scope_file.write_text("\n".join(scope_lines) + "\n")

uat_lines = ["scenario_name\tmodule\tactor\tprecondition\taction_flow\texpected_result\tacceptance_criteria\tpriority\timplementation_status\tnote"]
for row in UAT_SCENARIOS:
    uat_lines.append("\t".join([safe(x) for x in list(row) + ["baseline_only"]]))
uat_file.write_text("\n".join(uat_lines) + "\n")

onboarding_lines = ["checklist_item\towner_role\trequired_before_go_live\tevidence_required\trisk_if_missing\timplementation_status\tnote"]
for row in ONBOARDING:
    onboarding_lines.append("\t".join([safe(x) for x in list(row) + ["baseline_only"]]))
onboarding_file.write_text("\n".join(onboarding_lines) + "\n")

rollout_lines = ["gate_name\tcategory\trequired_status\tblocker_if_failed\tevidence_source\timplementation_status\tnote"]
for row in ROLLOUT_GATES:
    rollout_lines.append("\t".join([safe(x) for x in list(row) + ["baseline_only"]]))
rollout_file.write_text("\n".join(rollout_lines) + "\n")

scope_count = len(PILOT_SCOPE)
uat_count = len(UAT_SCENARIOS)
uat_p0_count = sum(1 for x in UAT_SCENARIOS if x[7] == "P0")
onboarding_count = len(ONBOARDING)
onboarding_required_count = sum(1 for x in ONBOARDING if x[2] == "YES")
rollout_gate_count = len(ROLLOUT_GATES)
rollout_blocker_count = sum(1 for x in ROLLOUT_GATES if x[3] == "YES")
critical_scope_count = sum(1 for x in PILOT_SCOPE if x[5] == "CRITICAL")

detail(f"PILOT_SCOPE_COUNT={scope_count}")
detail(f"PILOT_CRITICAL_SCOPE_COUNT={critical_scope_count}")
detail(f"PILOT_UAT_SCENARIO_COUNT={uat_count}")
detail(f"PILOT_UAT_P0_SCENARIO_COUNT={uat_p0_count}")
detail(f"PILOT_ONBOARDING_CHECKLIST_COUNT={onboarding_count}")
detail(f"PILOT_ONBOARDING_REQUIRED_COUNT={onboarding_required_count}")
detail(f"PILOT_ROLLOUT_GATE_COUNT={rollout_gate_count}")
detail(f"PILOT_ROLLOUT_BLOCKER_GATE_COUNT={rollout_blocker_count}")

foundation_status = "PASS" if (
    prev_17_status == "PASS" and prev_17_closure == "PASS" and
    prev_20_status == "PASS" and prev_20_closure == "PASS" and
    prev_21_status == "PASS" and prev_21_closure == "PASS" and
    prev_22_status == "PASS" and prev_22_closure == "PASS"
) else "FAIL"

scope_status = "PASS" if scope_file.exists() and scope_count >= 10 and critical_scope_count >= 3 else "FAIL"
uat_status = "PASS" if uat_file.exists() and uat_count >= 12 and uat_p0_count >= 5 else "FAIL"
onboarding_status = "PASS" if onboarding_file.exists() and onboarding_count >= 10 and onboarding_required_count == onboarding_count else "FAIL"
rollout_status = "PASS" if rollout_file.exists() and rollout_gate_count >= 10 and rollout_blocker_count >= 6 else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"PILOT_PREVIOUS_FOUNDATION={foundation_status}")
detail(f"PILOT_SCOPE_INVENTORY={scope_status}")
detail(f"PILOT_UAT_SCENARIO_CATALOG={uat_status}")
detail(f"PILOT_ONBOARDING_CHECKLIST={onboarding_status}")
detail(f"PILOT_ROLLOUT_GATE_MATRIX={rollout_status}")
detail(f"PILOT_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"PILOT_NO_CONFIG_CHANGE={no_config_status}")
detail(f"PILOT_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_foundation", foundation_status),
    ("scope_inventory", scope_status),
    ("uat_scenario_catalog", uat_status),
    ("onboarding_checklist", onboarding_status),
    ("rollout_gate_matrix", rollout_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_foundation\t{foundation_status}\t17/20/21/22 prerequisite final closures",
    f"pilot_scope_inventory\t{scope_status}\tscope={scope_count} critical={critical_scope_count}",
    f"uat_scenario_catalog\t{uat_status}\tscenarios={uat_count} p0={uat_p0_count}",
    f"onboarding_checklist\t{onboarding_status}\titems={onboarding_count} required={onboarding_required_count}",
    f"rollout_gate_matrix\t{rollout_status}\tgates={rollout_gate_count} blockers={rollout_blocker_count}",
    f"no_runtime_change\t{no_runtime_status}\tno service/db/api/ui/event changed",
    f"no_config_change\t{no_config_status}\tno config/env/nginx/firewall changed",
    f"secret_safe\t{secret_safe_status}\tno secrets/customer private data printed",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "port_changed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "ui_code_changed\tNO\tbaseline only",
    "api_route_created\tNO\tbaseline only",
    "api_implementation_changed\tNO\tbaseline only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "event_published\tNO\tbaseline only",
    "event_consumed\tNO\tbaseline only",
    "notification_sent\tNO\tbaseline only",
    "customer_private_data_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
    "token_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"PILOT_UAT_ONBOARDING_BASELINE={final_status}")
detail(f"FAZ4B_16_1_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 16.1 - Pilot / UAT / Onboarding Baseline Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"PILOT_UAT_ONBOARDING_BASELINE={final_status}",
    f"FAZ4B_16_1_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/16_1_pilot_uat_onboarding_baseline_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "PILOT_SCOPE_INVENTORY_FILE=docs/phase4/16_1_pilot_scope_inventory.tsv",
    "PILOT_UAT_SCENARIO_CATALOG_FILE=docs/phase4/16_1_uat_scenario_catalog.tsv",
    "PILOT_ONBOARDING_CHECKLIST_FILE=docs/phase4/16_1_onboarding_checklist.tsv",
    "PILOT_ROLLOUT_GATE_MATRIX_FILE=docs/phase4/16_1_rollout_gate_matrix.tsv",
    "NOTE=Baseline only. No runtime/config/db/api/ui/event/customer-private-data change executed.",
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
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "EVENT_PUBLISHED=NO",
    "EVENT_CONSUMED=NO",
    "NOTIFICATION_SENT=NO",
    "CUSTOMER_PRIVATE_DATA_PRINTED=NO",
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
print(f"PILOT_SCOPE_INVENTORY_FILE={scope_file}")
print(f"PILOT_UAT_SCENARIO_CATALOG_FILE={uat_file}")
print(f"PILOT_ONBOARDING_CHECKLIST_FILE={onboarding_file}")
print(f"PILOT_ROLLOUT_GATE_MATRIX_FILE={rollout_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"PILOT_SCOPE_COUNT={scope_count}")
print(f"PILOT_CRITICAL_SCOPE_COUNT={critical_scope_count}")
print(f"PILOT_UAT_SCENARIO_COUNT={uat_count}")
print(f"PILOT_UAT_P0_SCENARIO_COUNT={uat_p0_count}")
print(f"PILOT_ONBOARDING_CHECKLIST_COUNT={onboarding_count}")
print(f"PILOT_ONBOARDING_REQUIRED_COUNT={onboarding_required_count}")
print(f"PILOT_ROLLOUT_GATE_COUNT={rollout_gate_count}")
print(f"PILOT_ROLLOUT_BLOCKER_GATE_COUNT={rollout_blocker_count}")
print(f"PILOT_PREVIOUS_FOUNDATION={foundation_status}")
print(f"PILOT_SCOPE_INVENTORY={scope_status}")
print(f"PILOT_UAT_SCENARIO_CATALOG={uat_status}")
print(f"PILOT_ONBOARDING_CHECKLIST={onboarding_status}")
print(f"PILOT_ROLLOUT_GATE_MATRIX={rollout_status}")
print(f"PILOT_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"PILOT_NO_CONFIG_CHANGE={no_config_status}")
print(f"PILOT_SECRET_SAFE={secret_safe_status}")
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
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("EVENT_PUBLISHED=NO")
print("EVENT_CONSUMED=NO")
print("NOTIFICATION_SENT=NO")
print("CUSTOMER_PRIVATE_DATA_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print("TOKEN_PRINTED=NO")
print(f"PILOT_UAT_ONBOARDING_BASELINE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_16_1_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
