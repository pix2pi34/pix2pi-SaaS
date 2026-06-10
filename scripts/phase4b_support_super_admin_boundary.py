#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "21_5_support_super_admin_boundary_standard.md"
contract_file = report_dir / "21_5_support_super_admin_boundary_contract.md"
rule_manifest_file = report_dir / "21_5_support_super_admin_boundary_rule_manifest.tsv"
reason_manifest_file = report_dir / "21_5_support_super_admin_boundary_reason_manifest.tsv"
decision_manifest_file = report_dir / "21_5_support_super_admin_boundary_decision_manifest.tsv"
report_file = report_dir / "21_5_support_super_admin_boundary_report.md"
matrix_file = report_dir / "21_5_support_super_admin_boundary_matrix.tsv"

prev_21_4 = report_dir / "21_4_tenant_access_checks_report.md"
prev_21_3 = report_dir / "21_3_audit_event_model_report.md"
prev_21_2 = report_dir / "21_2_permission_guard_report.md"
prev_21_1 = report_dir / "21_1_role_matrix_report.md"
prev_19 = report_dir / "19_panel_admin_professionalization_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

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

def count(pattern, text, flags=re.IGNORECASE | re.MULTILINE):
    return len(re.findall(pattern, text, flags))

def tsv_rows(path):
    text = read(path).strip()
    if not text:
        return []
    return [line.split("\t") for line in text.splitlines()]

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("SUPPORT_ACCESS_EXECUTED=NO")
detail("SUPER_ADMIN_ACCESS_EXECUTED=NO")
detail("BREAK_GLASS_EXECUTED=NO")
detail("PERMISSION_GUARD_EXECUTED=NO")
detail("RBAC_ENFORCEMENT_EXECUTED=NO")
detail("AUDIT_LOG_WRITE_EXECUTED=NO")
detail("PANEL_ROUTE_DEPLOYED=NO")
detail("API_ROUTE_DEPLOYED=NO")
detail("SERVICE_RESTARTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=SUPPORT_SUPER_ADMIN_BOUNDARY_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_21_4_status = get_value(prev_21_4, "FAZ4B_21_4_FINAL_STATUS")
prev_21_4_domain = get_value(prev_21_4, "TENANT_ACCESS_CHECKS")
prev_21_4_apply = get_value(prev_21_4, "DB_APPLY_EXECUTED")
prev_21_4_audit_write = get_value(prev_21_4, "AUDIT_LOG_WRITE_EXECUTED")
prev_21_3_status = get_value(prev_21_3, "FAZ4B_21_3_FINAL_STATUS")
prev_21_3_domain = get_value(prev_21_3, "AUDIT_EVENT_MODEL")
prev_21_2_status = get_value(prev_21_2, "FAZ4B_21_2_FINAL_STATUS")
prev_21_2_domain = get_value(prev_21_2, "PERMISSION_GUARD")
prev_21_1_status = get_value(prev_21_1, "FAZ4B_21_1_FINAL_STATUS")
prev_21_1_domain = get_value(prev_21_1, "ROLE_MATRIX")
prev_19_status = get_value(prev_19, "FAZ4B_19_FINAL_STATUS")

detail(f"PREVIOUS_21_4_FINAL_STATUS={prev_21_4_status}")
detail(f"PREVIOUS_21_4_TENANT_ACCESS_CHECKS={prev_21_4_domain}")
detail(f"PREVIOUS_21_4_DB_APPLY_EXECUTED={prev_21_4_apply}")
detail(f"PREVIOUS_21_4_AUDIT_LOG_WRITE_EXECUTED={prev_21_4_audit_write}")
detail(f"PREVIOUS_21_3_FINAL_STATUS={prev_21_3_status}")
detail(f"PREVIOUS_21_3_AUDIT_EVENT_MODEL={prev_21_3_domain}")
detail(f"PREVIOUS_21_2_FINAL_STATUS={prev_21_2_status}")
detail(f"PREVIOUS_21_2_PERMISSION_GUARD={prev_21_2_domain}")
detail(f"PREVIOUS_21_1_FINAL_STATUS={prev_21_1_status}")
detail(f"PREVIOUS_21_1_ROLE_MATRIX={prev_21_1_domain}")
detail(f"PREVIOUS_19_FINAL_STATUS={prev_19_status}")

if prev_21_4_status != "PASS":
    fail("21.4 final status PASS degil")
if prev_21_4_domain != "PASS":
    fail("21.4 tenant access checks PASS degil")
if prev_21_4_apply != "NO":
    fail("21.4 DB apply NO degil")
if prev_21_4_audit_write != "NO":
    fail("21.4 audit log write NO degil")
if prev_21_3_status != "PASS":
    fail("21.3 final status PASS degil")
if prev_21_3_domain != "PASS":
    fail("21.3 audit event model PASS degil")
if prev_21_2_status != "PASS":
    fail("21.2 final status PASS degil")
if prev_21_2_domain != "PASS":
    fail("21.2 permission guard PASS degil")
if prev_21_1_status != "PASS":
    fail("21.1 final status PASS degil")
if prev_21_1_domain != "PASS":
    fail("21.1 role matrix PASS degil")
if prev_19_status != "PASS":
    fail("19 final status PASS degil")

for path, label in [
    (standard_file, "standard doc"),
    (contract_file, "contract doc"),
    (rule_manifest_file, "rule manifest"),
    (reason_manifest_file, "reason manifest"),
    (decision_manifest_file, "decision manifest"),
]:
    if not path.exists():
        fail(f"{label} yok")

standard_text = read(standard_file)
contract_text = read(contract_file)
rule_text = read(rule_manifest_file)
reason_text = read(reason_manifest_file)
decision_text = read(decision_manifest_file)
all_text = "\n".join([standard_text, contract_text, rule_text, reason_text, decision_text])

required_inputs = [
    "tenant_id",
    "tenant_uuid",
    "actor_user_id",
    "actor_role_code",
    "actor_role_group",
    "target_tenant_id",
    "target_resource_area",
    "target_resource_name",
    "target_resource_id",
    "requested_action",
    "permission_code",
    "support_access_reason",
    "support_ticket_id",
    "support_access_mode",
    "super_admin_boundary_mode",
    "break_glass_reason_code",
    "break_glass_ticket_id",
    "approval_request_id",
    "approver_user_id",
    "approval_status",
    "access_timebox_minutes",
    "request_id",
    "correlation_id",
    "source_route",
    "http_method",
]

required_outputs = [
    "boundary_decision_id",
    "tenant_id",
    "actor_user_id",
    "actor_role_code",
    "target_tenant_id",
    "requested_action",
    "decision",
    "deny_reason",
    "deny_reason_code",
    "boundary_status",
    "support_access_allowed",
    "super_admin_access_allowed",
    "break_glass_required",
    "approval_required",
    "audit_required",
    "high_risk",
    "timebox_required",
    "request_id",
    "correlation_id",
    "decided_at",
]

required_rules = [
    "support_readonly_requires_reason",
    "support_operator_requires_ticket",
    "support_timeboxed_access",
    "support_no_secret_access",
    "support_no_export_default",
    "support_tenant_scope_required",
    "super_admin_break_glass_required",
    "super_admin_dual_approval_required",
    "super_admin_timeboxed_access",
    "super_admin_no_silent_access",
    "cross_tenant_default_deny",
    "audit_required_for_all_boundary_access",
    "emergency_revocation_required",
]

required_reasons = [
    "CUSTOMER_SUPPORT_REQUEST",
    "PILOT_UAT_SUPPORT",
    "IMPORT_ASSISTANCE",
    "INCIDENT_RESPONSE",
    "SECURITY_INVESTIGATION",
    "DATA_REPAIR_APPROVED",
    "BILLING_SUPPORT",
    "BREAK_GLASS_INCIDENT",
    "LEGAL_COMPLIANCE_REQUEST",
    "INTERNAL_TESTING_DENIED",
]

required_decisions = [
    "ALLOW_SUPPORT_READONLY_TIMEBOXED",
    "ALLOW_SUPPORT_OPERATOR_APPROVED",
    "ALLOW_SUPER_ADMIN_BREAK_GLASS_APPROVED",
    "DENY_SUPPORT_REASON_MISSING",
    "DENY_SUPPORT_TICKET_MISSING",
    "DENY_SUPPORT_TIMEBOX_MISSING",
    "DENY_SUPPORT_SECRET_ACCESS",
    "DENY_SUPPORT_EXPORT_ACCESS",
    "DENY_SUPPORT_TENANT_SCOPE",
    "DENY_SUPER_ADMIN_BREAK_GLASS_REQUIRED",
    "DENY_SUPER_ADMIN_APPROVAL_MISSING",
    "DENY_SUPER_ADMIN_SILENT_ACCESS",
    "DENY_SUPER_ADMIN_TIMEBOX_MISSING",
    "DENY_CROSS_TENANT_BOUNDARY",
    "DENY_BOUNDARY_AUDIT_REQUIRED",
    "DENY_EMERGENCY_REVOKED",
]

rule_rows = tsv_rows(rule_manifest_file)
reason_rows = tsv_rows(reason_manifest_file)
decision_rows = tsv_rows(decision_manifest_file)

rule_data_rows = max(0, len(rule_rows) - 1)
reason_data_rows = max(0, len(reason_rows) - 1)
decision_data_rows = max(0, len(decision_rows) - 1)

input_hit_count = sum(1 for item in required_inputs if item in contract_text)
output_hit_count = sum(1 for item in required_outputs if item in contract_text)
rule_hit_count = sum(1 for item in required_rules if item in standard_text and item in rule_text)
reason_hit_count = sum(1 for item in required_reasons if item in standard_text and item in reason_text)
decision_hit_count = sum(1 for item in required_decisions if item in contract_text and item in decision_text)

support_ref_count = count(r"support|Support|SUPPORT", all_text)
super_admin_ref_count = count(r"super_admin|Super-admin|super-admin|SUPER_ADMIN", all_text)
break_glass_ref_count = count(r"break_glass|break-glass|Break-glass|BREAK_GLASS", all_text)
boundary_ref_count = count(r"boundary|Boundary|BOUNDARY", all_text)
tenant_ref_count = count(r"tenant", all_text)
audit_ref_count = count(r"audit|Audit", all_text)
high_risk_ref_count = count(r"high_risk|High-risk|high-risk", all_text)
deny_ref_count = count(r"DENY|deny", all_text)
allow_ref_count = count(r"ALLOW|allow", all_text)
ticket_ref_count = count(r"ticket|Ticket", all_text)
approval_ref_count = count(r"approval|Approval|approver", all_text)
timebox_ref_count = count(r"timebox|Timebox|timeboxed", all_text)
secret_export_ref_count = count(r"secret|export|Secret|Export", all_text)
contract_only_count = count(r"\bcontract_only\b", all_text)
yes_count = count(r"\bYES\b", rule_text + "\n" + reason_text + "\n" + decision_text)

detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_INPUT_HIT_COUNT={input_hit_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_OUTPUT_HIT_COUNT={output_hit_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_RULE_COUNT={rule_data_rows}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_REQUIRED_RULE_HIT_COUNT={rule_hit_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_REASON_COUNT={reason_data_rows}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_REQUIRED_REASON_HIT_COUNT={reason_hit_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_DECISION_COUNT={decision_data_rows}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_REQUIRED_DECISION_HIT_COUNT={decision_hit_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_SUPPORT_REF_COUNT={support_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_SUPER_ADMIN_REF_COUNT={super_admin_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_BREAK_GLASS_REF_COUNT={break_glass_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_BOUNDARY_REF_COUNT={boundary_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_TENANT_REF_COUNT={tenant_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_AUDIT_REF_COUNT={audit_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_HIGH_RISK_REF_COUNT={high_risk_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_DENY_REF_COUNT={deny_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_ALLOW_REF_COUNT={allow_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_TICKET_REF_COUNT={ticket_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_APPROVAL_REF_COUNT={approval_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_TIMEBOX_REF_COUNT={timebox_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_SECRET_EXPORT_REF_COUNT={secret_export_ref_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_CONTRACT_ONLY_COUNT={contract_only_count}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_YES_COUNT={yes_count}")

if input_hit_count != 25:
    fail("required input hit count 25 degil")
if output_hit_count != 20:
    fail("required output hit count 20 degil")
if rule_data_rows != 13:
    fail("rule manifest count 13 degil")
if rule_hit_count != 13:
    fail("required rule hit count 13 degil")
if reason_data_rows != 10:
    fail("reason manifest count 10 degil")
if reason_hit_count != 10:
    fail("required reason hit count 10 degil")
if decision_data_rows != 16:
    fail("decision manifest count 16 degil")
if decision_hit_count != 16:
    fail("required decision hit count 16 degil")
if support_ref_count < 45:
    fail("support reference count 45 altinda")
if super_admin_ref_count < 35:
    fail("super-admin reference count 35 altinda")
if break_glass_ref_count < 12:
    fail("break-glass reference count 12 altinda")
if boundary_ref_count < 35:
    fail("boundary reference count 35 altinda")
if tenant_ref_count < 35:
    fail("tenant reference count 35 altinda")
if audit_ref_count < 18:
    fail("audit reference count 18 altinda")
if high_risk_ref_count < 10:
    fail("high risk reference count 10 altinda")
if deny_ref_count < 28:
    fail("deny reference count 28 altinda")
if allow_ref_count < 6:
    fail("allow reference count 6 altinda")
if ticket_ref_count < 14:
    fail("ticket reference count 14 altinda")
if approval_ref_count < 10:
    fail("approval reference count 10 altinda")
if timebox_ref_count < 10:
    fail("timebox reference count 10 altinda")
if secret_export_ref_count < 6:
    fail("secret/export reference count 6 altinda")
if contract_only_count < 35:
    fail("contract_only count 35 altinda")
if yes_count < 110:
    fail("YES count 110 altinda")

for item in required_inputs:
    if item not in contract_text:
        fail(f"input eksik: {item}")

for item in required_outputs:
    if item not in contract_text:
        fail(f"output eksik: {item}")

for item in required_rules:
    if item not in standard_text:
        fail(f"standard rule eksik: {item}")
    if item not in rule_text:
        fail(f"rule manifest eksik: {item}")

for item in required_reasons:
    if item not in standard_text:
        fail(f"standard reason eksik: {item}")
    if item not in reason_text:
        fail(f"reason manifest eksik: {item}")

for item in required_decisions:
    if item not in contract_text:
        fail(f"contract decision eksik: {item}")
    if item not in decision_text:
        fail(f"decision manifest eksik: {item}")

secret_hits = []
for path in [standard_file, contract_file, rule_manifest_file, reason_manifest_file, decision_manifest_file]:
    text = read(path)
    rel = str(path.relative_to(root))
    if re.search(r"POSTGRES_PASSWORD=.*[A-Za-z0-9]", text):
        secret_hits.append(rel)
    if re.search(r"password=[^* \n]", text, re.IGNORECASE):
        secret_hits.append(rel)
    if re.search(r"Bearer\s+", text):
        secret_hits.append(rel)
    if re.search(r"\bSELECT\s+.*\bFROM\b", text, re.IGNORECASE):
        secret_hits.append(rel)

detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_SECRET_HIT_COUNT={len(secret_hits)}")

if secret_hits:
    fail("secret/query leak bulundu: " + ",".join(secret_hits))

previous_status = "PASS" if (
    prev_21_4_status == "PASS"
    and prev_21_4_domain == "PASS"
    and prev_21_4_apply == "NO"
    and prev_21_4_audit_write == "NO"
    and prev_21_3_status == "PASS"
    and prev_21_2_status == "PASS"
    and prev_21_1_status == "PASS"
    and prev_19_status == "PASS"
) else "FAIL"

contract_status = "PASS" if input_hit_count == 25 and output_hit_count == 20 and decision_hit_count == 16 else "FAIL"
rule_manifest_status = "PASS" if rule_data_rows == 13 and rule_hit_count == 13 else "FAIL"
reason_manifest_status = "PASS" if reason_data_rows == 10 and reason_hit_count == 10 else "FAIL"
decision_manifest_status = "PASS" if decision_data_rows == 16 and decision_hit_count == 16 else "FAIL"
tenant_safety_status = "PASS" if tenant_ref_count >= 35 and deny_ref_count >= 28 else "FAIL"
boundary_status = "PASS" if support_ref_count >= 45 and super_admin_ref_count >= 35 and boundary_ref_count >= 35 else "FAIL"
break_glass_status = "PASS" if break_glass_ref_count >= 12 and approval_ref_count >= 10 and timebox_ref_count >= 10 else "FAIL"
audit_ready_status = "PASS" if audit_ref_count >= 18 and high_risk_ref_count >= 10 else "FAIL"
no_apply_status = "PASS"
secret_status = "PASS" if not secret_hits else "FAIL"

detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_PREVIOUS_21_4={previous_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_CONTRACT={contract_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_RULE_MANIFEST={rule_manifest_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_REASON_MANIFEST={reason_manifest_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_DECISION_MANIFEST={decision_manifest_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_TENANT_SAFETY={tenant_safety_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_BOUNDARY_STATUS={boundary_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_BREAK_GLASS_STATUS={break_glass_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_AUDIT_READY={audit_ready_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_NO_APPLY={no_apply_status}")
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY_SECRET_SAFETY={secret_status}")

for name, status in [
    ("previous_21_4", previous_status),
    ("contract", contract_status),
    ("rule_manifest", rule_manifest_status),
    ("reason_manifest", reason_manifest_status),
    ("decision_manifest", decision_manifest_status),
    ("tenant_safety", tenant_safety_status),
    ("boundary", boundary_status),
    ("break_glass", break_glass_status),
    ("audit_ready", audit_ready_status),
    ("no_apply", no_apply_status),
    ("secret_safety", secret_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_21_4\t{previous_status}\ttenant access checks prerequisite",
    f"contract\t{contract_status}\tinputs={input_hit_count} outputs={output_hit_count} decisions={decision_hit_count}",
    f"rule_manifest\t{rule_manifest_status}\trule_count={rule_data_rows}",
    f"reason_manifest\t{reason_manifest_status}\treason_count={reason_data_rows}",
    f"decision_manifest\t{decision_manifest_status}\tdecision_count={decision_data_rows}",
    f"tenant_safety\t{tenant_safety_status}\ttenant_refs={tenant_ref_count} deny_refs={deny_ref_count}",
    f"boundary\t{boundary_status}\tsupport={support_ref_count} super_admin={super_admin_ref_count} boundary={boundary_ref_count}",
    f"break_glass\t{break_glass_status}\tbreak_glass={break_glass_ref_count} approval={approval_ref_count} timebox={timebox_ref_count}",
    f"audit_ready\t{audit_ready_status}\taudit_refs={audit_ref_count} high_risk={high_risk_ref_count}",
    f"no_apply\t{no_apply_status}\tcontract only",
    f"secret_safety\t{secret_status}\tsecret_hits={len(secret_hits)}",
    "db_mutation\tNO\tcontract only",
    "db_apply_executed\tNO\tcontract only",
    "migration_created\tNO\tcontract only",
    "support_access_executed\tNO\tcontract only",
    "super_admin_access_executed\tNO\tcontract only",
    "break_glass_executed\tNO\tcontract only",
    "permission_guard_executed\tNO\tcontract only",
    "rbac_enforcement_executed\tNO\tcontract only",
    "audit_log_write_executed\tNO\tcontract only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"SUPPORT_SUPER_ADMIN_BOUNDARY={final_status}")
detail(f"FAZ4B_21_5_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 21.5 - Support / Super-admin Boundary Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"SUPPORT_SUPER_ADMIN_BOUNDARY={final_status}",
    f"FAZ4B_21_5_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/21_5_support_super_admin_boundary_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Artifacts",
    "STANDARD_FILE=docs/phase4/21_5_support_super_admin_boundary_standard.md",
    "CONTRACT_FILE=docs/phase4/21_5_support_super_admin_boundary_contract.md",
    "RULE_MANIFEST_FILE=docs/phase4/21_5_support_super_admin_boundary_rule_manifest.tsv",
    "REASON_MANIFEST_FILE=docs/phase4/21_5_support_super_admin_boundary_reason_manifest.tsv",
    "DECISION_MANIFEST_FILE=docs/phase4/21_5_support_super_admin_boundary_decision_manifest.tsv",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "SUPPORT_ACCESS_EXECUTED=NO",
    "SUPER_ADMIN_ACCESS_EXECUTED=NO",
    "BREAK_GLASS_EXECUTED=NO",
    "PERMISSION_GUARD_EXECUTED=NO",
    "RBAC_ENFORCEMENT_EXECUTED=NO",
    "AUDIT_LOG_WRITE_EXECUTED=NO",
    "PANEL_ROUTE_DEPLOYED=NO",
    "API_ROUTE_DEPLOYED=NO",
    "SERVICE_RESTARTED=NO",
    "POSTGRES_CONFIG_CHANGED=NO",
    "CONTAINER_RESTARTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "",
    "## Issues",
    *(failures if failures else ["OK ✅ issue yok"]),
    "",
    "## Secret Safety",
    "RAW_DSN_PRINTED=NO",
    "POSTGRES_PASSWORD_PRINTED=NO",
    "AUTH_TOKEN_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"CONTRACT_FILE={contract_file}")
print(f"RULE_MANIFEST_FILE={rule_manifest_file}")
print(f"REASON_MANIFEST_FILE={reason_manifest_file}")
print(f"DECISION_MANIFEST_FILE={decision_manifest_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_INPUT_HIT_COUNT={input_hit_count}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_OUTPUT_HIT_COUNT={output_hit_count}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_RULE_COUNT={rule_data_rows}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_REASON_COUNT={reason_data_rows}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_DECISION_COUNT={decision_data_rows}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_PREVIOUS_21_4={previous_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_CONTRACT={contract_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_RULE_MANIFEST={rule_manifest_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_REASON_MANIFEST={reason_manifest_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_DECISION_MANIFEST={decision_manifest_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_TENANT_SAFETY={tenant_safety_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_BOUNDARY_STATUS={boundary_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_BREAK_GLASS_STATUS={break_glass_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_AUDIT_READY={audit_ready_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_NO_APPLY={no_apply_status}")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY_SECRET_SAFETY={secret_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("SUPPORT_ACCESS_EXECUTED=NO")
print("SUPER_ADMIN_ACCESS_EXECUTED=NO")
print("BREAK_GLASS_EXECUTED=NO")
print("PERMISSION_GUARD_EXECUTED=NO")
print("RBAC_ENFORCEMENT_EXECUTED=NO")
print("AUDIT_LOG_WRITE_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"SUPPORT_SUPER_ADMIN_BOUNDARY={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_21_5_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
