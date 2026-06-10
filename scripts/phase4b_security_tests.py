#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "21_6_security_tests_standard.md"
report_file = report_dir / "21_6_security_tests_report.md"
matrix_file = report_dir / "21_6_security_tests_matrix.tsv"
inventory_file = report_dir / "21_6_security_tests_inventory.tsv"

reports = {
    "21.1": report_dir / "21_1_role_matrix_report.md",
    "21.2": report_dir / "21_2_permission_guard_report.md",
    "21.3": report_dir / "21_3_audit_event_model_report.md",
    "21.4": report_dir / "21_4_tenant_access_checks_report.md",
    "21.5": report_dir / "21_5_support_super_admin_boundary_report.md",
    "19": report_dir / "19_panel_admin_professionalization_final_closure_report.md",
}

domain_keys = {
    "21.1": "ROLE_MATRIX",
    "21.2": "PERMISSION_GUARD",
    "21.3": "AUDIT_EVENT_MODEL",
    "21.4": "TENANT_ACCESS_CHECKS",
    "21.5": "SUPPORT_SUPER_ADMIN_BOUNDARY",
}

final_keys = {
    "21.1": "FAZ4B_21_1_FINAL_STATUS",
    "21.2": "FAZ4B_21_2_FINAL_STATUS",
    "21.3": "FAZ4B_21_3_FINAL_STATUS",
    "21.4": "FAZ4B_21_4_FINAL_STATUS",
    "21.5": "FAZ4B_21_5_FINAL_STATUS",
}

artifact_sets = {
    "21.1": [
        "docs/phase4/21_1_role_matrix_standard.md",
        "docs/phase4/21_1_role_matrix_report.md",
        "docs/phase4/21_1_role_matrix_inventory.tsv",
        "docs/phase4/21_1_role_matrix_matrix.tsv",
        "db/migrations/20260429_211001_security_role_matrix.up.sql",
        "db/migrations/20260429_211001_security_role_matrix.down.sql",
        "scripts/phase4b_role_matrix.sh",
        "scripts/phase4b_role_matrix.py",
        "scripts/test_phase4b_role_matrix.sh",
    ],
    "21.2": [
        "docs/phase4/21_2_permission_guard_standard.md",
        "docs/phase4/21_2_permission_guard_contract.md",
        "docs/phase4/21_2_permission_guard_middleware_manifest.tsv",
        "docs/phase4/21_2_permission_guard_decision_manifest.tsv",
        "docs/phase4/21_2_permission_guard_surface_manifest.tsv",
        "docs/phase4/21_2_permission_guard_report.md",
        "docs/phase4/21_2_permission_guard_matrix.tsv",
        "scripts/phase4b_permission_guard.sh",
        "scripts/phase4b_permission_guard.py",
        "scripts/test_phase4b_permission_guard.sh",
    ],
    "21.3": [
        "docs/phase4/21_3_audit_event_model_standard.md",
        "docs/phase4/21_3_audit_event_model_report.md",
        "docs/phase4/21_3_audit_event_model_inventory.tsv",
        "docs/phase4/21_3_audit_event_model_matrix.tsv",
        "db/migrations/20260429_213001_security_audit_event_model.up.sql",
        "db/migrations/20260429_213001_security_audit_event_model.down.sql",
        "scripts/phase4b_audit_event_model.sh",
        "scripts/phase4b_audit_event_model.py",
        "scripts/test_phase4b_audit_event_model.sh",
    ],
    "21.4": [
        "docs/phase4/21_4_tenant_access_checks_standard.md",
        "docs/phase4/21_4_tenant_access_checks_contract.md",
        "docs/phase4/21_4_tenant_access_checks_check_manifest.tsv",
        "docs/phase4/21_4_tenant_access_checks_decision_manifest.tsv",
        "docs/phase4/21_4_tenant_access_checks_surface_manifest.tsv",
        "docs/phase4/21_4_tenant_access_checks_report.md",
        "docs/phase4/21_4_tenant_access_checks_matrix.tsv",
        "scripts/phase4b_tenant_access_checks.sh",
        "scripts/phase4b_tenant_access_checks.py",
        "scripts/test_phase4b_tenant_access_checks.sh",
    ],
    "21.5": [
        "docs/phase4/21_5_support_super_admin_boundary_standard.md",
        "docs/phase4/21_5_support_super_admin_boundary_contract.md",
        "docs/phase4/21_5_support_super_admin_boundary_rule_manifest.tsv",
        "docs/phase4/21_5_support_super_admin_boundary_reason_manifest.tsv",
        "docs/phase4/21_5_support_super_admin_boundary_decision_manifest.tsv",
        "docs/phase4/21_5_support_super_admin_boundary_report.md",
        "docs/phase4/21_5_support_super_admin_boundary_matrix.tsv",
        "scripts/phase4b_support_super_admin_boundary.sh",
        "scripts/phase4b_support_super_admin_boundary.py",
        "scripts/test_phase4b_support_super_admin_boundary.sh",
    ],
}

