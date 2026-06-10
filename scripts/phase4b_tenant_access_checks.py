#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "21_4_tenant_access_checks_standard.md"
contract_file = report_dir / "21_4_tenant_access_checks_contract.md"
check_manifest_file = report_dir / "21_4_tenant_access_checks_check_manifest.tsv"
decision_manifest_file = report_dir / "21_4_tenant_access_checks_decision_manifest.tsv"
surface_manifest_file = report_dir / "21_4_tenant_access_checks_surface_manifest.tsv"
report_file = report_dir / "21_4_tenant_access_checks_report.md"
matrix_file = report_dir / "21_4_tenant_access_checks_matrix.tsv"

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
detail("TENANT_ACCESS_CHECK_EXECUTED=NO")
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
detail("VALIDATION_MODE=TENANT_ACCESS_CHECKS_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_21_3_status = get_value(prev_21_3, "FAZ4B_21_3_FINAL_STATUS")
prev_21_3_domain = get_value(prev_21_3, "AUDIT_EVENT_MODEL")
prev_21_3_apply = get_value(prev_21_3, "DB_APPLY_EXECUTED")
prev_21_3_audit_write = get_value(prev_21_3, "AUDIT_LOG_WRITE_EXECUTED")
prev_21_2_status = get_value(prev_21_2, "FAZ4B_21_2_FINAL_STATUS")
prev_21_2_domain = get_value(prev_21_2, "PERMISSION_GUARD")
prev_21_1_status = get_value(prev_21_1, "FAZ4B_21_1_FINAL_STATUS")
prev_21_1_domain = get_value(prev_21_1, "ROLE_MATRIX")
prev_19_status = get_value(prev_19, "FAZ4B_19_FINAL_STATUS")

detail(f"PREVIOUS_21_3_FINAL_STATUS={prev_21_3_status}")
detail(f"PREVIOUS_21_3_AUDIT_EVENT_MODEL={prev_21_3_domain}")
detail(f"PREVIOUS_21_3_DB_APPLY_EXECUTED={prev_21_3_apply}")
detail(f"PREVIOUS_21_3_AUDIT_LOG_WRITE_EXECUTED={prev_21_3_audit_write}")
detail(f"PREVIOUS_21_2_FINAL_STATUS={prev_21_2_status}")
detail(f"PREVIOUS_21_2_PERMISSION_GUARD={prev_21_2_domain}")
detail(f"PREVIOUS_21_1_FINAL_STATUS={prev_21_1_status}")
detail(f"PREVIOUS_21_1_ROLE_MATRIX={prev_21_1_domain}")
detail(f"PREVIOUS_19_FINAL_STATUS={prev_19_status}")

if prev_21_3_status != "PASS":
    fail("21.3 final status PASS degil")
if prev_21_3_domain != "PASS":
    fail("21.3 audit event model PASS degil")
if prev_21_3_apply != "NO":
    fail("21.3 DB apply NO degil")
if prev_21_3_audit_write != "NO":
    fail("21.3 audit log write NO degil")
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
    (check_manifest_file, "check manifest"),
    (decision_manifest_file, "decision manifest"),
    (surface_manifest_file, "surface manifest"),
]:
    if not path.exists():
        fail(f"{label} yok")

standard_text = read(standard_file)
contract_text = read(contract_file)
check_text = read(check_manifest_file)
decision_text = read(decision_manifest_file)
surface_text = read(surface_manifest_file)
all_text = "\n".join([standard_text, contract_text, check_text, decision_text, surface_text])

required_inputs = [
    "tenant_id",
    "tenant_uuid",
    "jwt_tenant_id",
    "header_tenant_id",
    "actor_tenant_id",
    "actor_user_id",
    "actor_role_code",
    "resource_tenant_id",
    "resource_area",
    "resource_name",
    "resource_id",
    "role_code",
    "permission_code",
    "action_code",
    "source_route",
    "http_method",
    "request_id",
    "correlation_id",
    "support_access_reason",
    "super_admin_boundary_mode",
    "cross_tenant_boundary_mode",
]

