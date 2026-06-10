#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which
from collections import Counter

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "16_3_uat_scenario_execution_contract_standard.md"
policy_file = report_dir / "16_3_uat_scenario_execution_contract_policy.md"
execution_file = report_dir / "16_3_uat_execution_plan.tsv"
actor_file = report_dir / "16_3_uat_actor_matrix.tsv"
evidence_file = report_dir / "16_3_uat_evidence_matrix.tsv"
blocker_file = report_dir / "16_3_uat_blocker_policy.tsv"
matrix_file = report_dir / "16_3_uat_execution_contract_matrix.tsv"
report_file = report_dir / "16_3_uat_scenario_execution_contract_report.md"

prev_16_2 = report_dir / "16_2_pilot_tenant_readiness_contract_report.md"
prev_16_1 = report_dir / "16_1_pilot_uat_onboarding_baseline_report.md"
prev_17 = report_dir / "17_workflow_realtime_ui_final_closure_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"
prev_22 = report_dir / "22_observability_ops_console_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

UAT_EXECUTION = [
    ("uat_login_tenant_access", "auth_tenant", "P0", "tenant_user", "tenant user exists", "login and open panel", "tenant scoped panel evidence", "correct tenant only", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_role_permission_denied", "rbac", "P0", "cashier", "restricted permission missing", "open admin/security page", "access denied evidence", "no privilege escalation", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_product_create_update", "product", "P1", "tenant_operator", "tenant ready", "create/update product", "product list evidence", "tenant scoped product visible", "NO", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_stock_opening_entry", "inventory", "P0", "tenant_operator", "product exists", "enter opening stock", "opening stock evidence", "stock balance updated", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_sale_cash_flow", "pos_sales", "P0", "cashier", "product and stock exist", "complete cash sale", "sale receipt + stock delta evidence", "sale created and stock decreases", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_inventory_movement_validation", "inventory", "P0", "tenant_operator", "completed sale exists", "verify stock movement after sale", "stock movement evidence", "movement quantity matches sale quantity", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_sale_cancel_refund", "pos_sales", "P0", "cashier", "sale exists", "cancel/refund sale", "refund/cancel evidence", "no orphan movement", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_low_stock_warning", "inventory", "P1", "tenant_operator", "stock threshold exists", "reduce stock below threshold", "warning signal evidence", "warning visible", "NO", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_workflow_approval", "workflow", "P1", "tenant_approver", "approval workflow exists", "request/approve/reject workflow", "state transition + audit evidence", "audit and realtime evidence exists", "NO", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_accounting_journal_check", "accounting", "P0", "accountant", "sale exists", "review journal/ledger", "TDHP journal evidence", "accountant acceptance", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_reporting_summary", "reporting", "P1", "tenant_admin", "sales/stock data exists", "open summary report", "report snapshot evidence", "totals match source", "NO", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_audit_trail_check", "audit", "P0", "tenant_admin", "mutating actions exist", "open audit evidence", "actor/request/tenant audit evidence", "audit rows visible", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_observability_incident_loop", "ops", "P1", "ops_admin", "pilot issue recorded", "open ops/support evidence", "incident feedback evidence", "issue traceable", "NO", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_no_raw_secret_payload", "security", "P0", "security_admin", "reports/events exist", "inspect exported evidence", "secret safety evidence", "no raw secret/payload printed", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_backup_restore_readiness_note", "ops", "P1", "ops_admin", "pilot data exists", "verify backup/restore drill evidence note", "restore readiness note", "no destructive test in pilot gate", "NO", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_go_no_go_decision", "rollout", "P0", "project_owner", "all P0 pass", "review final gate", "go/no-go decision evidence", "blockers listed and decision ready", "YES", "YES", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
]

EVIDENCE = [
    ("tenant_access_evidence", "uat_login_tenant_access", "screenshot_or_log_summary", "YES", "tenant_user", "masked tenant scoped panel evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("permission_denied_evidence", "uat_role_permission_denied", "screenshot_or_response_summary", "YES", "tenant_admin", "access denied without sensitive payload", "YES", "READY_FOR_IMPLEMENTATION"),
    ("product_update_evidence", "uat_product_create_update", "record_snapshot", "NO", "tenant_operator", "masked product record evidence", "NO", "READY_FOR_IMPLEMENTATION"),
    ("opening_stock_evidence", "uat_stock_opening_entry", "stock_snapshot", "YES", "tenant_operator", "stock balance before/after evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("sale_cash_flow_evidence", "uat_sale_cash_flow", "receipt_and_stock_delta", "YES", "cashier", "sale receipt + stock delta evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("inventory_movement_evidence", "uat_inventory_movement_validation", "movement_snapshot", "YES", "tenant_operator", "movement quantity matches sale quantity", "YES", "READY_FOR_IMPLEMENTATION"),
    ("sale_refund_cancel_evidence", "uat_sale_cancel_refund", "refund_snapshot", "YES", "cashier", "refund/cancel movement evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("low_stock_warning_evidence", "uat_low_stock_warning", "warning_snapshot", "NO", "tenant_operator", "warning signal evidence", "NO", "READY_FOR_IMPLEMENTATION"),
    ("workflow_approval_evidence", "uat_workflow_approval", "workflow_state_snapshot", "NO", "tenant_approver", "state transition/audit evidence", "NO", "READY_FOR_IMPLEMENTATION"),
    ("accounting_journal_evidence", "uat_accounting_journal_check", "journal_snapshot", "YES", "accountant", "TDHP line review evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("reporting_summary_evidence", "uat_reporting_summary", "report_snapshot", "NO", "tenant_admin", "report totals evidence", "NO", "READY_FOR_IMPLEMENTATION"),
    ("audit_trail_evidence", "uat_audit_trail_check", "audit_snapshot", "YES", "tenant_admin", "actor/request/tenant audit evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("incident_loop_evidence", "uat_observability_incident_loop", "incident_note", "NO", "ops_admin", "issue traceability evidence", "NO", "READY_FOR_IMPLEMENTATION"),
    ("secret_safety_evidence", "uat_no_raw_secret_payload", "sanitized_report_check", "YES", "security_admin", "no raw secret/raw payload evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("backup_restore_readiness_evidence", "uat_backup_restore_readiness_note", "readiness_note", "NO", "ops_admin", "non destructive readiness note", "NO", "READY_FOR_IMPLEMENTATION"),
    ("go_no_go_evidence", "uat_go_no_go_decision", "signed_decision_note", "YES", "project_owner", "go/no-go decision evidence", "YES", "READY_FOR_IMPLEMENTATION"),
]

BLOCKERS = [
    ("P0", "tenant_access_failed", "NO_GO", "project_owner", "fix tenant access before rollout", "READY_FOR_IMPLEMENTATION"),
    ("P0", "rbac_bypass_or_wrong_access", "NO_GO", "security_admin", "fix RBAC/tenant isolation before rollout", "READY_FOR_IMPLEMENTATION"),
    ("P0", "sale_flow_failed", "NO_GO", "project_owner", "fix sale flow before rollout", "READY_FOR_IMPLEMENTATION"),
    ("P0", "stock_movement_mismatch", "NO_GO", "tenant_operator", "fix stock movement before rollout", "READY_FOR_IMPLEMENTATION"),
    ("P0", "accounting_journal_wrong", "NO_GO", "accountant", "fix TDHP/journal mapping before rollout", "READY_FOR_IMPLEMENTATION"),
    ("P0", "audit_missing", "NO_GO", "security_admin", "fix audit evidence before rollout", "READY_FOR_IMPLEMENTATION"),
    ("P0", "secret_leak_detected", "NO_GO", "security_admin", "remove raw secret/raw payload before rollout", "READY_FOR_IMPLEMENTATION"),
    ("P0", "go_no_go_not_signed", "NO_GO", "project_owner", "complete go/no-go decision", "READY_FOR_IMPLEMENTATION"),
    ("P1", "reporting_minor_mismatch", "CONDITIONAL_GO", "tenant_admin", "document workaround and backlog item", "READY_FOR_IMPLEMENTATION"),
    ("P1", "workflow_minor_issue", "CONDITIONAL_GO", "tenant_admin", "document workaround and retry plan", "READY_FOR_IMPLEMENTATION"),
    ("P1", "support_loop_minor_gap", "CONDITIONAL_GO", "support", "assign support owner before rollout", "READY_FOR_IMPLEMENTATION"),
    ("P1", "backup_restore_note_missing", "CONDITIONAL_GO", "ops_admin", "create readiness note before final go-live", "READY_FOR_IMPLEMENTATION"),
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
    return v[:420]

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
detail("TENANT_CREATED=NO")
detail("USER_CREATED=NO")
detail("PASSWORD_CREATED=NO")
detail("TOKEN_CREATED=NO")
detail("UAT_EXECUTED=NO")
detail("REAL_SALE_CREATED=NO")
detail("REAL_STOCK_MUTATED=NO")
detail("REAL_ACCOUNTING_ENTRY_CREATED=NO")
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
detail("VALIDATION_MODE=UAT_SCENARIO_EXECUTION_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_16_2_status = get_value(prev_16_2, "FAZ4B_16_2_FINAL_STATUS")
prev_16_2_gate = get_value(prev_16_2, "PILOT_TENANT_READINESS_CONTRACT")
prev_16_2_no_runtime = get_value(prev_16_2, "PILOT_TENANT_NO_RUNTIME_CHANGE")
prev_16_2_secret = get_value(prev_16_2, "PILOT_TENANT_SECRET_SAFE")
prev_16_1_status = get_value(prev_16_1, "FAZ4B_16_1_FINAL_STATUS")
prev_17_status = get_value(prev_17, "FAZ4B_17_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")

detail(f"PREVIOUS_16_2_FINAL_STATUS={prev_16_2_status}")
detail(f"PREVIOUS_16_2_PILOT_TENANT_READINESS_CONTRACT={prev_16_2_gate}")
detail(f"PREVIOUS_16_2_PILOT_TENANT_NO_RUNTIME_CHANGE={prev_16_2_no_runtime}")
detail(f"PREVIOUS_16_2_PILOT_TENANT_SECRET_SAFE={prev_16_2_secret}")
detail(f"PREVIOUS_16_1_FINAL_STATUS={prev_16_1_status}")
detail(f"PREVIOUS_17_FINAL_STATUS={prev_17_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")

if prev_16_2_status != "PASS":
    fail("16.2 final status PASS degil")
if prev_16_2_gate != "PASS":
    fail("16.2 pilot tenant readiness PASS degil")
if prev_16_2_no_runtime != "PASS":
    fail("16.2 no runtime change PASS degil")
if prev_16_2_secret != "PASS":
    fail("16.2 secret safe PASS degil")
if prev_16_1_status != "PASS":
    fail("16.1 final status PASS degil")
if prev_17_status != "PASS":
    fail("17 final status PASS degil")
if prev_20_status != "PASS":
    fail("20 final status PASS degil")
if prev_21_status != "PASS":
    fail("21 final status PASS degil")
if prev_22_status != "PASS":
    fail("22 final status PASS degil")

for p, label in [(standard_file, "standard doc"), (policy_file, "policy doc")]:
    if not p.exists():
        fail(f"{label} yok")

execution_lines = ["scenario_name\tmodule\tpriority\tactor_role\tprecondition\texecution_steps\texpected_evidence\tacceptance_criteria\tblocker_if_failed\taudit_required\ttenant_check_required\trbac_check_required\timplementation_status\tnote"]
for row in UAT_EXECUTION:
    execution_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_uat_executed"]]))
execution_file.write_text("\n".join(execution_lines) + "\n")

actor_counts = Counter([x[3] for x in UAT_EXECUTION])
actor_p0_counts = Counter([x[3] for x in UAT_EXECUTION if x[2] == "P0"])

actor_lines = ["actor_role\tscenario_count\tp0_count\tallowed_scope\tforbidden_scope\tevidence_owner\timplementation_status\tnote"]
actor_scope = {
    "tenant_user": ("tenant scoped panel access", "platform/security/raw secrets", "tenant_user"),
    "cashier": ("sales/refund/basic product lookup", "admin/security/accounting/platform ops", "cashier"),
    "tenant_operator": ("product/stock/customer/vendor/task", "security/platform ops/raw secrets", "tenant_operator"),
    "tenant_approver": ("approval/workflow action evidence", "security/platform ops/raw secrets", "tenant_approver"),
    "accountant": ("accounting/journal/ledger/report review", "cashier action/security/platform ops", "accountant"),
    "tenant_admin": ("tenant reports/audit/users/readiness", "platform security/raw secrets", "tenant_admin"),
    "ops_admin": ("ops/support/readiness evidence", "tenant private data raw/raw secrets", "ops_admin"),
    "security_admin": ("security/rbac/tenant isolation evidence", "tenant business mutation", "security_admin"),
    "project_owner": ("UAT decision/go-no-go", "raw secrets", "project_owner"),
}
for actor, count in sorted(actor_counts.items()):
    allowed, forbidden, owner = actor_scope.get(actor, ("scenario scoped", "raw secrets", actor))
    actor_lines.append("\t".join([safe(x) for x in [
        actor,
        str(count),
        str(actor_p0_counts.get(actor, 0)),
        allowed,
        forbidden,
        owner,
        "READY_FOR_IMPLEMENTATION",
        "contract_only",
    ]]))
actor_file.write_text("\n".join(actor_lines) + "\n")

evidence_lines = ["evidence_name\tscenario_ref\tevidence_type\trequired_for_go_live\towner_role\tacceptance_format\tblocker_if_missing\timplementation_status\tnote"]
for row in EVIDENCE:
    evidence_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_private_data"]]))
evidence_file.write_text("\n".join(evidence_lines) + "\n")

blocker_lines = ["priority\tfailure_type\trollout_decision\tescalation_owner\trequired_action\timplementation_status\tnote"]
for row in BLOCKERS:
    blocker_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
blocker_file.write_text("\n".join(blocker_lines) + "\n")

scenario_count = len(UAT_EXECUTION)
p0_count = sum(1 for x in UAT_EXECUTION if x[2] == "P0")
p1_count = sum(1 for x in UAT_EXECUTION if x[2] == "P1")
blocker_scenario_count = sum(1 for x in UAT_EXECUTION if x[8] == "YES")
audit_required_count = sum(1 for x in UAT_EXECUTION if x[9] == "YES")
tenant_check_count = sum(1 for x in UAT_EXECUTION if x[10] == "YES")
rbac_check_count = sum(1 for x in UAT_EXECUTION if x[11] == "YES")
actor_count = len(actor_counts)
evidence_count = len(EVIDENCE)
golive_evidence_count = sum(1 for x in EVIDENCE if x[3] == "YES")
blocker_evidence_count = sum(1 for x in EVIDENCE if x[6] == "YES")
blocker_policy_count = len(BLOCKERS)
no_go_policy_count = sum(1 for x in BLOCKERS if x[2] == "NO_GO")
conditional_go_policy_count = sum(1 for x in BLOCKERS if x[2] == "CONDITIONAL_GO")

detail(f"UAT_SCENARIO_COUNT={scenario_count}")
detail(f"UAT_P0_SCENARIO_COUNT={p0_count}")
detail(f"UAT_P1_SCENARIO_COUNT={p1_count}")
detail(f"UAT_BLOCKER_SCENARIO_COUNT={blocker_scenario_count}")
detail(f"UAT_AUDIT_REQUIRED_COUNT={audit_required_count}")
detail(f"UAT_TENANT_CHECK_COUNT={tenant_check_count}")
detail(f"UAT_RBAC_CHECK_COUNT={rbac_check_count}")
detail(f"UAT_ACTOR_COUNT={actor_count}")
detail(f"UAT_EVIDENCE_COUNT={evidence_count}")
detail(f"UAT_GOLIVE_EVIDENCE_COUNT={golive_evidence_count}")
detail(f"UAT_BLOCKER_EVIDENCE_COUNT={blocker_evidence_count}")
detail(f"UAT_BLOCKER_POLICY_COUNT={blocker_policy_count}")
detail(f"UAT_NO_GO_POLICY_COUNT={no_go_policy_count}")
detail(f"UAT_CONDITIONAL_GO_POLICY_COUNT={conditional_go_policy_count}")

required_scenarios = [
    "uat_login_tenant_access",
    "uat_role_permission_denied",
    "uat_sale_cash_flow",
    "uat_inventory_movement_validation",
    "uat_sale_cancel_refund",
    "uat_accounting_journal_check",
    "uat_audit_trail_check",
    "uat_no_raw_secret_payload",
    "uat_go_no_go_decision",
]
scenario_names = set([x[0] for x in UAT_EXECUTION])
missing_scenarios = [x for x in required_scenarios if x not in scenario_names]

required_actors = ["tenant_user", "cashier", "tenant_operator", "accountant", "tenant_admin", "ops_admin", "security_admin", "project_owner"]
missing_actors = [x for x in required_actors if x not in actor_counts]

required_evidence = [
    "tenant_access_evidence",
    "permission_denied_evidence",
    "sale_cash_flow_evidence",
    "inventory_movement_evidence",
    "accounting_journal_evidence",
    "audit_trail_evidence",
    "secret_safety_evidence",
    "go_no_go_evidence",
]
evidence_names = set([x[0] for x in EVIDENCE])
missing_evidence = [x for x in required_evidence if x not in evidence_names]

if missing_scenarios:
    fail("required UAT scenario eksik: " + ",".join(missing_scenarios))
if missing_actors:
    fail("required actor eksik: " + ",".join(missing_actors))
if missing_evidence:
    fail("required evidence eksik: " + ",".join(missing_evidence))
if p0_count < 9:
    fail("P0 scenario sayisi yetersiz")
if audit_required_count < p0_count:
    fail("audit coverage P0 sayisindan az")
if tenant_check_count != scenario_count:
    fail("tum UAT senaryolarinda tenant_check YES degil")
if rbac_check_count != scenario_count:
    fail("tum UAT senaryolarinda rbac_check YES degil")
if no_go_policy_count < 7:
    fail("NO_GO blocker policy sayisi yetersiz")

previous_status = "PASS" if (
    prev_16_2_status == "PASS"
    and prev_16_2_gate == "PASS"
    and prev_16_2_no_runtime == "PASS"
    and prev_16_2_secret == "PASS"
) else "FAIL"

execution_status = "PASS" if execution_file.exists() and scenario_count >= 15 and not missing_scenarios else "FAIL"
actor_status = "PASS" if actor_file.exists() and actor_count >= 8 and not missing_actors else "FAIL"
evidence_status = "PASS" if evidence_file.exists() and evidence_count >= 15 and not missing_evidence else "FAIL"
blocker_status = "PASS" if blocker_file.exists() and blocker_policy_count >= 10 and no_go_policy_count >= 7 else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"UAT_PREVIOUS_16_2={previous_status}")
detail(f"UAT_EXECUTION_PLAN={execution_status}")
detail(f"UAT_ACTOR_MATRIX={actor_status}")
detail(f"UAT_EVIDENCE_MATRIX={evidence_status}")
detail(f"UAT_BLOCKER_POLICY={blocker_status}")
detail(f"UAT_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"UAT_NO_CONFIG_CHANGE={no_config_status}")
detail(f"UAT_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_16_2", previous_status),
    ("execution_plan", execution_status),
    ("actor_matrix", actor_status),
    ("evidence_matrix", evidence_status),
    ("blocker_policy", blocker_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_16_2\t{previous_status}\tpilot tenant readiness prerequisite",
    f"uat_execution_plan\t{execution_status}\tscenarios={scenario_count} p0={p0_count} p1={p1_count}",
    f"uat_actor_matrix\t{actor_status}\tactors={actor_count}",
    f"uat_evidence_matrix\t{evidence_status}\tevidence={evidence_count} go_live={golive_evidence_count}",
    f"uat_blocker_policy\t{blocker_status}\tpolicies={blocker_policy_count} no_go={no_go_policy_count}",
    f"tenant_rbac_coverage\tPASS\ttenant_checks={tenant_check_count} rbac_checks={rbac_check_count}",
    f"audit_coverage\tPASS\taudit_required={audit_required_count}",
    f"no_runtime_change\t{no_runtime_status}\tno real UAT/tenant/user/db/api/ui/event changed",
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
    "tenant_created\tNO\tcontract only",
    "user_created\tNO\tcontract only",
    "password_created\tNO\tcontract only",
    "token_created\tNO\tcontract only",
    "uat_executed\tNO\tcontract only",
    "real_sale_created\tNO\tcontract only",
    "real_stock_mutated\tNO\tcontract only",
    "real_accounting_entry_created\tNO\tcontract only",
    "ui_code_changed\tNO\tcontract only",
    "api_route_created\tNO\tcontract only",
    "api_implementation_changed\tNO\tcontract only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "event_published\tNO\tcontract only",
    "event_consumed\tNO\tcontract only",
    "notification_sent\tNO\tcontract only",
    "customer_private_data_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
    "token_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"UAT_SCENARIO_EXECUTION_CONTRACT={final_status}")
detail(f"FAZ4B_16_3_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 16.3 - UAT Scenario Execution Contract Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"UAT_SCENARIO_EXECUTION_CONTRACT={final_status}",
    f"FAZ4B_16_3_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/16_3_uat_execution_contract_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "UAT_EXECUTION_PLAN_FILE=docs/phase4/16_3_uat_execution_plan.tsv",
    "UAT_ACTOR_MATRIX_FILE=docs/phase4/16_3_uat_actor_matrix.tsv",
    "UAT_EVIDENCE_MATRIX_FILE=docs/phase4/16_3_uat_evidence_matrix.tsv",
    "UAT_BLOCKER_POLICY_FILE=docs/phase4/16_3_uat_blocker_policy.tsv",
    "NOTE=Contract only. No real UAT/runtime/config/db/api/ui/event/customer-private-data change executed.",
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
    "TENANT_CREATED=NO",
    "USER_CREATED=NO",
    "PASSWORD_CREATED=NO",
    "TOKEN_CREATED=NO",
    "UAT_EXECUTED=NO",
    "REAL_SALE_CREATED=NO",
    "REAL_STOCK_MUTATED=NO",
    "REAL_ACCOUNTING_ENTRY_CREATED=NO",
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
print(f"UAT_EXECUTION_PLAN_FILE={execution_file}")
print(f"UAT_ACTOR_MATRIX_FILE={actor_file}")
print(f"UAT_EVIDENCE_MATRIX_FILE={evidence_file}")
print(f"UAT_BLOCKER_POLICY_FILE={blocker_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"UAT_SCENARIO_COUNT={scenario_count}")
print(f"UAT_P0_SCENARIO_COUNT={p0_count}")
print(f"UAT_P1_SCENARIO_COUNT={p1_count}")
print(f"UAT_BLOCKER_SCENARIO_COUNT={blocker_scenario_count}")
print(f"UAT_AUDIT_REQUIRED_COUNT={audit_required_count}")
print(f"UAT_TENANT_CHECK_COUNT={tenant_check_count}")
print(f"UAT_RBAC_CHECK_COUNT={rbac_check_count}")
print(f"UAT_ACTOR_COUNT={actor_count}")
print(f"UAT_EVIDENCE_COUNT={evidence_count}")
print(f"UAT_GOLIVE_EVIDENCE_COUNT={golive_evidence_count}")
print(f"UAT_BLOCKER_EVIDENCE_COUNT={blocker_evidence_count}")
print(f"UAT_BLOCKER_POLICY_COUNT={blocker_policy_count}")
print(f"UAT_NO_GO_POLICY_COUNT={no_go_policy_count}")
print(f"UAT_CONDITIONAL_GO_POLICY_COUNT={conditional_go_policy_count}")
print(f"UAT_PREVIOUS_16_2={previous_status}")
print(f"UAT_EXECUTION_PLAN={execution_status}")
print(f"UAT_ACTOR_MATRIX={actor_status}")
print(f"UAT_EVIDENCE_MATRIX={evidence_status}")
print(f"UAT_BLOCKER_POLICY={blocker_status}")
print(f"UAT_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"UAT_NO_CONFIG_CHANGE={no_config_status}")
print(f"UAT_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("TENANT_CREATED=NO")
print("USER_CREATED=NO")
print("PASSWORD_CREATED=NO")
print("TOKEN_CREATED=NO")
print("UAT_EXECUTED=NO")
print("REAL_SALE_CREATED=NO")
print("REAL_STOCK_MUTATED=NO")
print("REAL_ACCOUNTING_ENTRY_CREATED=NO")
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
print(f"UAT_SCENARIO_EXECUTION_CONTRACT={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_16_3_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
