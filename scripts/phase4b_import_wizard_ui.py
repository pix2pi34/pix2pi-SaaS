#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "19_4_import_wizard_ui_standard.md"
contract_file = report_dir / "19_4_import_wizard_ui_contract.md"
route_manifest_file = report_dir / "19_4_import_wizard_ui_route_manifest.tsv"
step_manifest_file = report_dir / "19_4_import_wizard_ui_step_manifest.tsv"
component_manifest_file = report_dir / "19_4_import_wizard_ui_component_manifest.tsv"
report_file = report_dir / "19_4_import_wizard_ui_report.md"
matrix_file = report_dir / "19_4_import_wizard_ui_matrix.tsv"

prev_19_3 = report_dir / "19_3_admin_dashboard_cards_report.md"
prev_19_2 = report_dir / "19_2_flow_detail_page_report.md"
prev_19_1 = report_dir / "19_1_runtime_flow_history_report.md"
prev_14 = report_dir / "14_migration_lifecycle_import_final_closure_report.md"
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
detail("FILE_UPLOAD_EXECUTED=NO")
detail("IMPORT_RUNTIME_EXECUTED=NO")
detail("IMPORT_COMMIT_EXECUTED=NO")
detail("PANEL_ROUTE_DEPLOYED=NO")
detail("PANEL_BUILD_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=IMPORT_WIZARD_UI_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_19_3_status = get_value(prev_19_3, "FAZ4B_19_3_FINAL_STATUS")
prev_19_3_domain = get_value(prev_19_3, "ADMIN_DASHBOARD_CARDS")
prev_19_3_apply = get_value(prev_19_3, "DB_APPLY_EXECUTED")
prev_19_2_status = get_value(prev_19_2, "FAZ4B_19_2_FINAL_STATUS")
prev_19_1_status = get_value(prev_19_1, "FAZ4B_19_1_FINAL_STATUS")
prev_14_status = get_value(prev_14, "FAZ4B_14_FINAL_STATUS")
prev_14_tests = get_value(prev_14, "MIGRATION_LIFECYCLE_IMPORT_TESTS")
prev_18_status = get_value(prev_18, "FAZ4B_18_FINAL_STATUS")

detail(f"PREVIOUS_19_3_FINAL_STATUS={prev_19_3_status}")
detail(f"PREVIOUS_19_3_ADMIN_DASHBOARD_CARDS={prev_19_3_domain}")
detail(f"PREVIOUS_19_3_DB_APPLY_EXECUTED={prev_19_3_apply}")
detail(f"PREVIOUS_19_2_FINAL_STATUS={prev_19_2_status}")
detail(f"PREVIOUS_19_1_FINAL_STATUS={prev_19_1_status}")
detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_14_MIGRATION_LIFECYCLE_IMPORT_TESTS={prev_14_tests}")
detail(f"PREVIOUS_18_FINAL_STATUS={prev_18_status}")

if prev_19_3_status != "PASS":
    fail("19.3 final status PASS degil")
if prev_19_3_domain != "PASS":
    fail("19.3 admin dashboard cards PASS degil")
if prev_19_3_apply != "NO":
    fail("19.3 DB apply NO degil")
if prev_19_2_status != "PASS":
    fail("19.2 final status PASS degil")
if prev_19_1_status != "PASS":
    fail("19.1 final status PASS degil")
if prev_14_status != "PASS":
    fail("14 final status PASS degil")
if prev_14_tests != "PASS":
    fail("14 import lifecycle tests PASS degil")
if prev_18_status != "PASS":
    fail("18 final status PASS degil")

for path, label in [
    (standard_file, "standard doc"),
    (contract_file, "contract doc"),
    (route_manifest_file, "route manifest"),
    (step_manifest_file, "step manifest"),
    (component_manifest_file, "component manifest"),
]:
    if not path.exists():
        fail(f"{label} yok")

standard_text = read(standard_file)
contract_text = read(contract_file)
route_text = read(route_manifest_file)
step_text = read(step_manifest_file)
component_text = read(component_manifest_file)
all_text = "\n".join([standard_text, contract_text, route_text, step_text, component_text])

required_routes = [
    "/api/v1/admin/imports/templates",
    "/api/v1/admin/imports/upload",
    "/api/v1/admin/imports/:import_batch_id/mapping",
    "/api/v1/admin/imports/:import_batch_id/validate",
    "/api/v1/admin/imports/:import_batch_id/preview",
    "/api/v1/admin/imports/:import_batch_id/errors",
    "/api/v1/admin/imports/:import_batch_id/commit-plan",
    "/api/v1/admin/imports/history",
]

required_steps = [
    "ImportTemplateStep",
    "ImportUploadStep",
    "ImportMappingStep",
    "ImportValidationStep",
    "ImportPreviewStep",
    "ImportErrorDownloadStep",
    "ImportCommitPlanStep",
    "ImportHistoryLinkStep",
]

required_components = [
    "ImportWizardShell",
    "ImportStepIndicator",
    "ImportTemplateSelector",
    "ImportFileDropzone",
    "ImportFileSummary",
    "ImportColumnMapper",
    "ImportValidationPanel",
    "ImportPreviewTable",
    "ImportErrorDownloadPanel",
    "ImportCommitPlanPanel",
    "ImportHistoryLinkPanel",
    "ImportFlowLinkPanel",
    "ImportEmptyState",
    "ImportLoadingState",
    "ImportErrorState",
]

required_fields = [
    "import_batch_id",
    "tenant_id",
    "import_type",
    "import_template_code",
    "upload_file_name",
    "upload_file_hash",
    "total_row_count",
    "valid_row_count",
    "invalid_row_count",
    "warning_count",
    "error_count",
    "mapping_status",
    "validation_status",
    "preview_status",
    "commit_plan_status",
    "runtime_flow_run_id",
    "request_id",
    "correlation_id",
    "created_at",
    "updated_at",
]

required_import_types = [
    "party_customer",
    "party_vendor",
    "product_item",
    "inventory_opening_stock",
    "inventory_stock_balance",
    "address_contact",
    "finance_opening_balance",
]

route_rows = tsv_rows(route_manifest_file)
step_rows = tsv_rows(step_manifest_file)
component_rows = tsv_rows(component_manifest_file)

route_data_rows = max(0, len(route_rows) - 1)
step_data_rows = max(0, len(step_rows) - 1)
component_data_rows = max(0, len(component_rows) - 1)

route_hit_count = sum(1 for route in required_routes if route in contract_text and route in route_text)
step_hit_count = sum(1 for step in required_steps if step in contract_text and step in step_text)
component_hit_count = sum(1 for component in required_components if component in contract_text and component in component_text)
field_hit_count = sum(1 for field in required_fields if field in contract_text)
import_type_hit_count = sum(1 for item in required_import_types if item in contract_text)

tenant_yes_count = count(r"\bYES\b", route_text + "\n" + step_text + "\n" + component_text)
auth_yes_count = count(r"\bYES\b", route_text)
contract_only_count = count(r"\bcontract_only\b", all_text)
tenant_ref_count = count(r"tenant", all_text)
import_ref_count = count(r"import", all_text)
wizard_route_count = count(r"/admin/imports/wizard", all_text)
flow_link_count = count(r"runtime_flow_run_id|Runtime flow|flow link|Flow", all_text)

detail(f"IMPORT_WIZARD_ROUTE_COUNT={route_data_rows}")
detail(f"IMPORT_WIZARD_REQUIRED_ROUTE_HIT_COUNT={route_hit_count}")
detail(f"IMPORT_WIZARD_STEP_COUNT={step_data_rows}")
detail(f"IMPORT_WIZARD_REQUIRED_STEP_HIT_COUNT={step_hit_count}")
detail(f"IMPORT_WIZARD_COMPONENT_COUNT={component_data_rows}")
detail(f"IMPORT_WIZARD_REQUIRED_COMPONENT_HIT_COUNT={component_hit_count}")
detail(f"IMPORT_WIZARD_REQUIRED_FIELD_HIT_COUNT={field_hit_count}")
detail(f"IMPORT_WIZARD_IMPORT_TYPE_HIT_COUNT={import_type_hit_count}")
detail(f"IMPORT_WIZARD_TENANT_YES_COUNT={tenant_yes_count}")
detail(f"IMPORT_WIZARD_AUTH_YES_COUNT={auth_yes_count}")
detail(f"IMPORT_WIZARD_CONTRACT_ONLY_COUNT={contract_only_count}")
detail(f"IMPORT_WIZARD_TENANT_REF_COUNT={tenant_ref_count}")
detail(f"IMPORT_WIZARD_IMPORT_REF_COUNT={import_ref_count}")
detail(f"IMPORT_WIZARD_PAGE_ROUTE_COUNT={wizard_route_count}")
detail(f"IMPORT_WIZARD_FLOW_LINK_COUNT={flow_link_count}")

if route_data_rows != 8:
    fail("route manifest route count 8 degil")
if route_hit_count != 8:
    fail("required route hit count 8 degil")
if step_data_rows != 8:
    fail("step manifest step count 8 degil")
if step_hit_count != 8:
    fail("required step hit count 8 degil")
if component_data_rows != 15:
    fail("component manifest component count 15 degil")
if component_hit_count != 15:
    fail("required component hit count 15 degil")
if field_hit_count != 20:
    fail("required field hit count 20 degil")
if import_type_hit_count != 7:
    fail("import type hit count 7 degil")
if tenant_yes_count < 30:
    fail("tenant YES count 30 altinda")
if auth_yes_count < 16:
    fail("auth YES count 16 altinda")
if contract_only_count < 25:
    fail("contract_only count 25 altinda")
if tenant_ref_count < 12:
    fail("tenant reference count 12 altinda")
if import_ref_count < 35:
    fail("import reference count 35 altinda")
if wizard_route_count < 2:
    fail("wizard route count 2 altinda")
if flow_link_count < 3:
    fail("runtime flow link count 3 altinda")

for route in required_routes:
    if route not in contract_text:
        fail(f"contract route eksik: {route}")
    if route not in route_text:
        fail(f"route manifest eksik: {route}")

for step in required_steps:
    if step not in contract_text:
        fail(f"contract step eksik: {step}")
    if step not in step_text:
        fail(f"step manifest eksik: {step}")

for component in required_components:
    if component not in contract_text:
        fail(f"contract component eksik: {component}")
    if component not in component_text:
        fail(f"component manifest eksik: {component}")

secret_hits = []
for path in [standard_file, contract_file, route_manifest_file, step_manifest_file, component_manifest_file]:
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

detail(f"IMPORT_WIZARD_SECRET_HIT_COUNT={len(secret_hits)}")

if secret_hits:
    fail("secret/query leak bulundu: " + ",".join(secret_hits))

previous_status = "PASS" if (
    prev_19_3_status == "PASS"
    and prev_19_3_domain == "PASS"
    and prev_19_3_apply == "NO"
    and prev_14_status == "PASS"
    and prev_18_status == "PASS"
) else "FAIL"

contract_status = "PASS" if route_hit_count == 8 and step_hit_count == 8 and field_hit_count == 20 else "FAIL"
route_manifest_status = "PASS" if route_data_rows == 8 and route_hit_count == 8 else "FAIL"
step_manifest_status = "PASS" if step_data_rows == 8 and step_hit_count == 8 else "FAIL"
component_manifest_status = "PASS" if component_data_rows == 15 and component_hit_count == 15 else "FAIL"
tenant_safety_status = "PASS" if tenant_yes_count >= 30 and tenant_ref_count >= 12 else "FAIL"
flow_link_status = "PASS" if flow_link_count >= 3 else "FAIL"
no_apply_status = "PASS"
secret_status = "PASS" if not secret_hits else "FAIL"

detail(f"IMPORT_WIZARD_PREVIOUS_19_3={previous_status}")
detail(f"IMPORT_WIZARD_CONTRACT={contract_status}")
detail(f"IMPORT_WIZARD_ROUTE_MANIFEST={route_manifest_status}")
detail(f"IMPORT_WIZARD_STEP_MANIFEST={step_manifest_status}")
detail(f"IMPORT_WIZARD_COMPONENT_MANIFEST={component_manifest_status}")
detail(f"IMPORT_WIZARD_TENANT_SAFETY={tenant_safety_status}")
detail(f"IMPORT_WIZARD_FLOW_LINK_STATUS={flow_link_status}")
detail(f"IMPORT_WIZARD_NO_APPLY={no_apply_status}")
detail(f"IMPORT_WIZARD_SECRET_SAFETY={secret_status}")

for name, status in [
    ("previous_19_3", previous_status),
    ("contract", contract_status),
    ("route_manifest", route_manifest_status),
    ("step_manifest", step_manifest_status),
    ("component_manifest", component_manifest_status),
    ("tenant_safety", tenant_safety_status),
    ("flow_link", flow_link_status),
    ("no_apply", no_apply_status),
    ("secret_safety", secret_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_19_3\t{previous_status}\tadmin dashboard cards prerequisite",
    f"contract\t{contract_status}\troutes={route_hit_count} steps={step_hit_count} fields={field_hit_count}",
    f"route_manifest\t{route_manifest_status}\troute_count={route_data_rows}",
    f"step_manifest\t{step_manifest_status}\tstep_count={step_data_rows}",
    f"component_manifest\t{component_manifest_status}\tcomponent_count={component_data_rows}",
    f"tenant_safety\t{tenant_safety_status}\ttenant_yes={tenant_yes_count} tenant_refs={tenant_ref_count}",
    f"flow_link\t{flow_link_status}\tflow_link_count={flow_link_count}",
    f"no_apply\t{no_apply_status}\tcontract only",
    f"secret_safety\t{secret_status}\tsecret_hits={len(secret_hits)}",
    "db_mutation\tNO\tcontract only",
    "db_apply_executed\tNO\tcontract only",
    "migration_created\tNO\tcontract only",
    "file_upload_executed\tNO\tcontract only",
    "import_runtime_executed\tNO\tcontract only",
    "import_commit_executed\tNO\tcontract only",
    "panel_route_deployed\tNO\tcontract only",
    "panel_build_executed\tNO\tcontract only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"IMPORT_WIZARD_UI={final_status}")
detail(f"FAZ4B_19_4_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 19.4 - Import Wizard UI Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"IMPORT_WIZARD_UI={final_status}",
    f"FAZ4B_19_4_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/19_4_import_wizard_ui_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Artifacts",
    "STANDARD_FILE=docs/phase4/19_4_import_wizard_ui_standard.md",
    "CONTRACT_FILE=docs/phase4/19_4_import_wizard_ui_contract.md",
    "ROUTE_MANIFEST_FILE=docs/phase4/19_4_import_wizard_ui_route_manifest.tsv",
    "STEP_MANIFEST_FILE=docs/phase4/19_4_import_wizard_ui_step_manifest.tsv",
    "COMPONENT_MANIFEST_FILE=docs/phase4/19_4_import_wizard_ui_component_manifest.tsv",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "FILE_UPLOAD_EXECUTED=NO",
    "IMPORT_RUNTIME_EXECUTED=NO",
    "IMPORT_COMMIT_EXECUTED=NO",
    "PANEL_ROUTE_DEPLOYED=NO",
    "PANEL_BUILD_EXECUTED=NO",
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
print(f"ROUTE_MANIFEST_FILE={route_manifest_file}")
print(f"STEP_MANIFEST_FILE={step_manifest_file}")
print(f"COMPONENT_MANIFEST_FILE={component_manifest_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"IMPORT_WIZARD_ROUTE_COUNT={route_data_rows}")
print(f"IMPORT_WIZARD_STEP_COUNT={step_data_rows}")
print(f"IMPORT_WIZARD_COMPONENT_COUNT={component_data_rows}")
print(f"IMPORT_WIZARD_REQUIRED_FIELD_HIT_COUNT={field_hit_count}")
print(f"IMPORT_WIZARD_IMPORT_TYPE_HIT_COUNT={import_type_hit_count}")
print(f"IMPORT_WIZARD_PREVIOUS_19_3={previous_status}")
print(f"IMPORT_WIZARD_CONTRACT={contract_status}")
print(f"IMPORT_WIZARD_ROUTE_MANIFEST={route_manifest_status}")
print(f"IMPORT_WIZARD_STEP_MANIFEST={step_manifest_status}")
print(f"IMPORT_WIZARD_COMPONENT_MANIFEST={component_manifest_status}")
print(f"IMPORT_WIZARD_TENANT_SAFETY={tenant_safety_status}")
print(f"IMPORT_WIZARD_FLOW_LINK_STATUS={flow_link_status}")
print(f"IMPORT_WIZARD_NO_APPLY={no_apply_status}")
print(f"IMPORT_WIZARD_SECRET_SAFETY={secret_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("FILE_UPLOAD_EXECUTED=NO")
print("IMPORT_RUNTIME_EXECUTED=NO")
print("IMPORT_COMMIT_EXECUTED=NO")
print("PANEL_ROUTE_DEPLOYED=NO")
print("PANEL_BUILD_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"IMPORT_WIZARD_UI={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_19_4_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