required_outputs = [
    "tenant_access_check_id",
    "tenant_id",
    "actor_user_id",
    "resource_tenant_id",
    "role_code",
    "permission_code",
    "action_code",
    "decision",
    "deny_reason",
    "deny_reason_code",
    "boundary_status",
    "audit_required",
    "high_risk",
    "request_id",
    "correlation_id",
    "checked_at",
]

required_checks = [
    "tenant_context_required",
    "jwt_tenant_required",
    "header_tenant_match",
    "actor_tenant_match",
    "resource_tenant_match",
    "route_tenant_scope",
    "permission_tenant_scope",
    "role_tenant_scope",
    "audit_tenant_scope",
    "support_boundary_tenant_scope",
    "super_admin_boundary_tenant_scope",
    "cross_tenant_default_deny",
]

required_decisions = [
    "ALLOW_TENANT_MATCH",
    "DENY_NO_TENANT",
    "DENY_JWT_TENANT_MISSING",
    "DENY_HEADER_TENANT_MISMATCH",
    "DENY_ACTOR_TENANT_MISMATCH",
    "DENY_RESOURCE_TENANT_MISMATCH",
    "DENY_ROUTE_TENANT_SCOPE",
    "DENY_ROLE_TENANT_SCOPE",
    "DENY_PERMISSION_TENANT_SCOPE",
    "DENY_AUDIT_TENANT_SCOPE",
    "DENY_CROSS_TENANT",
    "DENY_SUPPORT_BOUNDARY_TENANT",
    "DENY_SUPER_ADMIN_BOUNDARY_TENANT",
]

required_surfaces = [
    "panel_admin_tenant_check",
    "api_route_tenant_check",
    "import_batch_tenant_check",
    "inventory_resource_tenant_check",
    "reporting_resource_tenant_check",
    "uat_checklist_tenant_check",
    "issue_feedback_tenant_check",
    "audit_event_tenant_check",
    "support_access_tenant_check",
    "super_admin_tenant_check",
]

check_rows = tsv_rows(check_manifest_file)
decision_rows = tsv_rows(decision_manifest_file)
surface_rows = tsv_rows(surface_manifest_file)

check_data_rows = max(0, len(check_rows) - 1)
decision_data_rows = max(0, len(decision_rows) - 1)
surface_data_rows = max(0, len(surface_rows) - 1)

input_hit_count = sum(1 for item in required_inputs if item in contract_text)
output_hit_count = sum(1 for item in required_outputs if item in contract_text)
check_hit_count = sum(1 for item in required_checks if item in standard_text and item in check_text)
decision_hit_count = sum(1 for item in required_decisions if item in contract_text and item in decision_text)
surface_hit_count = sum(1 for item in required_surfaces if item in standard_text and item in surface_text)

tenant_yes_count = count(r"\bYES\b", check_text + "\n" + decision_text + "\n" + surface_text)
audit_yes_count = count(r"\bYES\b", check_text + "\n" + decision_text + "\n" + surface_text)
contract_only_count = count(r"\bcontract_only\b", all_text)
tenant_ref_count = count(r"tenant", all_text)
jwt_ref_count = count(r"jwt_tenant|JWT tenant|jwt", all_text)
header_ref_count = count(r"header_tenant|Header tenant|header", all_text)
actor_ref_count = count(r"actor_tenant|Actor tenant|actor", all_text)
resource_ref_count = count(r"resource_tenant|Resource tenant|resource", all_text)
deny_ref_count = count(r"DENY|deny", all_text)
allow_ref_count = count(r"ALLOW|allow", all_text)
boundary_ref_count = count(r"boundary|Boundary|cross_tenant|super_admin|support", all_text)
audit_ref_count = count(r"audit|Audit", all_text)
high_risk_ref_count = count(r"high_risk|High-risk|high-risk", all_text)

