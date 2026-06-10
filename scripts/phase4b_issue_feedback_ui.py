#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "19_6_issue_feedback_ui_standard.md"
contract_file = report_dir / "19_6_issue_feedback_ui_contract.md"
route_manifest_file = report_dir / "19_6_issue_feedback_ui_route_manifest.tsv"
type_manifest_file = report_dir / "19_6_issue_feedback_ui_type_manifest.tsv"
component_manifest_file = report_dir / "19_6_issue_feedback_ui_component_manifest.tsv"
report_file = report_dir / "19_6_issue_feedback_ui_report.md"
matrix_file = report_dir / "19_6_issue_feedback_ui_matrix.tsv"

prev_19_5 = report_dir / "19_5_uat_checklist_ui_report.md"
prev_19_4 = report_dir / "19_4_import_wizard_ui_report.md"
prev_19_3 = report_dir / "19_3_admin_dashboard_cards_report.md"
prev_19_2 = report_dir / "19_2_flow_detail_page_report.md"
prev_19_1 = report_dir / "19_1_runtime_flow_history_report.md"
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
detail("ISSUE_RUNTIME_EXECUTED=NO")
detail("ISSUE_CREATE_EXECUTED=NO")
detail("FEEDBACK_CREATE_EXECUTED=NO")
detail("ISSUE_STATUS_UPDATE_EXECUTED=NO")
detail("ISSUE_EVIDENCE_UPLOAD_EXECUTED=NO")
detail("PANEL_ROUTE_DEPLOYED=NO")
detail("PANEL_BUILD_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=ISSUE_FEEDBACK_UI_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_19_5_status = get_value(prev_19_5, "FAZ4B_19_5_FINAL_STATUS")
prev_19_5_domain = get_value(prev_19_5, "UAT_CHECKLIST_UI")
prev_19_5_apply = get_value(prev_19_5, "DB_APPLY_EXECUTED")
prev_19_4_status = get_value(prev_19_4, "FAZ4B_19_4_FINAL_STATUS")
prev_19_3_status = get_value(prev_19_3, "FAZ4B_19_3_FINAL_STATUS")
prev_19_2_status = get_value(prev_19_2, "FAZ4B_19_2_FINAL_STATUS")
prev_19_1_status = get_value(prev_19_1, "FAZ4B_19_1_FINAL_STATUS")
prev_18_status = get_value(prev_18, "FAZ4B_18_FINAL_STATUS")

detail(f"PREVIOUS_19_5_FINAL_STATUS={prev_19_5_status}")
detail(f"PREVIOUS_19_5_UAT_CHECKLIST_UI={prev_19_5_domain}")
detail(f"PREVIOUS_19_5_DB_APPLY_EXECUTED={prev_19_5_apply}")
detail(f"PREVIOUS_19_4_FINAL_STATUS={prev_19_4_status}")
detail(f"PREVIOUS_19_3_FINAL_STATUS={prev_19_3_status}")
detail(f"PREVIOUS_19_2_FINAL_STATUS={prev_19_2_status}")
detail(f"PREVIOUS_19_1_FINAL_STATUS={prev_19_1_status}")
detail(f"PREVIOUS_18_FINAL_STATUS={prev_18_status}")

if prev_19_5_status != "PASS":
    fail("19.5 final status PASS degil")
if prev_19_5_domain != "PASS":
    fail("19.5 UAT checklist UI PASS degil")
if prev_19_5_apply != "NO":
    fail("19.5 DB apply NO degil")
if prev_19_4_status != "PASS":
    fail("19.4 final status PASS degil")
if prev_19_3_status != "PASS":
    fail("19.3 final status PASS degil")
if prev_19_2_status != "PASS":
    fail("19.2 final status PASS degil")
if prev_19_1_status != "PASS":
    fail("19.1 final status PASS degil")
if prev_18_status != "PASS":
    fail("18 final status PASS degil")

for path, label in [
    (standard_file, "standard doc"),
    (contract_file, "contract doc"),
    (route_manifest_file, "route manifest"),
    (type_manifest_file, "type manifest"),
    (component_manifest_file, "component manifest"),
]:
    if not path.exists():
        fail(f"{label} yok")

standard_text = read(standard_file)
contract_text = read(contract_file)
route_text = read(route_manifest_file)
type_text = read(type_manifest_file)
component_text = read(component_manifest_file)
all_text = "\n".join([standard_text, contract_text, route_text, type_text, component_text])

required_routes = [
    "/api/v1/admin/issues/summary",
    "/api/v1/admin/issues",
    "/api/v1/admin/issues/:issue_id",
    "/api/v1/admin/issues/:issue_id/comments",
    "/api/v1/admin/issues/:issue_id/evidence",
    "/api/v1/admin/issues/:issue_id/status",
    "/api/v1/admin/feedback",
]

required_types = [
    "bug",
    "feedback",
    "feature_request",
    "question",
    "data_issue",
    "import_issue",
    "inventory_issue",
    "reporting_issue",
    "security_concern",
    "uat_blocker",
]

required_components = [
    "IssueFeedbackShell",
    "IssueSummaryCards",
    "IssueCreateForm",
    "FeedbackCreateForm",
    "IssueTypeSelector",
    "IssueSeveritySelector",
    "IssuePrioritySelector",
    "IssueContextLinkPanel",
    "IssueRuntimeFlowLinkPanel",
    "IssueUATLinkPanel",
    "IssueImportLinkPanel",
    "IssueEvidencePanel",
    "IssueCommentPanel",
    "IssueStatusTimeline",
    "IssueAssigneePanel",
    "IssueListTable",
    "FeedbackListTable",
    "IssueEmptyState",
    "IssueLoadingState",
    "IssueErrorState",
]

required_fields = [
    "issue_id",
    "feedback_id",
    "tenant_id",
    "issue_no",
    "feedback_no",
    "issue_type",
    "feedback_type",
    "issue_title",
    "issue_description",
    "issue_status",
    "feedback_status",
    "severity",
    "priority",
    "source_page",
    "source_route",
    "runtime_flow_run_id",
    "uat_checklist_id",
    "uat_item_id",
    "import_batch_id",
    "inventory_context_id",
    "evidence_required",
    "evidence_url",
    "assignee_user_id",
    "reporter_user_id",
    "reporter_role_code",
    "request_id",
    "correlation_id",
    "created_at",
    "updated_at",
]

required_issue_statuses = [
    "OPEN",
    "TRIAGED",
    "IN_PROGRESS",
    "WAITING_USER",
    "RESOLVED",
    "CLOSED",
    "DUPLICATE",
    "CANCELLED",
]

required_feedback_statuses = [
    "NEW",
    "REVIEWED",
    "ACCEPTED",
    "PLANNED",
    "REJECTED",
    "ARCHIVED",
]

route_rows = tsv_rows(route_manifest_file)
type_rows = tsv_rows(type_manifest_file)
component_rows = tsv_rows(component_manifest_file)

route_data_rows = max(0, len(route_rows) - 1)
type_data_rows = max(0, len(type_rows) - 1)
component_data_rows = max(0, len(component_rows) - 1)

route_hit_count = sum(1 for route in required_routes if route in contract_text and route in route_text)
type_hit_count = sum(1 for issue_type in required_types if issue_type in type_text)
component_hit_count = sum(1 for component in required_components if component in contract_text and component in component_text)
field_hit_count = sum(1 for field in required_fields if field in contract_text)
issue_status_hit_count = sum(1 for status in required_issue_statuses if status in contract_text)
feedback_status_hit_count = sum(1 for status in required_feedback_statuses if status in contract_text)

tenant_yes_count = count(r"\bYES\b", route_text + "\n" + type_text + "\n" + component_text)
auth_yes_count = count(r"\bYES\b", route_text)
contract_only_count = count(r"\bcontract_only\b", all_text)
tenant_ref_count = count(r"tenant", all_text)
issue_ref_count = count(r"issue|Issue", all_text)
feedback_ref_count = count(r"feedback|Feedback", all_text)
evidence_ref_count = count(r"evidence|Evidence", all_text)
severity_ref_count = count(r"severity|Severity|CRITICAL|HIGH|MEDIUM|LOW|INFO", all_text)
priority_ref_count = count(r"priority|Priority|P0|P1|P2|P3|P4", all_text)
linkage_ref_count = count(r"runtime_flow_run_id|uat_checklist_id|import_batch_id|inventory_context_id|evidence_url", all_text)
page_route_count = count(r"/admin/issues-feedback", all_text)

detail(f"ISSUE_FEEDBACK_ROUTE_COUNT={route_data_rows}")
detail(f"ISSUE_FEEDBACK_REQUIRED_ROUTE_HIT_COUNT={route_hit_count}")
detail(f"ISSUE_FEEDBACK_TYPE_COUNT={type_data_rows}")
detail(f"ISSUE_FEEDBACK_REQUIRED_TYPE_HIT_COUNT={type_hit_count}")
detail(f"ISSUE_FEEDBACK_COMPONENT_COUNT={component_data_rows}")
detail(f"ISSUE_FEEDBACK_REQUIRED_COMPONENT_HIT_COUNT={component_hit_count}")
detail(f"ISSUE_FEEDBACK_REQUIRED_FIELD_HIT_COUNT={field_hit_count}")
detail(f"ISSUE_FEEDBACK_ISSUE_STATUS_HIT_COUNT={issue_status_hit_count}")
detail(f"ISSUE_FEEDBACK_FEEDBACK_STATUS_HIT_COUNT={feedback_status_hit_count}")
detail(f"ISSUE_FEEDBACK_TENANT_YES_COUNT={tenant_yes_count}")
detail(f"ISSUE_FEEDBACK_AUTH_YES_COUNT={auth_yes_count}")
detail(f"ISSUE_FEEDBACK_CONTRACT_ONLY_COUNT={contract_only_count}")
detail(f"ISSUE_FEEDBACK_TENANT_REF_COUNT={tenant_ref_count}")
detail(f"ISSUE_FEEDBACK_ISSUE_REF_COUNT={issue_ref_count}")
detail(f"ISSUE_FEEDBACK_FEEDBACK_REF_COUNT={feedback_ref_count}")
detail(f"ISSUE_FEEDBACK_EVIDENCE_REF_COUNT={evidence_ref_count}")
detail(f"ISSUE_FEEDBACK_SEVERITY_REF_COUNT={severity_ref_count}")
detail(f"ISSUE_FEEDBACK_PRIORITY_REF_COUNT={priority_ref_count}")
detail(f"ISSUE_FEEDBACK_LINKAGE_REF_COUNT={linkage_ref_count}")
detail(f"ISSUE_FEEDBACK_PAGE_ROUTE_COUNT={page_route_count}")

if route_data_rows != 9:
    fail("route manifest route count 9 degil")
if route_hit_count < 7:
    fail("required route hit count 7 altinda")
if type_data_rows != 10:
    fail("type manifest type count 10 degil")
if type_hit_count != 10:
    fail("required type hit count 10 degil")
if component_data_rows != 20:
    fail("component manifest component count 20 degil")
if component_hit_count != 20:
    fail("required component hit count 20 degil")
if field_hit_count != 29:
    fail("required field hit count 29 degil")
if issue_status_hit_count != 8:
    fail("issue status hit count 8 degil")
if feedback_status_hit_count != 6:
    fail("feedback status hit count 6 degil")
if tenant_yes_count < 45:
    fail("tenant YES count 45 altinda")
if auth_yes_count < 18:
    fail("auth YES count 18 altinda")
if contract_only_count < 38:
    fail("contract_only count 38 altinda")
if tenant_ref_count < 22:
    fail("tenant reference count 22 altinda")
if issue_ref_count < 55:
    fail("issue reference count 55 altinda")
if feedback_ref_count < 18:
    fail("feedback reference count 18 altinda")
if evidence_ref_count < 10:
    fail("evidence reference count 10 altinda")
if severity_ref_count < 10:
    fail("severity reference count 10 altinda")
if priority_ref_count < 10:
    fail("priority reference count 10 altinda")
if linkage_ref_count < 8:
    fail("linkage reference count 8 altinda")
if page_route_count < 2:
    fail("page route count 2 altinda")

for route in required_routes:
    if route not in contract_text:
        fail(f"contract route eksik: {route}")
    if route not in route_text:
        fail(f"route manifest eksik: {route}")

for issue_type in required_types:
    if issue_type not in type_text:
        fail(f"type manifest eksik: {issue_type}")

for component in required_components:
    if component not in contract_text:
        fail(f"contract component eksik: {component}")
    if component not in component_text:
        fail(f"component manifest eksik: {component}")

secret_hits = []
for path in [standard_file, contract_file, route_manifest_file, type_manifest_file, component_manifest_file]:
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

detail(f"ISSUE_FEEDBACK_SECRET_HIT_COUNT={len(secret_hits)}")

if secret_hits:
    fail("secret/query leak bulundu: " + ",".join(secret_hits))

previous_status = "PASS" if (
    prev_19_5_status == "PASS"
    and prev_19_5_domain == "PASS"
    and prev_19_5_apply == "NO"
    and prev_19_4_status == "PASS"
    and prev_19_1_status == "PASS"
    and prev_18_status == "PASS"
) else "FAIL"

contract_status = "PASS" if route_hit_count >= 7 and field_hit_count == 29 and issue_status_hit_count == 8 and feedback_status_hit_count == 6 else "FAIL"
route_manifest_status = "PASS" if route_data_rows == 9 and route_hit_count >= 7 else "FAIL"
type_manifest_status = "PASS" if type_data_rows == 10 and type_hit_count == 10 else "FAIL"
component_manifest_status = "PASS" if component_data_rows == 20 and component_hit_count == 20 else "FAIL"
tenant_safety_status = "PASS" if tenant_yes_count >= 45 and tenant_ref_count >= 22 else "FAIL"
linkage_status = "PASS" if linkage_ref_count >= 8 and evidence_ref_count >= 10 else "FAIL"
classification_status = "PASS" if severity_ref_count >= 10 and priority_ref_count >= 10 else "FAIL"
no_apply_status = "PASS"
secret_status = "PASS" if not secret_hits else "FAIL"

detail(f"ISSUE_FEEDBACK_PREVIOUS_19_5={previous_status}")
detail(f"ISSUE_FEEDBACK_CONTRACT={contract_status}")
detail(f"ISSUE_FEEDBACK_ROUTE_MANIFEST={route_manifest_status}")
detail(f"ISSUE_FEEDBACK_TYPE_MANIFEST={type_manifest_status}")
detail(f"ISSUE_FEEDBACK_COMPONENT_MANIFEST={component_manifest_status}")
detail(f"ISSUE_FEEDBACK_TENANT_SAFETY={tenant_safety_status}")
detail(f"ISSUE_FEEDBACK_LINKAGE_STATUS={linkage_status}")
detail(f"ISSUE_FEEDBACK_CLASSIFICATION_STATUS={classification_status}")
detail(f"ISSUE_FEEDBACK_NO_APPLY={no_apply_status}")
detail(f"ISSUE_FEEDBACK_SECRET_SAFETY={secret_status}")

for name, status in [
    ("previous_19_5", previous_status),
    ("contract", contract_status),
    ("route_manifest", route_manifest_status),
    ("type_manifest", type_manifest_status),
    ("component_manifest", component_manifest_status),
    ("tenant_safety", tenant_safety_status),
    ("linkage", linkage_status),
    ("classification", classification_status),
    ("no_apply", no_apply_status),
    ("secret_safety", secret_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_19_5\t{previous_status}\tUAT checklist prerequisite",
    f"contract\t{contract_status}\troutes={route_hit_count} fields={field_hit_count} issue_status={issue_status_hit_count} feedback_status={feedback_status_hit_count}",
    f"route_manifest\t{route_manifest_status}\troute_count={route_data_rows}",
    f"type_manifest\t{type_manifest_status}\ttype_count={type_data_rows}",
    f"component_manifest\t{component_manifest_status}\tcomponent_count={component_data_rows}",
    f"tenant_safety\t{tenant_safety_status}\ttenant_yes={tenant_yes_count} tenant_refs={tenant_ref_count}",
    f"linkage\t{linkage_status}\tlinkage_refs={linkage_ref_count} evidence_refs={evidence_ref_count}",
    f"classification\t{classification_status}\tseverity_refs={severity_ref_count} priority_refs={priority_ref_count}",
    f"no_apply\t{no_apply_status}\tcontract only",
    f"secret_safety\t{secret_status}\tsecret_hits={len(secret_hits)}",
    "db_mutation\tNO\tcontract only",
    "db_apply_executed\tNO\tcontract only",
    "migration_created\tNO\tcontract only",
    "issue_runtime_executed\tNO\tcontract only",
    "issue_create_executed\tNO\tcontract only",
    "feedback_create_executed\tNO\tcontract only",
    "issue_status_update_executed\tNO\tcontract only",
    "issue_evidence_upload_executed\tNO\tcontract only",
    "panel_route_deployed\tNO\tcontract only",
    "panel_build_executed\tNO\tcontract only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"ISSUE_FEEDBACK_UI={final_status}")
detail(f"FAZ4B_19_6_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 19.6 - Issue / Feedback UI Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"ISSUE_FEEDBACK_UI={final_status}",
    f"FAZ4B_19_6_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/19_6_issue_feedback_ui_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Artifacts",
    "STANDARD_FILE=docs/phase4/19_6_issue_feedback_ui_standard.md",
    "CONTRACT_FILE=docs/phase4/19_6_issue_feedback_ui_contract.md",
    "ROUTE_MANIFEST_FILE=docs/phase4/19_6_issue_feedback_ui_route_manifest.tsv",
    "TYPE_MANIFEST_FILE=docs/phase4/19_6_issue_feedback_ui_type_manifest.tsv",
    "COMPONENT_MANIFEST_FILE=docs/phase4/19_6_issue_feedback_ui_component_manifest.tsv",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "ISSUE_RUNTIME_EXECUTED=NO",
    "ISSUE_CREATE_EXECUTED=NO",
    "FEEDBACK_CREATE_EXECUTED=NO",
    "ISSUE_STATUS_UPDATE_EXECUTED=NO",
    "ISSUE_EVIDENCE_UPLOAD_EXECUTED=NO",
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
print(f"TYPE_MANIFEST_FILE={type_manifest_file}")
print(f"COMPONENT_MANIFEST_FILE={component_manifest_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"ISSUE_FEEDBACK_ROUTE_COUNT={route_data_rows}")
print(f"ISSUE_FEEDBACK_TYPE_COUNT={type_data_rows}")
print(f"ISSUE_FEEDBACK_COMPONENT_COUNT={component_data_rows}")
print(f"ISSUE_FEEDBACK_REQUIRED_FIELD_HIT_COUNT={field_hit_count}")
print(f"ISSUE_FEEDBACK_ISSUE_STATUS_HIT_COUNT={issue_status_hit_count}")
print(f"ISSUE_FEEDBACK_FEEDBACK_STATUS_HIT_COUNT={feedback_status_hit_count}")
print(f"ISSUE_FEEDBACK_PREVIOUS_19_5={previous_status}")
print(f"ISSUE_FEEDBACK_CONTRACT={contract_status}")
print(f"ISSUE_FEEDBACK_ROUTE_MANIFEST={route_manifest_status}")
print(f"ISSUE_FEEDBACK_TYPE_MANIFEST={type_manifest_status}")
print(f"ISSUE_FEEDBACK_COMPONENT_MANIFEST={component_manifest_status}")
print(f"ISSUE_FEEDBACK_TENANT_SAFETY={tenant_safety_status}")
print(f"ISSUE_FEEDBACK_LINKAGE_STATUS={linkage_status}")
print(f"ISSUE_FEEDBACK_CLASSIFICATION_STATUS={classification_status}")
print(f"ISSUE_FEEDBACK_NO_APPLY={no_apply_status}")
print(f"ISSUE_FEEDBACK_SECRET_SAFETY={secret_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("ISSUE_RUNTIME_EXECUTED=NO")
print("ISSUE_CREATE_EXECUTED=NO")
print("FEEDBACK_CREATE_EXECUTED=NO")
print("ISSUE_STATUS_UPDATE_EXECUTED=NO")
print("ISSUE_EVIDENCE_UPLOAD_EXECUTED=NO")
print("PANEL_ROUTE_DEPLOYED=NO")
print("PANEL_BUILD_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"ISSUE_FEEDBACK_UI={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_19_6_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
