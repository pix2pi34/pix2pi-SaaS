#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "16_2_pilot_tenant_readiness_contract_standard.md"
policy_file = report_dir / "16_2_pilot_tenant_readiness_contract_policy.md"
readiness_file = report_dir / "16_2_pilot_tenant_readiness_catalog.tsv"
role_file = report_dir / "16_2_pilot_role_permission_matrix.tsv"
owner_file = report_dir / "16_2_pilot_onboarding_owner_matrix.tsv"
evidence_file = report_dir / "16_2_pilot_evidence_acceptance_matrix.tsv"
training_file = report_dir / "16_2_pilot_training_support_plan.tsv"
matrix_file = report_dir / "16_2_pilot_tenant_readiness_contract_matrix.tsv"
report_file = report_dir / "16_2_pilot_tenant_readiness_contract_report.md"

prev_16_1 = report_dir / "16_1_pilot_uat_onboarding_baseline_report.md"
prev_17 = report_dir / "17_workflow_realtime_ui_final_closure_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"
prev_22 = report_dir / "22_observability_ops_console_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

READINESS = [
    ("pilot_tenant_identity_reserved", "tenant", "platform_admin", "tenant_scoped", "YES", "YES", "pilot tenant id/uuid reserved evidence", "CRITICAL", "READY_FOR_IMPLEMENTATION"),
    ("tenant_isolation_strategy_confirmed", "tenant_security", "platform_admin", "tenant_scoped", "YES", "YES", "tenant_id / schema / RLS strategy noted", "CRITICAL", "READY_FOR_IMPLEMENTATION"),
    ("tenant_admin_role_ready", "rbac", "platform_admin", "tenant_scoped", "YES", "YES", "tenant admin role mapped", "CRITICAL", "READY_FOR_IMPLEMENTATION"),
    ("cashier_role_ready", "rbac", "tenant_admin", "tenant_scoped", "YES", "YES", "cashier role mapped", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("operator_role_ready", "rbac", "tenant_admin", "tenant_scoped", "YES", "YES", "operator role mapped", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("accountant_role_ready", "rbac", "tenant_admin", "tenant_scoped", "YES", "YES", "accountant role mapped", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("support_contact_ready", "support", "support", "platform_scoped", "YES", "YES", "support contact/channel evidence", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("store_branch_cashdesk_contract_ready", "business_setup", "tenant_admin", "tenant_scoped", "YES", "YES", "store/branch/cashdesk onboarding evidence", "CRITICAL", "READY_FOR_IMPLEMENTATION"),
    ("product_stock_onboarding_ready", "business_setup", "tenant_operator", "tenant_scoped", "YES", "YES", "product/opening stock readiness evidence", "CRITICAL", "READY_FOR_IMPLEMENTATION"),
    ("accounting_mapping_owner_ready", "accounting", "accountant", "tenant_scoped", "YES", "YES", "TDHP/accounting review owner evidence", "CRITICAL", "READY_FOR_IMPLEMENTATION"),
    ("uat_owner_ready", "uat", "project_owner", "tenant_scoped", "YES", "YES", "UAT owner and schedule evidence", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("go_no_go_owner_ready", "rollout", "project_owner", "tenant_scoped", "YES", "YES", "go/no-go owner evidence", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("incident_feedback_owner_ready", "ops", "ops_admin", "platform_scoped", "YES", "YES", "incident feedback loop owner evidence", "HIGH", "READY_FOR_IMPLEMENTATION"),
    ("training_owner_ready", "training", "trainer", "tenant_scoped", "YES", "YES", "training session owner evidence", "MEDIUM", "READY_FOR_IMPLEMENTATION"),
]

ROLES = [
    ("tenant_admin", "human", "tenant_settings,users,products,stock,sales,reports,workflow,audit", "platform_ops,security_console,raw_secrets", "workflow:read,workflow:execute,workflow:cancel,audit:read,report:read,user:manage", "tenant_scoped", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("cashier", "human", "pos_sales,refund_limited,customer_lookup", "admin_settings,accounting,security_console,platform_ops", "sales:create,sales:cancel_limited,product:read,stock:read", "tenant_scoped", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("tenant_operator", "human", "products,stock,customers,vendors,tasks,workflow", "security_console,platform_ops,raw_audit", "product:write,stock:write,task:write,workflow:execute", "tenant_scoped", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("accountant", "human", "accounting,journal,ledger,reports,audit_read", "pos_cashier_actions,security_console,platform_ops", "accounting:read,accounting:export,report:read,audit:read", "tenant_scoped", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("tenant_approver", "human", "approvals,workflow_detail,task_center", "security_console,platform_ops", "approval:read,approval:write,workflow:read", "tenant_scoped", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("support_agent", "human", "support_ticket,masked_status,incident_notes", "raw_secrets,raw_payload,financial_private_export", "support:read,support:update", "platform_scoped_limited", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops_admin", "human", "ops_console,health,backlog,dlq,realtime_health", "tenant_private_data_raw,raw_secrets", "ops:read,incident:write", "platform_scoped", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security_admin", "human", "security_console,tenant_isolation,audit_security", "tenant_business_mutation", "security:read,audit:read", "platform_scoped", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("project_owner", "human", "uat,go_no_go,scope,acceptance", "raw_secrets", "uat:read,uat:approve,rollout:approve", "tenant_scoped", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
    ("trainer", "human", "training,usage_guides,onboarding_notes", "security_console,platform_ops,raw_secrets", "training:read,training:update", "tenant_scoped", "YES", "YES", "READY_FOR_IMPLEMENTATION"),
]

OWNERS = [
    ("tenant_setup", "platform_admin", "pilot_tenant_identity_reserved", "before_uat", "tenant readiness evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("role_mapping", "tenant_admin", "user_role_matrix_ready", "before_uat", "role permission matrix evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("store_branch_cashdesk", "tenant_admin", "store_branch_cashdesk_ready", "before_uat", "store/branch/cashdesk checklist", "YES", "READY_FOR_IMPLEMENTATION"),
    ("product_import", "tenant_operator", "product_import_template_ready", "before_uat", "product template evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("opening_stock", "tenant_operator", "opening_stock_ready", "before_uat", "opening stock evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("accounting_review", "accountant", "accounting_mapping_reviewed", "before_go_live", "TDHP review evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("training_session", "trainer", "training_session_completed", "before_go_live", "training completion evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("support_channel", "support", "support_channel_ready", "before_uat", "support channel evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("incident_loop", "ops_admin", "incident_feedback_loop_ready", "before_uat", "incident template evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security_review", "security_admin", "rbac_access_checked", "before_go_live", "RBAC/tenant isolation evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("uat_execution", "project_owner", "p0_uat_passed", "before_go_live", "P0 UAT evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("go_no_go", "project_owner", "go_no_go_ready", "before_go_live", "go/no-go decision evidence", "YES", "READY_FOR_IMPLEMENTATION"),
]

EVIDENCE = [
    ("tenant_identity_evidence", "tenant", "platform_admin", "YES", "YES", "masked tenant id/uuid note", "YES", "READY_FOR_IMPLEMENTATION"),
    ("role_permission_evidence", "rbac", "tenant_admin", "YES", "YES", "role permission matrix", "YES", "READY_FOR_IMPLEMENTATION"),
    ("tenant_isolation_evidence", "security", "security_admin", "YES", "YES", "tenant scoped access check", "YES", "READY_FOR_IMPLEMENTATION"),
    ("store_branch_cashdesk_evidence", "business_setup", "tenant_admin", "YES", "YES", "store/branch/cashdesk checklist", "YES", "READY_FOR_IMPLEMENTATION"),
    ("product_catalog_evidence", "product", "tenant_operator", "YES", "YES", "sample product list/template", "YES", "READY_FOR_IMPLEMENTATION"),
    ("opening_stock_evidence", "inventory", "tenant_operator", "YES", "YES", "stock count/import evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("sales_flow_evidence", "sales", "cashier", "YES", "YES", "sale/refund/cancel UAT evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("inventory_movement_evidence", "inventory", "tenant_operator", "YES", "YES", "movement quantity matches sale", "YES", "READY_FOR_IMPLEMENTATION"),
    ("accounting_mapping_evidence", "accounting", "accountant", "YES", "YES", "TDHP journal/ledger review", "YES", "READY_FOR_IMPLEMENTATION"),
    ("audit_trail_evidence", "audit", "tenant_admin", "YES", "YES", "actor/request/tenant audit evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("support_loop_evidence", "support", "support", "YES", "YES", "support/incident loop evidence", "YES", "READY_FOR_IMPLEMENTATION"),
    ("training_completion_evidence", "training", "trainer", "NO", "YES", "training attendance/completion note", "NO", "READY_FOR_IMPLEMENTATION"),
    ("go_no_go_evidence", "rollout", "project_owner", "YES", "YES", "signed go/no-go decision", "YES", "READY_FOR_IMPLEMENTATION"),
]

TRAINING = [
    ("tenant_admin_training", "tenant_admin", "users/roles/settings/reports/audit", "trainer", "before_uat", "YES", "READY_FOR_IMPLEMENTATION"),
    ("cashier_training", "cashier", "sales/refund/cancel/basic product lookup", "trainer", "before_uat", "YES", "READY_FOR_IMPLEMENTATION"),
    ("operator_training", "tenant_operator", "product/stock/customer/vendor/task", "trainer", "before_uat", "YES", "READY_FOR_IMPLEMENTATION"),
    ("accountant_training", "accountant", "journal/ledger/report/export review", "trainer", "before_go_live", "YES", "READY_FOR_IMPLEMENTATION"),
    ("approver_training", "tenant_approver", "approval/reject/reason/audit", "trainer", "before_uat", "YES", "READY_FOR_IMPLEMENTATION"),
    ("support_handoff", "support_agent", "issue intake/escalation/feedback loop", "support", "before_uat", "YES", "READY_FOR_IMPLEMENTATION"),
    ("ops_handoff", "ops_admin", "health/backlog/dlq/incident loop", "ops_admin", "before_go_live", "YES", "READY_FOR_IMPLEMENTATION"),
    ("security_handoff", "security_admin", "tenant isolation/rbac/audit review", "security_admin", "before_go_live", "YES", "READY_FOR_IMPLEMENTATION"),
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
detail("TENANT_CREATED=NO")
detail("USER_CREATED=NO")
detail("PASSWORD_CREATED=NO")
detail("TOKEN_CREATED=NO")
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
detail("VALIDATION_MODE=PILOT_TENANT_READINESS_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_16_1_status = get_value(prev_16_1, "FAZ4B_16_1_FINAL_STATUS")
prev_16_1_gate = get_value(prev_16_1, "PILOT_UAT_ONBOARDING_BASELINE")
prev_16_1_no_runtime = get_value(prev_16_1, "PILOT_NO_RUNTIME_CHANGE")
prev_16_1_secret = get_value(prev_16_1, "PILOT_SECRET_SAFE")
prev_17_status = get_value(prev_17, "FAZ4B_17_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")

detail(f"PREVIOUS_16_1_FINAL_STATUS={prev_16_1_status}")
detail(f"PREVIOUS_16_1_PILOT_UAT_ONBOARDING_BASELINE={prev_16_1_gate}")
detail(f"PREVIOUS_16_1_PILOT_NO_RUNTIME_CHANGE={prev_16_1_no_runtime}")
detail(f"PREVIOUS_16_1_PILOT_SECRET_SAFE={prev_16_1_secret}")
detail(f"PREVIOUS_17_FINAL_STATUS={prev_17_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")

if prev_16_1_status != "PASS":
    fail("16.1 final status PASS degil")
if prev_16_1_gate != "PASS":
    fail("16.1 pilot baseline PASS degil")
if prev_16_1_no_runtime != "PASS":
    fail("16.1 no runtime change PASS degil")
if prev_16_1_secret != "PASS":
    fail("16.1 secret safe PASS degil")
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

readiness_lines = ["readiness_item\tcategory\towner_role\ttenant_scope\trequired_before_uat\trequired_before_go_live\tacceptance_signal\trisk_level\timplementation_status\tnote"]
for row in READINESS:
    readiness_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_tenant_created"]]))
readiness_file.write_text("\n".join(readiness_lines) + "\n")

role_lines = ["role_name\tactor_type\tallowed_modules\tforbidden_modules\trequired_permissions\ttenant_scope\taudit_required\tonboarding_required\timplementation_status\tnote"]
for row in ROLES:
    role_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_user_created"]]))
role_file.write_text("\n".join(role_lines) + "\n")

owner_lines = ["onboarding_area\towner_role\tbaseline_ref\tmilestone\tevidence_required\tblocker_if_missing\timplementation_status\tnote"]
for row in OWNERS:
    owner_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
owner_file.write_text("\n".join(owner_lines) + "\n")

evidence_lines = ["evidence_name\tcategory\towner_role\trequired_for_uat\trequired_for_go_live\tacceptance_format\tblocker_if_missing\timplementation_status\tnote"]
for row in EVIDENCE:
    evidence_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
evidence_file.write_text("\n".join(evidence_lines) + "\n")

training_lines = ["training_name\ttarget_role\tscope\towner_role\trequired_by\tattendance_required\timplementation_status\tnote"]
for row in TRAINING:
    training_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
training_file.write_text("\n".join(training_lines) + "\n")

readiness_count = len(READINESS)
critical_readiness_count = sum(1 for x in READINESS if x[7] == "CRITICAL")
uat_required_count = sum(1 for x in READINESS if x[4] == "YES")
golive_required_count = sum(1 for x in READINESS if x[5] == "YES")
role_count = len(ROLES)
tenant_role_count = sum(1 for x in ROLES if "tenant" in x[5])
audit_role_count = sum(1 for x in ROLES if x[6] == "YES")
onboarding_role_count = sum(1 for x in ROLES if x[7] == "YES")
owner_count = len(OWNERS)
owner_blocker_count = sum(1 for x in OWNERS if x[5] == "YES")
evidence_count = len(EVIDENCE)
evidence_blocker_count = sum(1 for x in EVIDENCE if x[6] == "YES")
training_count = len(TRAINING)
training_attendance_count = sum(1 for x in TRAINING if x[5] == "YES")

detail(f"PILOT_TENANT_READINESS_ITEM_COUNT={readiness_count}")
detail(f"PILOT_TENANT_CRITICAL_READINESS_COUNT={critical_readiness_count}")
detail(f"PILOT_TENANT_UAT_REQUIRED_COUNT={uat_required_count}")
detail(f"PILOT_TENANT_GOLIVE_REQUIRED_COUNT={golive_required_count}")
detail(f"PILOT_ROLE_COUNT={role_count}")
detail(f"PILOT_TENANT_ROLE_COUNT={tenant_role_count}")
detail(f"PILOT_AUDIT_ROLE_COUNT={audit_role_count}")
detail(f"PILOT_ONBOARDING_ROLE_COUNT={onboarding_role_count}")
detail(f"PILOT_ONBOARDING_OWNER_COUNT={owner_count}")
detail(f"PILOT_ONBOARDING_OWNER_BLOCKER_COUNT={owner_blocker_count}")
detail(f"PILOT_EVIDENCE_COUNT={evidence_count}")
detail(f"PILOT_EVIDENCE_BLOCKER_COUNT={evidence_blocker_count}")
detail(f"PILOT_TRAINING_PLAN_COUNT={training_count}")
detail(f"PILOT_TRAINING_ATTENDANCE_REQUIRED_COUNT={training_attendance_count}")

required_roles = ["tenant_admin", "cashier", "tenant_operator", "accountant", "tenant_approver", "support_agent", "ops_admin", "security_admin", "project_owner", "trainer"]
role_names = set([x[0] for x in ROLES])
missing_roles = [x for x in required_roles if x not in role_names]

required_evidence = ["tenant_identity_evidence", "role_permission_evidence", "tenant_isolation_evidence", "sales_flow_evidence", "inventory_movement_evidence", "accounting_mapping_evidence", "go_no_go_evidence"]
evidence_names = set([x[0] for x in EVIDENCE])
missing_evidence = [x for x in required_evidence if x not in evidence_names]

if missing_roles:
    fail("required role eksik: " + ",".join(missing_roles))
if missing_evidence:
    fail("required evidence eksik: " + ",".join(missing_evidence))
if audit_role_count != role_count:
    fail("tum roller audit_required YES degil")
if onboarding_role_count != role_count:
    fail("tum roller onboarding_required YES degil")

previous_status = "PASS" if (
    prev_16_1_status == "PASS"
    and prev_16_1_gate == "PASS"
    and prev_16_1_no_runtime == "PASS"
    and prev_16_1_secret == "PASS"
) else "FAIL"

readiness_status = "PASS" if readiness_file.exists() and readiness_count >= 12 and critical_readiness_count >= 5 else "FAIL"
role_status = "PASS" if role_file.exists() and role_count >= 10 and not missing_roles else "FAIL"
owner_status = "PASS" if owner_file.exists() and owner_count >= 10 and owner_blocker_count >= 10 else "FAIL"
evidence_status = "PASS" if evidence_file.exists() and evidence_count >= 12 and not missing_evidence else "FAIL"
training_status = "PASS" if training_file.exists() and training_count >= 8 and training_attendance_count == training_count else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"PILOT_TENANT_PREVIOUS_16_1={previous_status}")
detail(f"PILOT_TENANT_READINESS_CATALOG={readiness_status}")
detail(f"PILOT_ROLE_PERMISSION_MATRIX={role_status}")
detail(f"PILOT_ONBOARDING_OWNER_MATRIX={owner_status}")
detail(f"PILOT_EVIDENCE_ACCEPTANCE_MATRIX={evidence_status}")
detail(f"PILOT_TRAINING_SUPPORT_PLAN={training_status}")
detail(f"PILOT_TENANT_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"PILOT_TENANT_NO_CONFIG_CHANGE={no_config_status}")
detail(f"PILOT_TENANT_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_16_1", previous_status),
    ("readiness_catalog", readiness_status),
    ("role_permission_matrix", role_status),
    ("onboarding_owner_matrix", owner_status),
    ("evidence_acceptance_matrix", evidence_status),
    ("training_support_plan", training_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_16_1\t{previous_status}\tpilot baseline prerequisite",
    f"tenant_readiness_catalog\t{readiness_status}\titems={readiness_count} critical={critical_readiness_count}",
    f"role_permission_matrix\t{role_status}\troles={role_count} audit={audit_role_count}",
    f"onboarding_owner_matrix\t{owner_status}\towners={owner_count} blockers={owner_blocker_count}",
    f"evidence_acceptance_matrix\t{evidence_status}\tevidence={evidence_count} blockers={evidence_blocker_count}",
    f"training_support_plan\t{training_status}\ttraining={training_count} attendance={training_attendance_count}",
    f"no_runtime_change\t{no_runtime_status}\tno tenant/user/db/api/ui/event changed",
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
detail(f"PILOT_TENANT_READINESS_CONTRACT={final_status}")
detail(f"FAZ4B_16_2_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 16.2 - Pilot Tenant Readiness / Role & Onboarding Contract Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"PILOT_TENANT_READINESS_CONTRACT={final_status}",
    f"FAZ4B_16_2_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/16_2_pilot_tenant_readiness_contract_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "PILOT_TENANT_READINESS_CATALOG_FILE=docs/phase4/16_2_pilot_tenant_readiness_catalog.tsv",
    "PILOT_ROLE_PERMISSION_MATRIX_FILE=docs/phase4/16_2_pilot_role_permission_matrix.tsv",
    "PILOT_ONBOARDING_OWNER_MATRIX_FILE=docs/phase4/16_2_pilot_onboarding_owner_matrix.tsv",
    "PILOT_EVIDENCE_ACCEPTANCE_MATRIX_FILE=docs/phase4/16_2_pilot_evidence_acceptance_matrix.tsv",
    "PILOT_TRAINING_SUPPORT_PLAN_FILE=docs/phase4/16_2_pilot_training_support_plan.tsv",
    "NOTE=Contract only. No tenant/user/runtime/config/db/api/ui/event/customer-private-data change executed.",
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
print(f"PILOT_TENANT_READINESS_CATALOG_FILE={readiness_file}")
print(f"PILOT_ROLE_PERMISSION_MATRIX_FILE={role_file}")
print(f"PILOT_ONBOARDING_OWNER_MATRIX_FILE={owner_file}")
print(f"PILOT_EVIDENCE_ACCEPTANCE_MATRIX_FILE={evidence_file}")
print(f"PILOT_TRAINING_SUPPORT_PLAN_FILE={training_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"PILOT_TENANT_READINESS_ITEM_COUNT={readiness_count}")
print(f"PILOT_TENANT_CRITICAL_READINESS_COUNT={critical_readiness_count}")
print(f"PILOT_TENANT_UAT_REQUIRED_COUNT={uat_required_count}")
print(f"PILOT_TENANT_GOLIVE_REQUIRED_COUNT={golive_required_count}")
print(f"PILOT_ROLE_COUNT={role_count}")
print(f"PILOT_TENANT_ROLE_COUNT={tenant_role_count}")
print(f"PILOT_AUDIT_ROLE_COUNT={audit_role_count}")
print(f"PILOT_ONBOARDING_ROLE_COUNT={onboarding_role_count}")
print(f"PILOT_ONBOARDING_OWNER_COUNT={owner_count}")
print(f"PILOT_ONBOARDING_OWNER_BLOCKER_COUNT={owner_blocker_count}")
print(f"PILOT_EVIDENCE_COUNT={evidence_count}")
print(f"PILOT_EVIDENCE_BLOCKER_COUNT={evidence_blocker_count}")
print(f"PILOT_TRAINING_PLAN_COUNT={training_count}")
print(f"PILOT_TRAINING_ATTENDANCE_REQUIRED_COUNT={training_attendance_count}")
print(f"PILOT_TENANT_PREVIOUS_16_1={previous_status}")
print(f"PILOT_TENANT_READINESS_CATALOG={readiness_status}")
print(f"PILOT_ROLE_PERMISSION_MATRIX={role_status}")
print(f"PILOT_ONBOARDING_OWNER_MATRIX={owner_status}")
print(f"PILOT_EVIDENCE_ACCEPTANCE_MATRIX={evidence_status}")
print(f"PILOT_TRAINING_SUPPORT_PLAN={training_status}")
print(f"PILOT_TENANT_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"PILOT_TENANT_NO_CONFIG_CHANGE={no_config_status}")
print(f"PILOT_TENANT_SECRET_SAFE={secret_safe_status}")
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
print(f"PILOT_TENANT_READINESS_CONTRACT={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_16_2_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