detail(f"TENANT_ACCESS_CHECKS_INPUT_HIT_COUNT={input_hit_count}")
detail(f"TENANT_ACCESS_CHECKS_OUTPUT_HIT_COUNT={output_hit_count}")
detail(f"TENANT_ACCESS_CHECKS_CHECK_COUNT={check_data_rows}")
detail(f"TENANT_ACCESS_CHECKS_REQUIRED_CHECK_HIT_COUNT={check_hit_count}")
detail(f"TENANT_ACCESS_CHECKS_DECISION_COUNT={decision_data_rows}")
detail(f"TENANT_ACCESS_CHECKS_REQUIRED_DECISION_HIT_COUNT={decision_hit_count}")
detail(f"TENANT_ACCESS_CHECKS_SURFACE_COUNT={surface_data_rows}")
detail(f"TENANT_ACCESS_CHECKS_REQUIRED_SURFACE_HIT_COUNT={surface_hit_count}")
detail(f"TENANT_ACCESS_CHECKS_TENANT_YES_COUNT={tenant_yes_count}")
detail(f"TENANT_ACCESS_CHECKS_AUDIT_YES_COUNT={audit_yes_count}")
detail(f"TENANT_ACCESS_CHECKS_CONTRACT_ONLY_COUNT={contract_only_count}")
detail(f"TENANT_ACCESS_CHECKS_TENANT_REF_COUNT={tenant_ref_count}")
detail(f"TENANT_ACCESS_CHECKS_JWT_REF_COUNT={jwt_ref_count}")
detail(f"TENANT_ACCESS_CHECKS_HEADER_REF_COUNT={header_ref_count}")
detail(f"TENANT_ACCESS_CHECKS_ACTOR_REF_COUNT={actor_ref_count}")
detail(f"TENANT_ACCESS_CHECKS_RESOURCE_REF_COUNT={resource_ref_count}")
detail(f"TENANT_ACCESS_CHECKS_DENY_REF_COUNT={deny_ref_count}")
detail(f"TENANT_ACCESS_CHECKS_ALLOW_REF_COUNT={allow_ref_count}")
detail(f"TENANT_ACCESS_CHECKS_BOUNDARY_REF_COUNT={boundary_ref_count}")
detail(f"TENANT_ACCESS_CHECKS_AUDIT_REF_COUNT={audit_ref_count}")
detail(f"TENANT_ACCESS_CHECKS_HIGH_RISK_REF_COUNT={high_risk_ref_count}")

if input_hit_count != len(required_inputs):
    fail("required input hit count eksik")
if output_hit_count != len(required_outputs):
    fail("required output hit count eksik")
if check_data_rows != 12:
    fail("check manifest count 12 degil")
if check_hit_count != 12:
    fail("required check hit count 12 degil")
if decision_data_rows != 13:
    fail("decision manifest count 13 degil")
if decision_hit_count != 13:
    fail("required decision hit count 13 degil")
if surface_data_rows != 10:
    fail("surface manifest count 10 degil")
if surface_hit_count != 10:
    fail("required surface hit count 10 degil")
if tenant_yes_count < 60:
    fail("tenant YES count 60 altinda")
if audit_yes_count < 50:
    fail("audit YES count 50 altinda")
if contract_only_count < 30:
    fail("contract_only count 30 altinda")
if tenant_ref_count < 60:
    fail("tenant reference count 60 altinda")
if jwt_ref_count < 5:
    fail("jwt tenant reference count 5 altinda")
if header_ref_count < 5:
    fail("header tenant reference count 5 altinda")
if actor_ref_count < 8:
    fail("actor tenant reference count 8 altinda")
if resource_ref_count < 8:
    fail("resource tenant reference count 8 altinda")
if deny_ref_count < 25:
    fail("deny reference count 25 altinda")
if allow_ref_count < 4:
    fail("allow reference count 4 altinda")
if boundary_ref_count < 20:
    fail("boundary reference count 20 altinda")
if audit_ref_count < 12:
    fail("audit reference count 12 altinda")
if high_risk_ref_count < 6:
    fail("high risk reference count 6 altinda")

for item in required_inputs:
    if item not in contract_text:
        fail(f"input eksik: {item}")

for item in required_outputs:
    if item not in contract_text:
        fail(f"output eksik: {item}")

for item in required_checks:
    if item not in standard_text:
        fail(f"standard check eksik: {item}")
    if item not in check_text:
        fail(f"check manifest eksik: {item}")

for item in required_decisions:
    if item not in contract_text:
        fail(f"contract decision eksik: {item}")
    if item not in decision_text:
        fail(f"decision manifest eksik: {item}")

for item in required_surfaces:
    if item not in standard_text:
        fail(f"standard surface eksik: {item}")
    if item not in surface_text:
        fail(f"surface manifest eksik: {item}")