required_status_keys = {
    "21.1": [
        "ROLE_MATRIX_MIGRATION_PAIR",
        "ROLE_MATRIX_TENANT_SAFETY_STATUS",
        "ROLE_MATRIX_ROLE_STATUS",
        "ROLE_MATRIX_PERMISSION_STATUS",
        "ROLE_MATRIX_AUDIT_READY_STATUS",
        "ROLE_MATRIX_BOUNDARY_STATUS",
        "ROLE_MATRIX_CHAIN_STATUS",
    ],
    "21.2": [
        "PERMISSION_GUARD_CONTRACT",
        "PERMISSION_GUARD_MIDDLEWARE_MANIFEST",
        "PERMISSION_GUARD_DECISION_MANIFEST",
        "PERMISSION_GUARD_SURFACE_MANIFEST",
        "PERMISSION_GUARD_TENANT_SAFETY",
        "PERMISSION_GUARD_BOUNDARY_STATUS",
        "PERMISSION_GUARD_AUDIT_READY",
        "PERMISSION_GUARD_SECRET_SAFETY",
    ],
    "21.3": [
        "AUDIT_EVENT_MODEL_MIGRATION_PAIR",
        "AUDIT_EVENT_MODEL_TENANT_SAFETY_STATUS",
        "AUDIT_EVENT_MODEL_DECISION_READY",
        "AUDIT_EVENT_MODEL_TRACE_READY",
        "AUDIT_EVENT_MODEL_IMMUTABLE_READY",
        "AUDIT_EVENT_MODEL_BOUNDARY_READY",
        "AUDIT_EVENT_MODEL_CHAIN_STATUS",
    ],
    "21.4": [
        "TENANT_ACCESS_CHECKS_CONTRACT",
        "TENANT_ACCESS_CHECKS_CHECK_MANIFEST",
        "TENANT_ACCESS_CHECKS_DECISION_MANIFEST",
        "TENANT_ACCESS_CHECKS_SURFACE_MANIFEST",
        "TENANT_ACCESS_CHECKS_TENANT_SAFETY",
        "TENANT_ACCESS_CHECKS_IDENTITY_MATCH_STATUS",
        "TENANT_ACCESS_CHECKS_BOUNDARY_STATUS",
        "TENANT_ACCESS_CHECKS_AUDIT_READY",
        "TENANT_ACCESS_CHECKS_SECRET_SAFETY",
    ],
    "21.5": [
        "SUPPORT_SUPER_ADMIN_BOUNDARY_CONTRACT",
        "SUPPORT_SUPER_ADMIN_BOUNDARY_RULE_MANIFEST",
        "SUPPORT_SUPER_ADMIN_BOUNDARY_REASON_MANIFEST",
        "SUPPORT_SUPER_ADMIN_BOUNDARY_DECISION_MANIFEST",
        "SUPPORT_SUPER_ADMIN_BOUNDARY_TENANT_SAFETY",
        "SUPPORT_SUPER_ADMIN_BOUNDARY_BOUNDARY_STATUS",
        "SUPPORT_SUPER_ADMIN_BOUNDARY_BREAK_GLASS_STATUS",
        "SUPPORT_SUPER_ADMIN_BOUNDARY_AUDIT_READY",
        "SUPPORT_SUPER_ADMIN_BOUNDARY_SECRET_SAFETY",
    ],
}

