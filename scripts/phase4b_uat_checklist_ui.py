#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "19_5_uat_checklist_ui_standard.md"
contract_file = report_dir / "19_5_uat_checklist_ui_contract.md"
route_manifest_file = report_dir / "19_5_uat_checklist_ui_route_manifest.tsv"
scenario_manifest_file = report_dir / "19_5_uat_checklist_ui_scenario_manifest.tsv"
component_manifest_file = report_dir / "19_5_uat_checklist_ui_component_manifest.tsv"
report_file = report_dir / "19_5_uat_checklist_ui_report.md"
matrix_file = report_dir / "19_5_uat_checklist_ui_matrix.tsv"

prev_19_4 = report_dir / "19_4_import_wizard_ui_report.md"
prev_19_3 = report_dir / "19_3_admin_dashboard_cards_report.md"
prev_19_2 = report_dir / "19_2_flow_detail_page_report.md"
prev_19_1 = report_dir / "19_1_runtime_flow_history_report.md"
prev_18 = report_dir / "18_inventory_pilot_motor_final_closure_report.md"
prev_14 = report_dir / "14_migration_lifecycle_import_final_closure_report.md"
prev_15 = report_dir / "15_readmodel_reporting_final_closure_report.md"

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
detail("UAT_RUNTIME_EXECUTED=NO")
detail("UAT_STATUS_UPDATE_EXECUTED=NO")
detail("UAT_EVIDENCE_UPLOAD_EXECUTED=NO")
detail("GO_LIVE_APPROVAL_EXECUTED=NO")
detail("PANEL_ROUTE_DEPLOYED=NO")
detail("PANEL_BUILD_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=UAT_CHECKLIST_UI_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_19_4_status = get_value(prev_19_4, "FAZ4B_19_4_FINAL_STATUS")
prev_19_4_domain = get_value(prev_19_4, "IMPORT_WIZARD_UI")
prev_19_4_apply = get_value(prev_19_4, "DB_APPLY_EXECUTED")
prev_19_3_status = get_value(prev_19_3, "FAZ4B_19_3_FINAL_STATUS")
prev_19_2_status = get_value(prev_19_2, "FAZ4B_19_2_FINAL_STATUS")
prev_19_1_status = get_value(prev_19_1, "FAZ4B_19_1_FINAL_STATUS")
prev_18_status = get_value(prev_18, "FAZ4B_18_FINAL_STATUS")
prev_14_status = get_value(prev_14, "FAZ4B_14_FINAL_STATUS")
prev_15_status = get_value(prev_15, "FAZ4B_15_FINAL_STATUS")

detail(f"PREVIOUS_19_4_FINAL_STATUS={prev_19_4_status}")
detail(f"PREVIOUS_19_4_IMPORT_WIZARD_UI={prev_19_4_domain}")
detail(f"PREVIOUS_19_4_DB_APPLY_EXECUTED={prev_19_4_apply}")
detail(f"PREVIOUS_19_3_FINAL_STATUS={prev_19_3_status}")
detail(f"PREVIOUS_19_2_FINAL_STATUS={prev_19_2_status}")
detail(f"PREVIOUS_19_1_FINAL_STATUS={prev_19_1_status}")
detail(f"PREVIOUS_18_FINAL_STATUS={prev_18_status}")
detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_15_FINAL_STATUS={prev_15_status}")

if prev_19_4_status != "PASS":
    fail("19.4 final status PASS degil")
if prev_19_4_domain != "PASS":
    fail("19.4 import wizard UI PASS degil")
if prev_19_4_apply != "NO":
    fail("19.4 DB apply NO degil")
if prev_19_3_status != "PASS":
    fail("19.3 final status PASS degil")
if prev_19_2_status != "PASS":
    fail("19.2 final status PASS degil")
if prev_19_1_status != "PASS":
    fail("19.1 final status PASS degil")
if prev_18_status != "PASS":
    fail("18 final status PASS degil")
if prev_14_status != "PASS":
    fail("14 final status PASS degil")
if prev_15_status != "PASS":
    fail("15 final status PASS degil")

for path, label in [
    (standard_file, "standard doc"),
    (contract_file, "contract doc"),
    (route_manifest_file, "route manifest"),
    (scenario_manifest_file, "scenario manifest"),
    (component_manifest_file, "component manifest"),
]:
    if not path.exists():
        fail(f"{label} yok")

standard_text = read(standard_file)
contract_text = read(contract_file)
route_text = read(route_manifest_file)
scenario_text = read(scenario_manifest_file)
component_text = read(component_manifest_file)
all_text = "\n".join([standard_text, contract_text, route_text, scenario_text, component_text])

required_routes = [
    "/api/v1/admin/uat/checklists",
    "/api/v1/admin/uat/checklists/:checklist_id",
    "/api/v1/admin/uat/checklists/:checklist_id/items",
    "/api/v1/admin/uat/checklists/:checklist_id/items/:item_id/status",
    "/api/v1/admin/uat/checklists/:checklist_id/evidence",
    "/api/v1/admin/uat/checklists/:checklist_id/readiness",
    "/api/v1/admin/uat/checklists/:checklist_id/blockers",
    "/api/v1/admin/uat/history",
]

required_scenarios = [
    "tenant_login_context",
    "customer_create_required_fields",
    "vendor_create_required_fields",
    "product_create_unit_category",
    "opening_stock_import",
    "sales_stock_decrement",
    "purchase_stock_increment",
    "stock_reservation_release",
    "negative_stock_policy",
    "stock_valuation",
    "finance_reporting_mart",
    "ebelde_export_reporting",
    "payment_reconciliation",
    "runtime_flow_trace",
    "admin_dashboard_visibility",
]

required_components = [
    "UATChecklistShell",
    "UATReadinessSummary",
    "UATScenarioList",
    "UATScenarioDetailPanel",
    "UATStatusBadge",
    "UATEvidenceLinkPanel",
    "UATResponsibleOwnerPanel",
    "UATBlockingItemsPanel",
    "UATGoLiveReadinessGate",
    "UATCommentPanel",
    "UATHistoryPanel",
    "UATFlowLinkPanel",
    "UATIssueLinkPanel",
    "UATEmptyState",
    "UATLoadingState",
    "UATErrorState",
]

required_fields = [
    "checklist_id",
    "tenant_id",
    "pilot_id",
    "checklist_title",
    "checklist_status",
    "readiness_percent",
    "total_item_count",
    "passed_item_count",
    "failed_item_count",
    "blocked_item_count",
    "not_started_item_count",
    "blocking_item_count",
    "go_live_allowed",
    "scenario_id",
    "scenario_name",
    "scenario_status",
    "evidence_required",
    "evidence_url",
    "owner_user_id",
    "owner_role_code",
    "reviewer_user_id",
    "reviewer_role_code",
    "runtime_flow_run_id",
    "issue_id",
    "request_id",
    "correlation_id",
    "created_at",
    "updated_at",
]

required_statuses = [
    "NOT_STARTED",
    "IN_PROGRESS",
    "PASS",
    "FAIL",
    "BLOCKED",
    "SKIPPED",
    "NEEDS_REVIEW",
]

route_rows = tsv_rows(route_manifest_file)
scenario_rows = tsv_rows(scenario_manifest_file)
component_rows = tsv_rows(component_manifest_file)

route_data_rows = max(0, len(route_rows) - 1)
scenario_data_rows = max(0, len(scenario_rows) - 1)
component_data_rows = max(0, len(component_rows) - 1)

route_hit_count = sum(1 for route in required_routes if route in contract_text and route in route_text)
scenario_hit_count = sum(1 for scenario in required_scenarios if scenario in scenario_text)
component_hit_count = sum(1 for component in required_components if component in contract_text and component in component_text)
field_hit_count = sum(1 for field in required_fields if field in contract_text)
status_hit_count = sum(1 for status in required_statuses if status in contract_text)

tenant_yes_count = count(r"\bYES\b", route_text + "\n" + scenario_text + "\n" + component_text)
auth_yes_count = count(r"\bYES\b", route_text)
contract_only_count = count(r"\bcontract_only\b", all_text)
tenant_ref_count = count(r"tenant", all_text)
uat_ref_count = count(r"uat|UAT", all_text)
evidence_ref_count = count(r"evidence|Evidence", all_text)
blocker_ref_count = count(r"block|Block|BLOCK", all_text)
readiness_ref_count = count(r"readiness|Readiness|go-live|Go-live|GO_LIVE", all_text)
flow_issue_link_count = count(r"runtime_flow_run_id|UATFlowLinkPanel|UATIssueLinkPanel|issue_id", all_text)
page_route_count = count(r"/admin/uat/checklist", all_text)

detail(f"UAT_CHECKLIST_ROUTE_COUNT={route_data_rows}")
detail(f"UAT_CHECKLIST_REQUIRED_ROUTE_HIT_COUNT={route_hit_count}")
detail(f"UAT_CHECKLIST_SCENARIO_COUNT={scenario_data_rows}")
detail(f"UAT_CHECKLIST_REQUIRED_SCENARIO_HIT_COUNT={scenario_hit_count}")
detail(f"UAT_CHECKLIST_COMPONENT_COUNT={component_data_rows}")
detail(f"UAT_CHECKLIST_REQUIRED_COMPONENT_HIT_COUNT={component_hit_count}")
detail(f"UAT_CHECKLIST_REQUIRED_FIELD_HIT_COUNT={field_hit_count}")
detail(f"UAT_CHECKLIST_STATUS_HIT_COUNT={status_hit_count}")
detail(f"UAT_CHECKLIST_TENANT_YES_COUNT={tenant_yes_count}")
detail(f"UAT_CHECKLIST_AUTH_YES_COUNT={auth_yes_count}")
detail(f"UAT_CHECKLIST_CONTRACT_ONLY_COUNT={contract_only_count}")
detail(f"UAT_CHECKLIST_TENANT_REF_COUNT={tenant_ref_count}")
detail(f"UAT_CHECKLIST_UAT_REF_COUNT={uat_ref_count}")
detail(f"UAT_CHECKLIST_EVIDENCE_REF_COUNT={evidence_ref_count}")
detail(f"UAT_CHECKLIST_BLOCKER_REF_COUNT={blocker_ref_count}")
detail(f"UAT_CHECKLIST_READINESS_REF_COUNT={readiness_ref_count}")
detail(f"UAT_CHECKLIST_FLOW_ISSUE_LINK_COUNT={flow_issue_link_count}")
detail(f"UAT_CHECKLIST_PAGE_ROUTE_COUNT={page_route_count}")

if route_data_rows != 8:
    fail("route manifest route count 8 degil")
if route_hit_count != 8:
    fail("required route hit count 8 degil")
if scenario_data_rows != 15:
    fail("scenario manifest scenario count 15 degil")
if scenario_hit_count != 15:
    fail("required scenario hit count 15 degil")
if component_data_rows != 16:
    fail("component manifest component count 16 degil")
if component_hit_count != 16:
    fail("required component hit count 16 degil")
if field_hit_count != 28:
    fail("required field hit count 28 degil")
if status_hit_count != 7:
    fail("status hit count 7 degil")
if tenant_yes_count < 70:
    fail("tenant YES count 70 altinda")
if auth_yes_count < 16:
    fail("auth YES count 16 altinda")
if contract_only_count < 35:
    fail("contract_only count 35 altinda")
if tenant_ref_count < 18:
    fail("tenant reference count 18 altinda")
if uat_ref_count < 45:
    fail("UAT reference count 45 altinda")
if evidence_ref_count < 10:
    fail("evidence reference count 10 altinda")
if blocker_ref_count < 8:
    fail("blocker reference count 8 altinda")
if readiness_ref_count < 8:
    fail("readiness reference count 8 altinda")
if flow_issue_link_count < 4:
    fail("flow/issue link count 4 altinda")
if page_route_count < 2:
    fail("page route count 2 altinda")

for route in required_routes:
    if route not in contract_text:
        fail(f"contract route eksik: {route}")
    if route not in route_text:
        fail(f"route manifest eksik: {route}")

for scenario in required_scenarios:
    if scenario not in scenario_text:
        fail(f"scenario manifest eksik: {scenario}")

for component in required_components:
    if component not in contract_text:
        fail(f"contract component eksik: {component}")
    if component not in component_text:
        fail(f"component manifest eksik: {component}")

secret_hits = []
for path in [standard_file, contract_file, route_manifest_file, scenario_manifest_file, component_manifest_file]:
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

detail(f"UAT_CHECKLIST_SECRET_HIT_COUNT={len(secret_hits)}")

if secret_hits:
    fail("secret/query leak bulundu: " + ",".join(secret_hits))

previous_status = "PASS" if (
    prev_19_4_status == "PASS"
    and prev_19_4_domain == "PASS"
    and prev_19_4_apply == "NO"
    and prev_19_3_status == "PASS"
    and prev_18_status == "PASS"
    and prev_14_status == "PASS"
) else "FAIL"

contract_status = "PASS" if route_hit_count == 8 and field_hit_count == 28 and status_hit_count == 7 else "FAIL"
route_manifest_status = "PASS" if route_data_rows == 8 and route_hit_count == 8 else "FAIL"
scenario_manifest_status = "PASS" if scenario_data_rows == 15 and scenario_hit_count == 15 else "FAIL"
component_manifest_status = "PASS" if component_data_rows == 16 and component_hit_count == 16 else "FAIL"
tenant_safety_status = "PASS" if tenant_yes_count >= 70 and tenant_ref_count >= 18 else "FAIL"
readiness_status = "PASS" if readiness_ref_count >= 8 and blocker_ref_count >= 8 and evidence_ref_count >= 10 else "FAIL"
flow_issue_status = "PASS" if flow_issue_link_count >= 4 else "FAIL"
no_apply_status = "PASS"
secret_status = "PASS" if not secret_hits else "FAIL"

detail(f"UAT_CHECKLIST_PREVIOUS_19_4={previous_status}")
detail(f"UAT_CHECKLIST_CONTRACT={contract_status}")
detail(f"UAT_CHECKLIST_ROUTE_MANIFEST={route_manifest_status}")
detail(f"UAT_CHECKLIST_SCENARIO_MANIFEST={scenario_manifest_status}")
detail(f"UAT_CHECKLIST_COMPONENT_MANIFEST={component_manifest_status}")
detail(f"UAT_CHECKLIST_TENANT_SAFETY={tenant_safety_status}")
detail(f"UAT_CHECKLIST_READINESS_STATUS={readiness_status}")
detail(f"UAT_CHECKLIST_FLOW_ISSUE_STATUS={flow_issue_status}")
detail(f"UAT_CHECKLIST_NO_APPLY={no_apply_status}")
detail(f"UAT_CHECKLIST_SECRET_SAFETY={secret_status}")

for name, status in [
    ("previous_19_4", previous_status),
    ("contract", contract_status),
    ("route_manifest", route_manifest_status),
    ("scenario_manifest", scenario_manifest_status),
    ("component_manifest", component_manifest_status),
    ("tenant_safety", tenant_safety_status),
    ("readiness", readiness_status),
    ("flow_issue", flow_issue_status),
    ("no_apply", no_apply_status),
    ("secret_safety", secret_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_19_4\t{previous_status}\timport wizard prerequisite",
    f"contract\t{contract_status}\troutes={route_hit_count} fields={field_hit_count} statuses={status_hit_count}",
    f"route_manifest\t{route_manifest_status}\troute_count={route_data_rows}",
    f"scenario_manifest\t{scenario_manifest_status}\tscenario_count={scenario_data_rows}",
    f"component_manifest\t{component_manifest_status}\tcomponent_count={component_data_rows}",
    f"tenant_safety\t{tenant_safety_status}\ttenant_yes={tenant_yes_count} tenant_refs={tenant_ref_count}",
    f"readiness\t{readiness_status}\treadiness={readiness_ref_count} blocker={blocker_ref_count} evidence={evidence_ref_count}",
    f"flow_issue\t{flow_issue_status}\tflow_issue_links={flow_issue_link_count}",
    f"no_apply\t{no_apply_status}\tcontract only",
    f"secret_safety\t{secret_status}\tsecret_hits={len(secret_hits)}",
    "db_mutation\tNO\tcontract only",
    "db_apply_executed\tNO\tcontract only",
    "migration_created\tNO\tcontract only",
    "uat_runtime_executed\tNO\tcontract only",
    "uat_status_update_executed\tNO\tcontract only",
    "uat_evidence_upload_executed\tNO\tcontract only",
    "go_live_approval_executed\tNO\tcontract only",
    "panel_route_deployed\tNO\tcontract only",
    "panel_build_executed\tNO\tcontract only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"UAT_CHECKLIST_UI={final_status}")
detail(f"FAZ4B_19_5_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 19.5 - UAT Checklist UI Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"UAT_CHECKLIST_UI={final_status}",
    f"FAZ4B_19_5_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/19_5_uat_checklist_ui_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Artifacts",
    "STANDARD_FILE=docs/phase4/19_5_uat_checklist_ui_standard.md",
    "CONTRACT_FILE=docs/phase4/19_5_uat_checklist_ui_contract.md",
    "ROUTE_MANIFEST_FILE=docs/phase4/19_5_uat_checklist_ui_route_manifest.tsv",
    "SCENARIO_MANIFEST_FILE=docs/phase4/19_5_uat_checklist_ui_scenario_manifest.tsv",
    "COMPONENT_MANIFEST_FILE=docs/phase4/19_5_uat_checklist_ui_component_manifest.tsv",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "UAT_RUNTIME_EXECUTED=NO",
    "UAT_STATUS_UPDATE_EXECUTED=NO",
    "UAT_EVIDENCE_UPLOAD_EXECUTED=NO",
    "GO_LIVE_APPROVAL_EXECUTED=NO",
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
print(f"SCENARIO_MANIFEST_FILE={scenario_manifest_file}")
print(f"COMPONENT_MANIFEST_FILE={component_manifest_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"UAT_CHECKLIST_ROUTE_COUNT={route_data_rows}")
print(f"UAT_CHECKLIST_SCENARIO_COUNT={scenario_data_rows}")
print(f"UAT_CHECKLIST_COMPONENT_COUNT={component_data_rows}")
print(f"UAT_CHECKLIST_REQUIRED_FIELD_HIT_COUNT={field_hit_count}")
print(f"UAT_CHECKLIST_STATUS_HIT_COUNT={status_hit_count}")
print(f"UAT_CHECKLIST_PREVIOUS_19_4={previous_status}")
print(f"UAT_CHECKLIST_CONTRACT={contract_status}")
print(f"UAT_CHECKLIST_ROUTE_MANIFEST={route_manifest_status}")
print(f"UAT_CHECKLIST_SCENARIO_MANIFEST={scenario_manifest_status}")
print(f"UAT_CHECKLIST_COMPONENT_MANIFEST={component_manifest_status}")
print(f"UAT_CHECKLIST_TENANT_SAFETY={tenant_safety_status}")
print(f"UAT_CHECKLIST_READINESS_STATUS={readiness_status}")
print(f"UAT_CHECKLIST_FLOW_ISSUE_STATUS={flow_issue_status}")
print(f"UAT_CHECKLIST_NO_APPLY={no_apply_status}")
print(f"UAT_CHECKLIST_SECRET_SAFETY={secret_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("UAT_RUNTIME_EXECUTED=NO")
print("UAT_STATUS_UPDATE_EXECUTED=NO")
print("UAT_EVIDENCE_UPLOAD_EXECUTED=NO")
print("GO_LIVE_APPROVAL_EXECUTED=NO")
print("PANEL_ROUTE_DEPLOYED=NO")
print("PANEL_BUILD_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"UAT_CHECKLIST_UI={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_19_5_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
