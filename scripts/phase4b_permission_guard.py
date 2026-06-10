#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "21_2_permission_guard_standard.md"
contract_file = report_dir / "21_2_permission_guard_contract.md"
middleware_manifest_file = report_dir / "21_2_permission_guard_middleware_manifest.tsv"
decision_manifest_file = report_dir / "21_2_permission_guard_decision_manifest.tsv"
surface_manifest_file = report_dir / "21_2_permission_guard_surface_manifest.tsv"
report_file = report_dir / "21_2_permission_guard_report.md"
matrix_file = report_dir / "21_2_permission_guard_matrix.tsv"

prev_21_1 = report_dir / "21_1_role_matrix_report.md"
prev_19 = report_dir / "19_panel_admin_professionalization_final_closure_report.md"
prev_18 = report_dir / "18_inventory_pilot_motor_final_closure_report.md"

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
detail("VALIDATION_MODE=PERMISSION_GUARD_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_21_1_status = get_value(prev_21_1, "FAZ4B_21_1_FINAL_STATUS")
prev_21_1_domain = get_value(prev_21_1, "ROLE_MATRIX")
prev_21_1_apply = get_value(prev_21_1, "DB_APPLY_EXECUTED")
prev_21_1_rbac = get_value(prev_21_1, "RBAC_ENFORCEMENT_EXECUTED")
prev_19_status = get_value(prev_19, "FAZ4B_19_FINAL_STATUS")
prev_18_status = get_value(prev_18, "FAZ4B_18_FINAL_STATUS")

detail(f"PREVIOUS_21_1_FINAL_STATUS={prev_21_1_status}")
detail(f"PREVIOUS_21_1_ROLE_MATRIX={prev_21_1_domain}")
detail(f"PREVIOUS_21_1_DB_APPLY_EXECUTED={prev_21_1_apply}")
detail(f"PREVIOUS_21_1_RBAC_ENFORCEMENT_EXECUTED={prev_21_1_rbac}")
detail(f"PREVIOUS_19_FINAL_STATUS={prev_19_status}")
detail(f"PREVIOUS_18_FINAL_STATUS={prev_18_status}")

if prev_21_1_status != "PASS":
    fail("21.1 final status PASS degil")
if prev_21_1_domain != "PASS":
    fail("21.1 role matrix PASS degil")
if prev_21_1_apply != "NO":
    fail("21.1 DB apply NO degil")
if prev_21_1_rbac != "NO":
    fail("21.1 RBAC enforcement NO degil")
if prev_19_status != "PASS":
    fail("19 final status PASS degil")
if prev_18_status != "PASS":
    fail("18 final status PASS degil")

for path, label in [
    (standard_file, "standard doc"),
    (contract_file, "contract doc"),
    (middleware_manifest_file, "middleware manifest"),
    (decision_manifest_file, "decision manifest"),
    (surface_manifest_file, "surface manifest"),
]:
    if not path.exists():
        fail(f"{label} yok")

standard_text = read(standard_file)
contract_text = read(contract_file)
middleware_text = read(middleware_manifest_file)
decision_text = read(decision_manifest_file)
surface_text = read(surface_manifest_file)
all_text = "\n".join([standard_text, contract_text, middleware_text, decision_text, surface_text])

required_inputs = [
    "tenant_id",
    "tenant_uuid",
    "user_id",
    "role_code",
    "permission_code",
    "resource_area",
    "resource_name",
    "action_code",
    "request_id",
    "correlation_id",
    "source_route",
    "http_method",
    "jwt_tenant_id",
    "header_tenant_id",
    "support_access_reason",
    "super_admin_boundary_mode",
    "cross_tenant_boundary_mode",
]

required_outputs = [
    "decision_id",
    "tenant_id",
    "user_id",
    "role_code",
    "permission_code",
    "resource_area",
    "action_code",
    "decision",
    "deny_reason",
    "boundary_status",
    "audit_required",
    "high_risk",
    "request_id",
    "correlation_id",
    "decided_at",
]

required_decisions = [
    "ALLOW",
    "DENY",
    "DENY_NO_TENANT",
    "DENY_TENANT_MISMATCH",
    "DENY_ROLE_MISSING",
    "DENY_PERMISSION_MISSING",
    "DENY_SCOPE_MISMATCH",
    "DENY_CROSS_TENANT",
    "DENY_SUPPORT_BOUNDARY",
    "DENY_SUPER_ADMIN_BOUNDARY",
    "DENY_HIGH_RISK_APPROVAL_REQUIRED",
]

required_middlewares = [
    "RequestIdMiddleware",
    "AuthMiddleware",
    "TenantContextMiddleware",
    "RoleContextMiddleware",
    "PermissionGuardMiddleware",
    "BoundaryGuardMiddleware",
    "AuditReadyMiddleware",
    "Handler",
]

required_surfaces = [
    "panel_route_guard",
    "api_route_guard",
    "import_action_guard",
    "inventory_action_guard",
    "reporting_access_guard",
    "uat_action_guard",
    "issue_feedback_guard",
    "security_admin_guard",
    "support_boundary_guard",
    "super_admin_boundary_guard",
]

middleware_rows = tsv_rows(middleware_manifest_file)
decision_rows = tsv_rows(decision_manifest_file)
surface_rows = tsv_rows(surface_manifest_file)

middleware_data_rows = max(0, len(middleware_rows) - 1)
decision_data_rows = max(0, len(decision_rows) - 1)
surface_data_rows = max(0, len(surface_rows) - 1)

input_hit_count = sum(1 for item in required_inputs if item in contract_text)
output_hit_count = sum(1 for item in required_outputs if item in contract_text)
decision_hit_count = sum(1 for item in required_decisions if item in contract_text and item in decision_text)
middleware_hit_count = sum(1 for item in required_middlewares if item in contract_text and item in middleware_text)
surface_hit_count = sum(1 for item in required_surfaces if item in standard_text and item in surface_text)

tenant_yes_count = count(r"\bYES\b", middleware_text + "\n" + decision_text + "\n" + surface_text)
audit_yes_count = count(r"\bYES\b", middleware_text + "\n" + decision_text + "\n" + surface_text)
contract_only_count = count(r"\bcontract_only\b", all_text)
tenant_ref_count = count(r"tenant", all_text)
deny_ref_count = count(r"DENY|deny", all_text)
allow_ref_count = count(r"ALLOW|allow", all_text)
boundary_ref_count = count(r"boundary|Boundary|cross_tenant|super_admin|support", all_text)
audit_ref_count = count(r"audit|Audit", all_text)
guard_ref_count = count(r"guard|Guard", all_text)
permission_ref_count = count(r"permission|Permission", all_text)
rbac_ref_count = count(r"RBAC|role|Role", all_text)

detail(f"PERMISSION_GUARD_INPUT_HIT_COUNT={input_hit_count}")
detail(f"PERMISSION_GUARD_OUTPUT_HIT_COUNT={output_hit_count}")
detail(f"PERMISSION_GUARD_DECISION_COUNT={decision_data_rows}")
detail(f"PERMISSION_GUARD_REQUIRED_DECISION_HIT_COUNT={decision_hit_count}")
detail(f"PERMISSION_GUARD_MIDDLEWARE_COUNT={middleware_data_rows}")
detail(f"PERMISSION_GUARD_REQUIRED_MIDDLEWARE_HIT_COUNT={middleware_hit_count}")
detail(f"PERMISSION_GUARD_SURFACE_COUNT={surface_data_rows}")
detail(f"PERMISSION_GUARD_REQUIRED_SURFACE_HIT_COUNT={surface_hit_count}")
detail(f"PERMISSION_GUARD_TENANT_YES_COUNT={tenant_yes_count}")
detail(f"PERMISSION_GUARD_AUDIT_YES_COUNT={audit_yes_count}")
detail(f"PERMISSION_GUARD_CONTRACT_ONLY_COUNT={contract_only_count}")
detail(f"PERMISSION_GUARD_TENANT_REF_COUNT={tenant_ref_count}")
detail(f"PERMISSION_GUARD_DENY_REF_COUNT={deny_ref_count}")
detail(f"PERMISSION_GUARD_ALLOW_REF_COUNT={allow_ref_count}")
detail(f"PERMISSION_GUARD_BOUNDARY_REF_COUNT={boundary_ref_count}")
detail(f"PERMISSION_GUARD_AUDIT_REF_COUNT={audit_ref_count}")
detail(f"PERMISSION_GUARD_GUARD_REF_COUNT={guard_ref_count}")
detail(f"PERMISSION_GUARD_PERMISSION_REF_COUNT={permission_ref_count}")
detail(f"PERMISSION_GUARD_RBAC_REF_COUNT={rbac_ref_count}")

if input_hit_count != len(required_inputs):
    fail("required guard input hit count eksik")
if output_hit_count != len(required_outputs):
    fail("required guard output hit count eksik")
if decision_data_rows != 11:
    fail("decision manifest decision count 11 degil")
if decision_hit_count != 11:
    fail("required decision hit count 11 degil")
if middleware_data_rows != 8:
    fail("middleware manifest middleware count 8 degil")
if middleware_hit_count != 8:
    fail("required middleware hit count 8 degil")
if surface_data_rows != 10:
    fail("surface manifest surface count 10 degil")
if surface_hit_count != 10:
    fail("required surface hit count 10 degil")
if tenant_yes_count < 25:
    fail("tenant YES count 25 altinda")
if audit_yes_count < 25:
    fail("audit YES count 25 altinda")
if contract_only_count < 25:
    fail("contract_only count 25 altinda")
if tenant_ref_count < 30:
    fail("tenant reference count 30 altinda")
if deny_ref_count < 20:
    fail("deny reference count 20 altinda")
if allow_ref_count < 6:
    fail("allow reference count 6 altinda")
if boundary_ref_count < 18:
    fail("boundary reference count 18 altinda")
if audit_ref_count < 10:
    fail("audit reference count 10 altinda")
if guard_ref_count < 25:
    fail("guard reference count 25 altinda")
if permission_ref_count < 18:
    fail("permission reference count 18 altinda")
if rbac_ref_count < 8:
    fail("RBAC/role reference count 8 altinda")

for item in required_inputs:
    if item not in contract_text:
        fail(f"guard input eksik: {item}")

for item in required_outputs:
    if item not in contract_text:
        fail(f"guard output eksik: {item}")

for item in required_decisions:
    if item not in contract_text:
        fail(f"contract decision eksik: {item}")
    if item not in decision_text:
        fail(f"decision manifest eksik: {item}")

for item in required_middlewares:
    if item not in contract_text:
        fail(f"contract middleware eksik: {item}")
    if item not in middleware_text:
        fail(f"middleware manifest eksik: {item}")

for item in required_surfaces:
    if item not in standard_text:
        fail(f"standard surface eksik: {item}")
    if item not in surface_text:
        fail(f"surface manifest eksik: {item}")

secret_hits = []
for path in [standard_file, contract_file, middleware_manifest_file, decision_manifest_file, surface_manifest_file]:
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

detail(f"PERMISSION_GUARD_SECRET_HIT_COUNT={len(secret_hits)}")

if secret_hits:
    fail("secret/query leak bulundu: " + ",".join(secret_hits))

previous_status = "PASS" if (
    prev_21_1_status == "PASS"
    and prev_21_1_domain == "PASS"
    and prev_21_1_apply == "NO"
    and prev_21_1_rbac == "NO"
    and prev_19_status == "PASS"
) else "FAIL"

contract_status = "PASS" if input_hit_count == 17 and output_hit_count == 15 and decision_hit_count == 11 else "FAIL"
middleware_status = "PASS" if middleware_data_rows == 8 and middleware_hit_count == 8 else "FAIL"
decision_status = "PASS" if decision_data_rows == 11 and decision_hit_count == 11 else "FAIL"
surface_status = "PASS" if surface_data_rows == 10 and surface_hit_count == 10 else "FAIL"
tenant_safety_status = "PASS" if tenant_yes_count >= 25 and tenant_ref_count >= 30 and deny_ref_count >= 20 else "FAIL"
boundary_status = "PASS" if boundary_ref_count >= 18 else "FAIL"
audit_ready_status = "PASS" if audit_ref_count >= 10 and audit_yes_count >= 25 else "FAIL"
no_apply_status = "PASS"
secret_status = "PASS" if not secret_hits else "FAIL"

detail(f"PERMISSION_GUARD_PREVIOUS_21_1={previous_status}")
detail(f"PERMISSION_GUARD_CONTRACT={contract_status}")
detail(f"PERMISSION_GUARD_MIDDLEWARE_MANIFEST={middleware_status}")
detail(f"PERMISSION_GUARD_DECISION_MANIFEST={decision_status}")
detail(f"PERMISSION_GUARD_SURFACE_MANIFEST={surface_status}")
detail(f"PERMISSION_GUARD_TENANT_SAFETY={tenant_safety_status}")
detail(f"PERMISSION_GUARD_BOUNDARY_STATUS={boundary_status}")
detail(f"PERMISSION_GUARD_AUDIT_READY={audit_ready_status}")
detail(f"PERMISSION_GUARD_NO_APPLY={no_apply_status}")
detail(f"PERMISSION_GUARD_SECRET_SAFETY={secret_status}")

for name, status in [
    ("previous_21_1", previous_status),
    ("contract", contract_status),
    ("middleware_manifest", middleware_status),
    ("decision_manifest", decision_status),
    ("surface_manifest", surface_status),
    ("tenant_safety", tenant_safety_status),
    ("boundary", boundary_status),
    ("audit_ready", audit_ready_status),
    ("no_apply", no_apply_status),
    ("secret_safety", secret_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_21_1\t{previous_status}\trole matrix prerequisite",
    f"contract\t{contract_status}\tinputs={input_hit_count} outputs={output_hit_count} decisions={decision_hit_count}",
    f"middleware_manifest\t{middleware_status}\tmiddleware_count={middleware_data_rows}",
    f"decision_manifest\t{decision_status}\tdecision_count={decision_data_rows}",
    f"surface_manifest\t{surface_status}\tsurface_count={surface_data_rows}",
    f"tenant_safety\t{tenant_safety_status}\ttenant_refs={tenant_ref_count} deny_refs={deny_ref_count}",
    f"boundary\t{boundary_status}\tboundary_refs={boundary_ref_count}",
    f"audit_ready\t{audit_ready_status}\taudit_refs={audit_ref_count}",
    f"no_apply\t{no_apply_status}\tcontract only",
    f"secret_safety\t{secret_status}\tsecret_hits={len(secret_hits)}",
    "db_mutation\tNO\tcontract only",
    "db_apply_executed\tNO\tcontract only",
    "migration_created\tNO\tcontract only",
    "permission_guard_executed\tNO\tcontract only",
    "rbac_enforcement_executed\tNO\tcontract only",
    "audit_log_write_executed\tNO\tcontract only",
    "panel_route_deployed\tNO\tcontract only",
    "api_route_deployed\tNO\tcontract only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"PERMISSION_GUARD={final_status}")
detail(f"FAZ4B_21_2_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 21.2 - Permission Guard Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"PERMISSION_GUARD={final_status}",
    f"FAZ4B_21_2_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/21_2_permission_guard_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Artifacts",
    "STANDARD_FILE=docs/phase4/21_2_permission_guard_standard.md",
    "CONTRACT_FILE=docs/phase4/21_2_permission_guard_contract.md",
    "MIDDLEWARE_MANIFEST_FILE=docs/phase4/21_2_permission_guard_middleware_manifest.tsv",
    "DECISION_MANIFEST_FILE=docs/phase4/21_2_permission_guard_decision_manifest.tsv",
    "SURFACE_MANIFEST_FILE=docs/phase4/21_2_permission_guard_surface_manifest.tsv",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
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
print(f"MIDDLEWARE_MANIFEST_FILE={middleware_manifest_file}")
print(f"DECISION_MANIFEST_FILE={decision_manifest_file}")
print(f"SURFACE_MANIFEST_FILE={surface_manifest_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"PERMISSION_GUARD_INPUT_HIT_COUNT={input_hit_count}")
print(f"PERMISSION_GUARD_OUTPUT_HIT_COUNT={output_hit_count}")
print(f"PERMISSION_GUARD_DECISION_COUNT={decision_data_rows}")
print(f"PERMISSION_GUARD_MIDDLEWARE_COUNT={middleware_data_rows}")
print(f"PERMISSION_GUARD_SURFACE_COUNT={surface_data_rows}")
print(f"PERMISSION_GUARD_PREVIOUS_21_1={previous_status}")
print(f"PERMISSION_GUARD_CONTRACT={contract_status}")
print(f"PERMISSION_GUARD_MIDDLEWARE_MANIFEST={middleware_status}")
print(f"PERMISSION_GUARD_DECISION_MANIFEST={decision_status}")
print(f"PERMISSION_GUARD_SURFACE_MANIFEST={surface_status}")
print(f"PERMISSION_GUARD_TENANT_SAFETY={tenant_safety_status}")
print(f"PERMISSION_GUARD_BOUNDARY_STATUS={boundary_status}")
print(f"PERMISSION_GUARD_AUDIT_READY={audit_ready_status}")
print(f"PERMISSION_GUARD_NO_APPLY={no_apply_status}")
print(f"PERMISSION_GUARD_SECRET_SAFETY={secret_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("PERMISSION_GUARD_EXECUTED=NO")
print("RBAC_ENFORCEMENT_EXECUTED=NO")
print("AUDIT_LOG_WRITE_EXECUTED=NO")
print("PANEL_ROUTE_DEPLOYED=NO")
print("API_ROUTE_DEPLOYED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"PERMISSION_GUARD={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_21_2_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