no_apply_keys = {
    "21.1": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_APPLY_EXECUTED",
        "RBAC_ENFORCEMENT_EXECUTED",
        "AUDIT_LOG_WRITE_EXECUTED",
        "QUERY_TEXT_PRINTED",
    ],
    "21.2": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "PERMISSION_GUARD_EXECUTED",
        "RBAC_ENFORCEMENT_EXECUTED",
        "AUDIT_LOG_WRITE_EXECUTED",
        "QUERY_TEXT_PRINTED",
    ],
    "21.3": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_APPLY_EXECUTED",
        "AUDIT_LOG_WRITE_EXECUTED",
        "AUDIT_INTEGRITY_CHAIN_EXECUTED",
        "PERMISSION_GUARD_EXECUTED",
        "QUERY_TEXT_PRINTED",
    ],
    "21.4": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "TENANT_ACCESS_CHECK_EXECUTED",
        "PERMISSION_GUARD_EXECUTED",
        "RBAC_ENFORCEMENT_EXECUTED",
        "AUDIT_LOG_WRITE_EXECUTED",
        "QUERY_TEXT_PRINTED",
    ],
    "21.5": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "SUPPORT_ACCESS_EXECUTED",
        "SUPER_ADMIN_ACCESS_EXECUTED",
        "BREAK_GLASS_EXECUTED",
        "PERMISSION_GUARD_EXECUTED",
        "RBAC_ENFORCEMENT_EXECUTED",
        "AUDIT_LOG_WRITE_EXECUTED",
        "QUERY_TEXT_PRINTED",
    ],
}

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

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("PERMISSION_GUARD_EXECUTED=NO")
detail("TENANT_ACCESS_CHECK_EXECUTED=NO")
detail("SUPPORT_ACCESS_EXECUTED=NO")
detail("SUPER_ADMIN_ACCESS_EXECUTED=NO")
detail("BREAK_GLASS_EXECUTED=NO")
detail("RBAC_ENFORCEMENT_EXECUTED=NO")
detail("AUDIT_LOG_WRITE_EXECUTED=NO")
detail("PANEL_ROUTE_DEPLOYED=NO")
detail("API_ROUTE_DEPLOYED=NO")
detail("SERVICE_RESTARTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=SECURITY_TESTS_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

if not standard_file.exists():
    fail("21.6 standard doc yok")

prev_19_status = get_value(reports["19"], "FAZ4B_19_FINAL_STATUS")
prev_19_panel = get_value(reports["19"], "PANEL_ADMIN_FINAL_CLOSURE")
detail(f"PREVIOUS_19_FINAL_STATUS={prev_19_status}")
detail(f"PREVIOUS_19_PANEL_ADMIN_FINAL_CLOSURE={prev_19_panel}")

if prev_19_status != "PASS":
    fail("19 final status PASS degil")
if prev_19_panel != "PASS":
    fail("19 panel admin final closure PASS degil")

block_results = {}
artifact_missing = []
status_failures = []
no_apply_failures = []

for block in ["21.1", "21.2", "21.3", "21.4", "21.5"]:
    report = reports[block]
    final_status = get_value(report, final_keys[block])
    domain_status = get_value(report, domain_keys[block])

    detail(f"PREVIOUS_{block.replace('.', '_')}_FINAL_STATUS={final_status}")
    detail(f"PREVIOUS_{block.replace('.', '_')}_{domain_keys[block]}={domain_status}")

    block_status = "PASS" if final_status == "PASS" and domain_status == "PASS" else "FAIL"

    if block_status != "PASS":
        fail(f"{block} final/domain status PASS degil")

    block_status_failures = []

    for key in required_status_keys[block]:
        value = get_value(report, key)
        detail(f"SECURITY_{block.replace('.', '_')}_{key}={value}")
        if value != "PASS":
            block_status_failures.append(f"{key}={value}")

    for key in no_apply_keys[block]:
        value = get_value(report, key)
        detail(f"SECURITY_{block.replace('.', '_')}_{key}={value}")
        if value != "NO":
            no_apply_failures.append(f"{block}:{key}={value}")

    expected_artifact_count = len(artifact_sets[block])
    existing_artifact_count = 0

    for rel in artifact_sets[block]:
        p = root / rel
        if p.exists():
            existing_artifact_count += 1
        else:
            artifact_missing.append(f"{block}:{rel}")

    detail(f"SECURITY_{block.replace('.', '_')}_ARTIFACT_EXPECTED_COUNT={expected_artifact_count}")
    detail(f"SECURITY_{block.replace('.', '_')}_ARTIFACT_EXISTING_COUNT={existing_artifact_count}")

    if block_status_failures:
        status_failures.extend([f"{block}:{x}" for x in block_status_failures])

    block_results[block] = {
        "status": "PASS" if block_status == "PASS" and not block_status_failures else "FAIL",
        "final_status": final_status,
        "domain_status": domain_status,
        "artifact_expected": expected_artifact_count,
        "artifact_existing": existing_artifact_count,
        "status_failures": len(block_status_failures),
    }

if artifact_missing:
    fail("security artifact eksik: " + ",".join(artifact_missing[:30]))

if status_failures:
    fail("security gate failure: " + ",".join(status_failures[:30]))

if no_apply_failures:
    fail("security no-apply failure: " + ",".join(no_apply_failures[:30]))

security_role_matrix_test = block_results["21.1"]["status"]
security_permission_guard_test = block_results["21.2"]["status"]
security_audit_event_model_test = block_results["21.3"]["status"]
security_tenant_access_test = block_results["21.4"]["status"]
security_support_super_admin_boundary_test = block_results["21.5"]["status"]

security_artifact_coverage_test = "PASS" if not artifact_missing else "FAIL"
security_no_apply_test = "PASS" if not no_apply_failures else "FAIL"

# Secret scan on docs/reports/manifests only, not SQL content.
scan_files = [standard_file]
for block, rels in artifact_sets.items():
    for rel in rels:
        p = root / rel
        if p.exists() and p.suffix in [".md", ".tsv"]:
            scan_files.append(p)

secret_hits = []
query_hits = []

for path in scan_files:
    text = read(path)
    rel = str(path.relative_to(root))
    if re.search(r"POSTGRES_PASSWORD=.*[A-Za-z0-9]", text):
        secret_hits.append(rel)
    if re.search(r"password=[^* \n]", text, re.IGNORECASE):
        secret_hits.append(rel)
    if re.search(r"Bearer\s+", text):
        secret_hits.append(rel)
    if re.search(r"\bSELECT\s+.*\bFROM\b", text, re.IGNORECASE):
        query_hits.append(rel)

detail(f"SECURITY_SECRET_HIT_COUNT={len(secret_hits)}")
detail(f"SECURITY_QUERY_TEXT_HIT_COUNT={len(query_hits)}")

security_secret_safety_test = "PASS" if not secret_hits and not query_hits else "FAIL"

if security_secret_safety_test != "PASS":
    fail("security secret/query leak bulundu")

for label, status in [
    ("SECURITY_ROLE_MATRIX_TEST", security_role_matrix_test),
    ("SECURITY_PERMISSION_GUARD_TEST", security_permission_guard_test),
    ("SECURITY_AUDIT_EVENT_MODEL_TEST", security_audit_event_model_test),
    ("SECURITY_TENANT_ACCESS_TEST", security_tenant_access_test),
    ("SECURITY_SUPPORT_SUPER_ADMIN_BOUNDARY_TEST", security_support_super_admin_boundary_test),
    ("SECURITY_ARTIFACT_COVERAGE_TEST", security_artifact_coverage_test),
    ("SECURITY_NO_APPLY_TEST", security_no_apply_test),
    ("SECURITY_SECRET_SAFETY_TEST", security_secret_safety_test),
]:
    detail(f"{label}={status}")
    if status != "PASS":
        fail(f"{label} PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"role_matrix\t{security_role_matrix_test}\t21.1 role matrix gates",
    f"permission_guard\t{security_permission_guard_test}\t21.2 permission guard gates",
    f"audit_event_model\t{security_audit_event_model_test}\t21.3 audit event model gates",
    f"tenant_access_checks\t{security_tenant_access_test}\t21.4 tenant access checks gates",
    f"support_super_admin_boundary\t{security_support_super_admin_boundary_test}\t21.5 support/super-admin boundary gates",
    f"artifact_coverage\t{security_artifact_coverage_test}\tmissing_artifacts={len(artifact_missing)}",
    f"no_apply\t{security_no_apply_test}\tno_apply_failures={len(no_apply_failures)}",
    f"secret_safety\t{security_secret_safety_test}\tsecret_hits={len(secret_hits)} query_hits={len(query_hits)}",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "permission_guard_executed\tNO\tevidence only",
    "tenant_access_check_executed\tNO\tevidence only",
    "support_access_executed\tNO\tevidence only",
    "super_admin_access_executed\tNO\tevidence only",
    "break_glass_executed\tNO\tevidence only",
    "audit_log_write_executed\tNO\tevidence only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = [
    "block\tstatus\tdomain_key\treport_file\tartifact_expected\tartifact_existing\tstatus_failures"
]
for block in ["21.1", "21.2", "21.3", "21.4", "21.5"]:
    result = block_results[block]
    inventory_lines.append(
        f"{block}\t{result['status']}\t{domain_keys[block]}\t{str(reports[block].relative_to(root))}\t{result['artifact_expected']}\t{result['artifact_existing']}\t{result['status_failures']}"
    )

inventory_file.write_text("\n".join(inventory_lines) + "\n")

detail(f"SECURITY_TEST_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"SECURITY_TEST_INVENTORY_LINE_COUNT={len(inventory_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"SECURITY_TESTS={final_status}")
detail(f"FAZ4B_21_6_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 21.6 - Security Tests Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"SECURITY_TESTS={final_status}",
    f"FAZ4B_21_6_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/21_6_security_tests_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/21_6_security_tests_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "PERMISSION_GUARD_EXECUTED=NO",
    "TENANT_ACCESS_CHECK_EXECUTED=NO",
    "SUPPORT_ACCESS_EXECUTED=NO",
    "SUPER_ADMIN_ACCESS_EXECUTED=NO",
    "BREAK_GLASS_EXECUTED=NO",
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
print(f"INVENTORY_FILE={inventory_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"SECURITY_ROLE_MATRIX_TEST={security_role_matrix_test}")
print(f"SECURITY_PERMISSION_GUARD_TEST={security_permission_guard_test}")
print(f"SECURITY_AUDIT_EVENT_MODEL_TEST={security_audit_event_model_test}")
print(f"SECURITY_TENANT_ACCESS_TEST={security_tenant_access_test}")
print(f"SECURITY_SUPPORT_SUPER_ADMIN_BOUNDARY_TEST={security_support_super_admin_boundary_test}")
print(f"SECURITY_ARTIFACT_COVERAGE_TEST={security_artifact_coverage_test}")
print(f"SECURITY_NO_APPLY_TEST={security_no_apply_test}")
print(f"SECURITY_SECRET_SAFETY_TEST={security_secret_safety_test}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("PERMISSION_GUARD_EXECUTED=NO")
print("TENANT_ACCESS_CHECK_EXECUTED=NO")
print("SUPPORT_ACCESS_EXECUTED=NO")
print("SUPER_ADMIN_ACCESS_EXECUTED=NO")
print("BREAK_GLASS_EXECUTED=NO")
print("RBAC_ENFORCEMENT_EXECUTED=NO")
print("AUDIT_LOG_WRITE_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"SECURITY_TESTS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_21_6_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