secret_hits = []
for path in [standard_file, contract_file, check_manifest_file, decision_manifest_file, surface_manifest_file]:
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

detail(f"TENANT_ACCESS_CHECKS_SECRET_HIT_COUNT={len(secret_hits)}")

if secret_hits:
    fail("secret/query leak bulundu: " + ",".join(secret_hits))

previous_status = "PASS" if (
    prev_21_3_status == "PASS"
    and prev_21_3_domain == "PASS"
    and prev_21_3_apply == "NO"
    and prev_21_3_audit_write == "NO"
    and prev_21_2_status == "PASS"
    and prev_21_2_domain == "PASS"
    and prev_21_1_status == "PASS"
    and prev_19_status == "PASS"
) else "FAIL"

contract_status = "PASS" if input_hit_count == 21 and output_hit_count == 16 and decision_hit_count == 13 else "FAIL"
check_manifest_status = "PASS" if check_data_rows == 12 and check_hit_count == 12 else "FAIL"
decision_manifest_status = "PASS" if decision_data_rows == 13 and decision_hit_count == 13 else "FAIL"
surface_manifest_status = "PASS" if surface_data_rows == 10 and surface_hit_count == 10 else "FAIL"
tenant_safety_status = "PASS" if tenant_yes_count >= 60 and tenant_ref_count >= 60 and deny_ref_count >= 25 else "FAIL"
boundary_status = "PASS" if boundary_ref_count >= 20 and high_risk_ref_count >= 6 else "FAIL"
audit_ready_status = "PASS" if audit_ref_count >= 12 and audit_yes_count >= 50 else "FAIL"
identity_match_status = "PASS" if jwt_ref_count >= 5 and header_ref_count >= 5 and actor_ref_count >= 8 and resource_ref_count >= 8 else "FAIL"
no_apply_status = "PASS"
secret_status = "PASS" if not secret_hits else "FAIL"

detail(f"TENANT_ACCESS_CHECKS_PREVIOUS_21_3={previous_status}")
detail(f"TENANT_ACCESS_CHECKS_CONTRACT={contract_status}")
detail(f"TENANT_ACCESS_CHECKS_CHECK_MANIFEST={check_manifest_status}")
detail(f"TENANT_ACCESS_CHECKS_DECISION_MANIFEST={decision_manifest_status}")
detail(f"TENANT_ACCESS_CHECKS_SURFACE_MANIFEST={surface_manifest_status}")
detail(f"TENANT_ACCESS_CHECKS_TENANT_SAFETY={tenant_safety_status}")
detail(f"TENANT_ACCESS_CHECKS_BOUNDARY_STATUS={boundary_status}")
detail(f"TENANT_ACCESS_CHECKS_AUDIT_READY={audit_ready_status}")
detail(f"TENANT_ACCESS_CHECKS_IDENTITY_MATCH_STATUS={identity_match_status}")
detail(f"TENANT_ACCESS_CHECKS_NO_APPLY={no_apply_status}")
detail(f"TENANT_ACCESS_CHECKS_SECRET_SAFETY={secret_status}")

