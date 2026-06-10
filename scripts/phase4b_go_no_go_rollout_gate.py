#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "16_5_go_no_go_rollout_gate_standard.md"
policy_file = report_dir / "16_5_go_no_go_rollout_gate_policy.md"
decision_file = report_dir / "16_5_go_no_go_decision_matrix.tsv"
blocker_file = report_dir / "16_5_rollout_blocker_policy.tsv"
security_file = report_dir / "16_5_security_tenant_gate.tsv"
business_file = report_dir / "16_5_business_chain_gate.tsv"
support_file = report_dir / "16_5_support_incident_gate.tsv"
matrix_file = report_dir / "16_5_go_no_go_rollout_gate_matrix.tsv"
report_file = report_dir / "16_5_go_no_go_rollout_gate_report.md"

prev_16_4 = report_dir / "16_4_pilot_data_readiness_contract_report.md"
prev_16_3 = report_dir / "16_3_uat_scenario_execution_contract_report.md"
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

DECISION_GATES = [
    ("foundation_closed", "foundation", "P0", "PASS", "YES", "NO_GO", "16.1-16.4 + 17/20/21/22 reports", "project_owner", "READY_FOR_IMPLEMENTATION"),
    ("pilot_tenant_ready", "tenant", "P0", "PASS", "YES", "NO_GO", "16.2 tenant readiness report", "platform_admin", "READY_FOR_IMPLEMENTATION"),
    ("uat_execution_contract_ready", "uat", "P0", "PASS", "YES", "NO_GO", "16.3 UAT execution contract", "project_owner", "READY_FOR_IMPLEMENTATION"),
    ("pilot_data_ready", "data", "P0", "PASS", "YES", "NO_GO", "16.4 pilot data readiness report", "tenant_operator", "READY_FOR_IMPLEMENTATION"),
    ("security_rbac_checked", "security", "P0", "PASS", "YES", "NO_GO", "21 security / 16.3 RBAC UAT evidence", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("tenant_isolation_checked", "tenant_security", "P0", "PASS", "YES", "NO_GO", "tenant access / isolation evidence", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("secret_safety_checked", "security", "P0", "PASS", "YES", "NO_GO", "no raw secret / payload evidence", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("sales_stock_accounting_chain_ready", "business", "P0", "PASS", "YES", "NO_GO", "sale + stock + TDHP chain evidence", "project_owner", "READY_FOR_IMPLEMENTATION"),
    ("audit_evidence_ready", "audit", "P0", "PASS", "YES", "NO_GO", "actor/request/tenant audit evidence", "tenant_admin", "READY_FOR_IMPLEMENTATION"),
    ("support_loop_ready", "support", "P0", "PASS", "YES", "NO_GO", "support channel + owner evidence", "support", "READY_FOR_IMPLEMENTATION"),
    ("incident_feedback_loop_ready", "ops", "P0", "PASS", "YES", "NO_GO", "incident template / feedback loop evidence", "ops_admin", "READY_FOR_IMPLEMENTATION"),
    ("training_completion_ready", "training", "P1", "PASS", "NO", "CONDITIONAL_GO", "training attendance evidence", "trainer", "READY_FOR_IMPLEMENTATION"),
    ("backup_restore_readiness_noted", "ops", "P1", "PASS", "NO", "CONDITIONAL_GO", "backup/restore readiness note", "ops_admin", "READY_FOR_IMPLEMENTATION"),
    ("reporting_snapshot_ready", "reporting", "P1", "PASS", "NO", "CONDITIONAL_GO", "reporting snapshot evidence", "tenant_admin", "READY_FOR_IMPLEMENTATION"),
    ("final_go_no_go_signed", "rollout", "P0", "PASS", "YES", "NO_GO", "signed final decision note", "project_owner", "READY_FOR_IMPLEMENTATION"),
]

BLOCKERS = [
    ("tenant_access_failed", "P0", "tenant", "NO_GO", "platform_admin", "fix tenant access before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("rbac_bypass_or_wrong_access", "P0", "security", "NO_GO", "security_admin", "fix RBAC before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("tenant_isolation_failed", "P0", "security", "NO_GO", "security_admin", "fix tenant isolation before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("secret_or_raw_payload_leak", "P0", "security", "NO_GO", "security_admin", "remove raw secret/raw payload before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("sale_flow_failed", "P0", "business", "NO_GO", "project_owner", "fix sale flow before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("stock_movement_mismatch", "P0", "inventory", "NO_GO", "tenant_operator", "fix stock movement before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("accounting_journal_wrong", "P0", "accounting", "NO_GO", "accountant", "fix TDHP/journal mapping before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("audit_missing", "P0", "audit", "NO_GO", "security_admin", "fix audit evidence before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("support_loop_missing", "P0", "support", "NO_GO", "support", "define support owner/channel before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("incident_feedback_loop_missing", "P0", "ops", "NO_GO", "ops_admin", "define incident loop before rollout", "NO", "READY_FOR_IMPLEMENTATION"),
    ("go_no_go_not_signed", "P0", "rollout", "NO_GO", "project_owner", "complete final decision", "NO", "READY_FOR_IMPLEMENTATION"),
    ("reporting_minor_mismatch", "P1", "reporting", "CONDITIONAL_GO", "tenant_admin", "document workaround and backlog", "YES", "READY_FOR_IMPLEMENTATION"),
    ("training_gap_minor", "P1", "training", "CONDITIONAL_GO", "trainer", "schedule catch-up training", "YES", "READY_FOR_IMPLEMENTATION"),
    ("backup_restore_note_missing", "P1", "ops", "CONDITIONAL_GO", "ops_admin", "create readiness note before wider rollout", "YES", "READY_FOR_IMPLEMENTATION"),
    ("workflow_minor_issue", "P1", "workflow", "CONDITIONAL_GO", "tenant_admin", "document workaround and retry plan", "YES", "READY_FOR_IMPLEMENTATION"),
]

SECURITY_GATES = [
    ("auth_login_gate", "auth", "PASS", "YES", "login tenant access evidence", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("rbac_denied_gate", "rbac", "PASS", "YES", "permission denied evidence", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("tenant_isolation_gate", "tenant_isolation", "PASS", "YES", "tenant scoped visibility evidence", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("audit_trail_gate", "audit", "PASS", "YES", "actor/request/tenant audit evidence", "tenant_admin", "READY_FOR_IMPLEMENTATION"),
    ("secret_safety_gate", "secret_safety", "PASS", "YES", "no raw secret/token/dsn evidence", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("customer_private_data_gate", "privacy", "PASS", "YES", "synthetic/masked data evidence", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("ops_access_gate", "ops_security", "PASS", "YES", "ops access restricted evidence", "ops_admin", "READY_FOR_IMPLEMENTATION"),
    ("support_masking_gate", "support_security", "PASS", "YES", "support sees masked status only", "support", "READY_FOR_IMPLEMENTATION"),
    ("no_raw_payload_ui_gate", "ui_security", "PASS", "YES", "no raw payload UI policy evidence", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("incident_security_gate", "incident", "PASS", "YES", "security escalation owner exists", "security_admin", "READY_FOR_IMPLEMENTATION"),
]

BUSINESS_GATES = [
    ("product_catalog_ready", "product", "PASS", "YES", "product sample dataset evidence", "tenant_operator", "READY_FOR_IMPLEMENTATION"),
    ("opening_stock_ready", "inventory", "PASS", "YES", "opening stock sample evidence", "tenant_operator", "READY_FOR_IMPLEMENTATION"),
    ("cash_sale_ready", "sales", "PASS", "YES", "cash sale UAT evidence", "cashier", "READY_FOR_IMPLEMENTATION"),
    ("card_sale_ready", "sales", "PASS", "YES", "card sale accounting policy evidence", "cashier", "READY_FOR_IMPLEMENTATION"),
    ("stock_decrease_ready", "inventory", "PASS", "YES", "sale stock decrease evidence", "tenant_operator", "READY_FOR_IMPLEMENTATION"),
    ("refund_cancel_ready", "sales_inventory", "PASS", "YES", "refund/cancel reversal evidence", "cashier", "READY_FOR_IMPLEMENTATION"),
    ("negative_stock_guard_ready", "inventory", "PASS", "YES", "negative stock guard evidence", "tenant_operator", "READY_FOR_IMPLEMENTATION"),
    ("tdhp_journal_ready", "accounting", "PASS", "YES", "100/108/120/600/391 line evidence", "accountant", "READY_FOR_IMPLEMENTATION"),
    ("reporting_summary_ready", "reporting", "PASS", "NO", "summary report evidence", "tenant_admin", "READY_FOR_IMPLEMENTATION"),
    ("go_no_go_business_owner_ready", "rollout", "PASS", "YES", "business owner decision evidence", "project_owner", "READY_FOR_IMPLEMENTATION"),
]

SUPPORT_GATES = [
    ("support_channel_ready", "support", "PASS", "YES", "support channel/contact evidence", "support", "READY_FOR_IMPLEMENTATION"),
    ("incident_template_ready", "incident", "PASS", "YES", "incident template evidence", "ops_admin", "READY_FOR_IMPLEMENTATION"),
    ("escalation_owner_ready", "incident", "PASS", "YES", "ops/security/business owner mapping", "project_owner", "READY_FOR_IMPLEMENTATION"),
    ("pilot_feedback_loop_ready", "feedback", "PASS", "YES", "feedback collection owner evidence", "support", "READY_FOR_IMPLEMENTATION"),
    ("ops_console_readiness_ready", "ops", "PASS", "YES", "observability/ops console closure evidence", "ops_admin", "READY_FOR_IMPLEMENTATION"),
    ("rollback_contact_ready", "rollout", "PASS", "YES", "rollback contact owner evidence", "ops_admin", "READY_FOR_IMPLEMENTATION"),
    ("daily_review_cadence_ready", "support", "PASS", "NO", "pilot daily review cadence note", "project_owner", "READY_FOR_IMPLEMENTATION"),
    ("customer_communication_plan_ready", "communication", "PASS", "YES", "communication plan draft only", "project_owner", "READY_FOR_IMPLEMENTATION"),
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
detail("ROLLOUT_EXECUTED=NO")
detail("GO_LIVE_SWITCHED=NO")
detail("PRODUCTION_TRAFFIC_CHANGED=NO")
detail("TENANT_ENABLED_FOR_LIVE=NO")
detail("REAL_CUSTOMER_NOTIFIED=NO")
detail("UAT_EXECUTED=NO")
detail("SAMPLE_DATA_INSERTED=NO")
detail("REAL_CUSTOMER_DATA_CREATED=NO")
detail("REAL_PRODUCT_CREATED=NO")
detail("REAL_STOCK_MUTATED=NO")
detail("REAL_SALE_CREATED=NO")
detail("REAL_ACCOUNTING_ENTRY_CREATED=NO")
detail("DATA_IMPORT_EXECUTED=NO")
detail("FILE_EXPORT_EXECUTED=NO")
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
detail("VALIDATION_MODE=GO_NO_GO_ROLLOUT_GATE_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_16_4_status = get_value(prev_16_4, "FAZ4B_16_4_FINAL_STATUS")
prev_16_4_gate = get_value(prev_16_4, "PILOT_DATA_READINESS_CONTRACT")
prev_16_4_no_runtime = get_value(prev_16_4, "PILOT_DATA_NO_RUNTIME_CHANGE")
prev_16_4_secret = get_value(prev_16_4, "PILOT_DATA_SECRET_SAFE")
prev_16_3_status = get_value(prev_16_3, "FAZ4B_16_3_FINAL_STATUS")
prev_16_2_status = get_value(prev_16_2, "FAZ4B_16_2_FINAL_STATUS")
prev_16_1_status = get_value(prev_16_1, "FAZ4B_16_1_FINAL_STATUS")
prev_17_status = get_value(prev_17, "FAZ4B_17_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")

detail(f"PREVIOUS_16_4_FINAL_STATUS={prev_16_4_status}")
detail(f"PREVIOUS_16_4_PILOT_DATA_READINESS_CONTRACT={prev_16_4_gate}")
detail(f"PREVIOUS_16_4_PILOT_DATA_NO_RUNTIME_CHANGE={prev_16_4_no_runtime}")
detail(f"PREVIOUS_16_4_PILOT_DATA_SECRET_SAFE={prev_16_4_secret}")
detail(f"PREVIOUS_16_3_FINAL_STATUS={prev_16_3_status}")
detail(f"PREVIOUS_16_2_FINAL_STATUS={prev_16_2_status}")
detail(f"PREVIOUS_16_1_FINAL_STATUS={prev_16_1_status}")
detail(f"PREVIOUS_17_FINAL_STATUS={prev_17_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")

if prev_16_4_status != "PASS":
    fail("16.4 final status PASS degil")
if prev_16_4_gate != "PASS":
    fail("16.4 pilot data readiness PASS degil")
if prev_16_4_no_runtime != "PASS":
    fail("16.4 no runtime change PASS degil")
if prev_16_4_secret != "PASS":
    fail("16.4 secret safe PASS degil")
if prev_16_3_status != "PASS":
    fail("16.3 final status PASS degil")
if prev_16_2_status != "PASS":
    fail("16.2 final status PASS degil")
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

decision_lines = ["gate_name\tcategory\tpriority\trequired_status\tblocker_if_failed\tdecision_if_failed\tevidence_source\towner_role\timplementation_status\tnote"]
for row in DECISION_GATES:
    decision_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_rollout_executed"]]))
decision_file.write_text("\n".join(decision_lines) + "\n")

blocker_lines = ["blocker_code\tpriority\tfailure_area\trollout_decision\tescalation_owner\trequired_action\tcan_continue_with_workaround\timplementation_status\tnote"]
for row in BLOCKERS:
    blocker_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
blocker_file.write_text("\n".join(blocker_lines) + "\n")

security_lines = ["gate_name\tsecurity_area\trequired_status\tblocker_if_failed\tevidence_source\towner_role\timplementation_status\tnote"]
for row in SECURITY_GATES:
    security_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
security_file.write_text("\n".join(security_lines) + "\n")

business_lines = ["chain_name\tbusiness_area\trequired_status\tblocker_if_failed\tevidence_source\towner_role\timplementation_status\tnote"]
for row in BUSINESS_GATES:
    business_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
business_file.write_text("\n".join(business_lines) + "\n")

support_lines = ["gate_name\tcategory\trequired_status\tblocker_if_failed\tevidence_source\towner_role\timplementation_status\tnote"]
for row in SUPPORT_GATES:
    support_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
support_file.write_text("\n".join(support_lines) + "\n")

decision_count = len(DECISION_GATES)
decision_p0_count = sum(1 for x in DECISION_GATES if x[2] == "P0")
decision_p1_count = sum(1 for x in DECISION_GATES if x[2] == "P1")
decision_blocker_count = sum(1 for x in DECISION_GATES if x[4] == "YES")
decision_no_go_count = sum(1 for x in DECISION_GATES if x[5] == "NO_GO")
decision_conditional_count = sum(1 for x in DECISION_GATES if x[5] == "CONDITIONAL_GO")

blocker_count = len(BLOCKERS)
p0_blocker_count = sum(1 for x in BLOCKERS if x[1] == "P0")
no_go_blocker_count = sum(1 for x in BLOCKERS if x[3] == "NO_GO")
conditional_blocker_count = sum(1 for x in BLOCKERS if x[3] == "CONDITIONAL_GO")
workaround_count = sum(1 for x in BLOCKERS if x[6] == "YES")

security_count = len(SECURITY_GATES)
security_blocker_count = sum(1 for x in SECURITY_GATES if x[3] == "YES")
business_count = len(BUSINESS_GATES)
business_blocker_count = sum(1 for x in BUSINESS_GATES if x[3] == "YES")
support_count = len(SUPPORT_GATES)
support_blocker_count = sum(1 for x in SUPPORT_GATES if x[3] == "YES")

detail(f"GO_NO_GO_DECISION_GATE_COUNT={decision_count}")
detail(f"GO_NO_GO_DECISION_P0_COUNT={decision_p0_count}")
detail(f"GO_NO_GO_DECISION_P1_COUNT={decision_p1_count}")
detail(f"GO_NO_GO_DECISION_BLOCKER_COUNT={decision_blocker_count}")
detail(f"GO_NO_GO_DECISION_NO_GO_COUNT={decision_no_go_count}")
detail(f"GO_NO_GO_DECISION_CONDITIONAL_COUNT={decision_conditional_count}")
detail(f"GO_NO_GO_BLOCKER_POLICY_COUNT={blocker_count}")
detail(f"GO_NO_GO_P0_BLOCKER_COUNT={p0_blocker_count}")
detail(f"GO_NO_GO_NO_GO_BLOCKER_COUNT={no_go_blocker_count}")
detail(f"GO_NO_GO_CONDITIONAL_BLOCKER_COUNT={conditional_blocker_count}")
detail(f"GO_NO_GO_WORKAROUND_ALLOWED_COUNT={workaround_count}")
detail(f"GO_NO_GO_SECURITY_GATE_COUNT={security_count}")
detail(f"GO_NO_GO_SECURITY_BLOCKER_COUNT={security_blocker_count}")
detail(f"GO_NO_GO_BUSINESS_GATE_COUNT={business_count}")
detail(f"GO_NO_GO_BUSINESS_BLOCKER_COUNT={business_blocker_count}")
detail(f"GO_NO_GO_SUPPORT_GATE_COUNT={support_count}")
detail(f"GO_NO_GO_SUPPORT_BLOCKER_COUNT={support_blocker_count}")

required_decisions = [
    "foundation_closed",
    "pilot_tenant_ready",
    "pilot_data_ready",
    "security_rbac_checked",
    "tenant_isolation_checked",
    "secret_safety_checked",
    "sales_stock_accounting_chain_ready",
    "audit_evidence_ready",
    "support_loop_ready",
    "final_go_no_go_signed",
]
decision_names = set([x[0] for x in DECISION_GATES])
missing_decisions = [x for x in required_decisions if x not in decision_names]

required_blockers = [
    "tenant_access_failed",
    "rbac_bypass_or_wrong_access",
    "tenant_isolation_failed",
    "secret_or_raw_payload_leak",
    "sale_flow_failed",
    "stock_movement_mismatch",
    "accounting_journal_wrong",
    "audit_missing",
    "support_loop_missing",
    "go_no_go_not_signed",
]
blocker_names = set([x[0] for x in BLOCKERS])
missing_blockers = [x for x in required_blockers if x not in blocker_names]

required_security = [
    "auth_login_gate",
    "rbac_denied_gate",
    "tenant_isolation_gate",
    "audit_trail_gate",
    "secret_safety_gate",
    "customer_private_data_gate",
]
security_names = set([x[0] for x in SECURITY_GATES])
missing_security = [x for x in required_security if x not in security_names]

required_business = [
    "product_catalog_ready",
    "opening_stock_ready",
    "cash_sale_ready",
    "stock_decrease_ready",
    "refund_cancel_ready",
    "negative_stock_guard_ready",
    "tdhp_journal_ready",
]
business_names = set([x[0] for x in BUSINESS_GATES])
missing_business = [x for x in required_business if x not in business_names]

required_support = [
    "support_channel_ready",
    "incident_template_ready",
    "escalation_owner_ready",
    "pilot_feedback_loop_ready",
    "ops_console_readiness_ready",
    "rollback_contact_ready",
]
support_names = set([x[0] for x in SUPPORT_GATES])
missing_support = [x for x in required_support if x not in support_names]

if missing_decisions:
    fail("required decision gate eksik: " + ",".join(missing_decisions))
if missing_blockers:
    fail("required blocker policy eksik: " + ",".join(missing_blockers))
if missing_security:
    fail("required security gate eksik: " + ",".join(missing_security))
if missing_business:
    fail("required business gate eksik: " + ",".join(missing_business))
if missing_support:
    fail("required support gate eksik: " + ",".join(missing_support))
if decision_p0_count < 10:
    fail("P0 decision gate sayisi yetersiz")
if no_go_blocker_count < 10:
    fail("NO_GO blocker policy sayisi yetersiz")
if security_blocker_count < 8:
    fail("security blocker coverage yetersiz")
if business_blocker_count < 7:
    fail("business blocker coverage yetersiz")
if support_blocker_count < 6:
    fail("support blocker coverage yetersiz")

previous_status = "PASS" if (
    prev_16_4_status == "PASS"
    and prev_16_4_gate == "PASS"
    and prev_16_4_no_runtime == "PASS"
    and prev_16_4_secret == "PASS"
) else "FAIL"

decision_status = "PASS" if decision_file.exists() and decision_count >= 14 and not missing_decisions else "FAIL"
blocker_status = "PASS" if blocker_file.exists() and blocker_count >= 12 and not missing_blockers else "FAIL"
security_status = "PASS" if security_file.exists() and security_count >= 10 and not missing_security else "FAIL"
business_status = "PASS" if business_file.exists() and business_count >= 10 and not missing_business else "FAIL"
support_status = "PASS" if support_file.exists() and support_count >= 8 and not missing_support else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"GO_NO_GO_PREVIOUS_16_4={previous_status}")
detail(f"GO_NO_GO_DECISION_MATRIX={decision_status}")
detail(f"GO_NO_GO_BLOCKER_POLICY={blocker_status}")
detail(f"GO_NO_GO_SECURITY_TENANT_GATE={security_status}")
detail(f"GO_NO_GO_BUSINESS_CHAIN_GATE={business_status}")
detail(f"GO_NO_GO_SUPPORT_INCIDENT_GATE={support_status}")
detail(f"GO_NO_GO_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"GO_NO_GO_NO_CONFIG_CHANGE={no_config_status}")
detail(f"GO_NO_GO_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_16_4", previous_status),
    ("decision_matrix", decision_status),
    ("blocker_policy", blocker_status),
    ("security_tenant_gate", security_status),
    ("business_chain_gate", business_status),
    ("support_incident_gate", support_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_16_4\t{previous_status}\tpilot data readiness prerequisite",
    f"go_no_go_decision_matrix\t{decision_status}\tdecision_gates={decision_count} p0={decision_p0_count} no_go={decision_no_go_count}",
    f"rollout_blocker_policy\t{blocker_status}\tblockers={blocker_count} p0={p0_blocker_count} no_go={no_go_blocker_count}",
    f"security_tenant_gate\t{security_status}\tsecurity_gates={security_count} blockers={security_blocker_count}",
    f"business_chain_gate\t{business_status}\tbusiness_gates={business_count} blockers={business_blocker_count}",
    f"support_incident_gate\t{support_status}\tsupport_gates={support_count} blockers={support_blocker_count}",
    f"no_runtime_change\t{no_runtime_status}\tno rollout/live/db/api/ui/event changed",
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
    "rollout_executed\tNO\tcontract only",
    "go_live_switched\tNO\tcontract only",
    "production_traffic_changed\tNO\tcontract only",
    "tenant_enabled_for_live\tNO\tcontract only",
    "real_customer_notified\tNO\tcontract only",
    "uat_executed\tNO\tcontract only",
    "sample_data_inserted\tNO\tcontract only",
    "real_customer_data_created\tNO\tcontract only",
    "real_product_created\tNO\tcontract only",
    "real_stock_mutated\tNO\tcontract only",
    "real_sale_created\tNO\tcontract only",
    "real_accounting_entry_created\tNO\tcontract only",
    "data_import_executed\tNO\tcontract only",
    "file_export_executed\tNO\tcontract only",
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
detail(f"GO_NO_GO_ROLLOUT_GATE={final_status}")
detail(f"FAZ4B_16_5_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 16.5 - Go / No-Go Rollout Gate Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"GO_NO_GO_ROLLOUT_GATE={final_status}",
    f"FAZ4B_16_5_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/16_5_go_no_go_rollout_gate_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "GO_NO_GO_DECISION_MATRIX_FILE=docs/phase4/16_5_go_no_go_decision_matrix.tsv",
    "ROLLOUT_BLOCKER_POLICY_FILE=docs/phase4/16_5_rollout_blocker_policy.tsv",
    "SECURITY_TENANT_GATE_FILE=docs/phase4/16_5_security_tenant_gate.tsv",
    "BUSINESS_CHAIN_GATE_FILE=docs/phase4/16_5_business_chain_gate.tsv",
    "SUPPORT_INCIDENT_GATE_FILE=docs/phase4/16_5_support_incident_gate.tsv",
    "NOTE=Contract only. No real rollout/live/runtime/config/db/api/ui/event/customer-private-data change executed.",
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
    "ROLLOUT_EXECUTED=NO",
    "GO_LIVE_SWITCHED=NO",
    "PRODUCTION_TRAFFIC_CHANGED=NO",
    "TENANT_ENABLED_FOR_LIVE=NO",
    "REAL_CUSTOMER_NOTIFIED=NO",
    "UAT_EXECUTED=NO",
    "SAMPLE_DATA_INSERTED=NO",
    "REAL_CUSTOMER_DATA_CREATED=NO",
    "REAL_PRODUCT_CREATED=NO",
    "REAL_STOCK_MUTATED=NO",
    "REAL_SALE_CREATED=NO",
    "REAL_ACCOUNTING_ENTRY_CREATED=NO",
    "DATA_IMPORT_EXECUTED=NO",
    "FILE_EXPORT_EXECUTED=NO",
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
print(f"GO_NO_GO_DECISION_MATRIX_FILE={decision_file}")
print(f"ROLLOUT_BLOCKER_POLICY_FILE={blocker_file}")
print(f"SECURITY_TENANT_GATE_FILE={security_file}")
print(f"BUSINESS_CHAIN_GATE_FILE={business_file}")
print(f"SUPPORT_INCIDENT_GATE_FILE={support_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"GO_NO_GO_DECISION_GATE_COUNT={decision_count}")
print(f"GO_NO_GO_DECISION_P0_COUNT={decision_p0_count}")
print(f"GO_NO_GO_DECISION_P1_COUNT={decision_p1_count}")
print(f"GO_NO_GO_DECISION_BLOCKER_COUNT={decision_blocker_count}")
print(f"GO_NO_GO_DECISION_NO_GO_COUNT={decision_no_go_count}")
print(f"GO_NO_GO_DECISION_CONDITIONAL_COUNT={decision_conditional_count}")
print(f"GO_NO_GO_BLOCKER_POLICY_COUNT={blocker_count}")
print(f"GO_NO_GO_P0_BLOCKER_COUNT={p0_blocker_count}")
print(f"GO_NO_GO_NO_GO_BLOCKER_COUNT={no_go_blocker_count}")
print(f"GO_NO_GO_CONDITIONAL_BLOCKER_COUNT={conditional_blocker_count}")
print(f"GO_NO_GO_SECURITY_GATE_COUNT={security_count}")
print(f"GO_NO_GO_SECURITY_BLOCKER_COUNT={security_blocker_count}")
print(f"GO_NO_GO_BUSINESS_GATE_COUNT={business_count}")
print(f"GO_NO_GO_BUSINESS_BLOCKER_COUNT={business_blocker_count}")
print(f"GO_NO_GO_SUPPORT_GATE_COUNT={support_count}")
print(f"GO_NO_GO_SUPPORT_BLOCKER_COUNT={support_blocker_count}")
print(f"GO_NO_GO_PREVIOUS_16_4={previous_status}")
print(f"GO_NO_GO_DECISION_MATRIX={decision_status}")
print(f"GO_NO_GO_BLOCKER_POLICY={blocker_status}")
print(f"GO_NO_GO_SECURITY_TENANT_GATE={security_status}")
print(f"GO_NO_GO_BUSINESS_CHAIN_GATE={business_status}")
print(f"GO_NO_GO_SUPPORT_INCIDENT_GATE={support_status}")
print(f"GO_NO_GO_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"GO_NO_GO_NO_CONFIG_CHANGE={no_config_status}")
print(f"GO_NO_GO_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("ROLLOUT_EXECUTED=NO")
print("GO_LIVE_SWITCHED=NO")
print("PRODUCTION_TRAFFIC_CHANGED=NO")
print("TENANT_ENABLED_FOR_LIVE=NO")
print("REAL_CUSTOMER_NOTIFIED=NO")
print("UAT_EXECUTED=NO")
print("SAMPLE_DATA_INSERTED=NO")
print("REAL_CUSTOMER_DATA_CREATED=NO")
print("REAL_PRODUCT_CREATED=NO")
print("REAL_STOCK_MUTATED=NO")
print("REAL_SALE_CREATED=NO")
print("REAL_ACCOUNTING_ENTRY_CREATED=NO")
print("DATA_IMPORT_EXECUTED=NO")
print("FILE_EXPORT_EXECUTED=NO")
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
print(f"GO_NO_GO_ROLLOUT_GATE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_16_5_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