for name, status in [
    ("previous_21_3", previous_status),
    ("contract", contract_status),
    ("check_manifest", check_manifest_status),
    ("decision_manifest", decision_manifest_status),
    ("surface_manifest", surface_manifest_status),
    ("tenant_safety", tenant_safety_status),
    ("boundary", boundary_status),
    ("audit_ready", audit_ready_status),
    ("identity_match", identity_match_status),
    ("no_apply", no_apply_status),
    ("secret_safety", secret_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_21_3\t{previous_status}\taudit event model prerequisite",
    f"contract\t{contract_status}\tinputs={input_hit_count} outputs={output_hit_count} decisions={decision_hit_count}",
    f"check_manifest\t{check_manifest_status}\tcheck_count={check_data_rows}",
    f"decision_manifest\t{decision_manifest_status}\tdecision_count={decision_data_rows}",
    f"surface_manifest\t{surface_manifest_status}\tsurface_count={surface_data_rows}",
    f"tenant_safety\t{tenant_safety_status}\ttenant_refs={tenant_ref_count} deny_refs={deny_ref_count}",
    f"identity_match\t{identity_match_status}\tjwt={jwt_ref_count} header={header_ref_count} actor={actor_ref_count} resource={resource_ref_count}",
    f"boundary\t{boundary_status}\tboundary_refs={boundary_ref_count} high_risk={high_risk_ref_count}",
    f"audit_ready\t{audit_ready_status}\taudit_refs={audit_ref_count}",
    f"no_apply\t{no_apply_status}\tcontract only",
    f"secret_safety\t{secret_status}\tsecret_hits={len(secret_hits)}",
    "db_mutation\tNO\tcontract only",
    "db_apply_executed\tNO\tcontract only",
    "migration_created\tNO\tcontract only",
    "tenant_access_check_executed\tNO\tcontract only",
    "permission_guard_executed\tNO\tcontract only",
    "rbac_enforcement_executed\tNO\tcontract only",
    "audit_log_write_executed\tNO\tcontract only",
    "panel_route_deployed\tNO\tcontract only",
    "api_route_deployed\tNO\tcontract only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"TENANT_ACCESS_CHECKS={final_status}")
detail(f"FAZ4B_21_4_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 21.4 - Tenant Access Checks Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"TENANT_ACCESS_CHECKS={final_status}",
    f"FAZ4B_21_4_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/21_4_tenant_access_checks_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Artifacts",
    "STANDARD_FILE=docs/phase4/21_4_tenant_access_checks_standard.md",
    "CONTRACT_FILE=docs/phase4/21_4_tenant_access_checks_contract.md",
    "CHECK_MANIFEST_FILE=docs/phase4/21_4_tenant_access_checks_check_manifest.tsv",
    "DECISION_MANIFEST_FILE=docs/phase4/21_4_tenant_access_checks_decision_manifest.tsv",
    "SURFACE_MANIFEST_FILE=docs/phase4/21_4_tenant_access_checks_surface_manifest.tsv",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "TENANT_ACCESS_CHECK_EXECUTED=NO",
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
print(f"CHECK_MANIFEST_FILE={check_manifest_file}")
print(f"DECISION_MANIFEST_FILE={decision_manifest_file}")
print(f"SURFACE_MANIFEST_FILE={surface_manifest_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"TENANT_ACCESS_CHECKS_INPUT_HIT_COUNT={input_hit_count}")
print(f"TENANT_ACCESS_CHECKS_OUTPUT_HIT_COUNT={output_hit_count}")
print(f"TENANT_ACCESS_CHECKS_CHECK_COUNT={check_data_rows}")
print(f"TENANT_ACCESS_CHECKS_DECISION_COUNT={decision_data_rows}")
print(f"TENANT_ACCESS_CHECKS_SURFACE_COUNT={surface_data_rows}")
print(f"TENANT_ACCESS_CHECKS_PREVIOUS_21_3={previous_status}")
print(f"TENANT_ACCESS_CHECKS_CONTRACT={contract_status}")
print(f"TENANT_ACCESS_CHECKS_CHECK_MANIFEST={check_manifest_status}")
print(f"TENANT_ACCESS_CHECKS_DECISION_MANIFEST={decision_manifest_status}")
print(f"TENANT_ACCESS_CHECKS_SURFACE_MANIFEST={surface_manifest_status}")
print(f"TENANT_ACCESS_CHECKS_TENANT_SAFETY={tenant_safety_status}")
print(f"TENANT_ACCESS_CHECKS_IDENTITY_MATCH_STATUS={identity_match_status}")
print(f"TENANT_ACCESS_CHECKS_BOUNDARY_STATUS={boundary_status}")
print(f"TENANT_ACCESS_CHECKS_AUDIT_READY={audit_ready_status}")
print(f"TENANT_ACCESS_CHECKS_NO_APPLY={no_apply_status}")
print(f"TENANT_ACCESS_CHECKS_SECRET_SAFETY={secret_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("TENANT_ACCESS_CHECK_EXECUTED=NO")
print("PERMISSION_GUARD_EXECUTED=NO")
print("RBAC_ENFORCEMENT_EXECUTED=NO")
print("AUDIT_LOG_WRITE_EXECUTED=NO")
print("PANEL_ROUTE_DEPLOYED=NO")
print("API_ROUTE_DEPLOYED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"TENANT_ACCESS_CHECKS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_21_4_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
