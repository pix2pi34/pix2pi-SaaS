#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "19_2_flow_detail_page_standard.md"
contract_file = report_dir / "19_2_flow_detail_page_contract.md"
route_manifest_file = report_dir / "19_2_flow_detail_page_route_manifest.tsv"
component_manifest_file = report_dir / "19_2_flow_detail_page_component_manifest.tsv"
report_file = report_dir / "19_2_flow_detail_page_report.md"
matrix_file = report_dir / "19_2_flow_detail_page_matrix.tsv"

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
detail("PANEL_ROUTE_DEPLOYED=NO")
detail("PANEL_BUILD_EXECUTED=NO")
detail("PANEL_RUNTIME_HISTORY_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=FLOW_DETAIL_PAGE_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_19_1_status = get_value(prev_19_1, "FAZ4B_19_1_FINAL_STATUS")
prev_19_1_domain = get_value(prev_19_1, "RUNTIME_FLOW_HISTORY")
prev_19_1_apply = get_value(prev_19_1, "DB_APPLY_EXECUTED")
prev_18_status = get_value(prev_18, "FAZ4B_18_FINAL_STATUS")

detail(f"PREVIOUS_19_1_FINAL_STATUS={prev_19_1_status}")
detail(f"PREVIOUS_19_1_RUNTIME_FLOW_HISTORY={prev_19_1_domain}")
detail(f"PREVIOUS_19_1_DB_APPLY_EXECUTED={prev_19_1_apply}")
detail(f"PREVIOUS_18_FINAL_STATUS={prev_18_status}")

if prev_19_1_status != "PASS":
    fail("19.1 final status PASS degil")
if prev_19_1_domain != "PASS":
    fail("19.1 runtime flow history PASS degil")
if prev_19_1_apply != "NO":
    fail("19.1 DB apply NO degil")
if prev_18_status != "PASS":
    fail("18 final closure PASS degil")

for path, label in [
    (standard_file, "standard doc"),
    (contract_file, "contract doc"),
    (route_manifest_file, "route manifest"),
    (component_manifest_file, "component manifest"),
]:
    if not path.exists():
        fail(f"{label} yok")

standard_text = read(standard_file)
contract_text = read(contract_file)
route_text = read(route_manifest_file)
component_text = read(component_manifest_file)

required_routes = [
    "/api/v1/admin/runtime-flows/:flow_run_id",
    "/api/v1/admin/runtime-flows/:flow_run_id/steps",
    "/api/v1/admin/runtime-flows/:flow_run_id/events",
    "/api/v1/admin/runtime-flows/:flow_run_id/timeline",
    "/api/v1/admin/runtime-flows/:flow_run_id/errors",
    "/api/v1/admin/runtime-flows/:flow_run_id/snapshots",
]

required_components = [
    "FlowSummaryHeader",
    "FlowStatusBadge",
    "FlowTraceBar",
    "FlowTimeline",
    "FlowStepList",
    "FlowEventList",
    "FlowErrorPanel",
    "FlowSnapshotPanel",
    "FlowActionBar",
    "FlowEmptyState",
    "FlowLoadingState",
    "FlowErrorState",
]

required_fields = [
    "runtime_flow_run_id",
    "tenant_id",
    "flow_run_no",
    "flow_type",
    "flow_name",
    "request_id",
    "correlation_id",
    "source_event_id",
    "status_code",
    "severity",
    "duration_ms",
    "runtime_flow_step_id",
    "runtime_flow_event_id",
    "runtime_flow_snapshot_id",
    "runtime_flow_error_link_id",
]

route_rows = tsv_rows(route_manifest_file)
component_rows = tsv_rows(component_manifest_file)

route_data_rows = max(0, len(route_rows) - 1)
component_data_rows = max(0, len(component_rows) - 1)

route_hit_count = sum(1 for route in required_routes if route in route_text and route in contract_text)
component_hit_count = sum(1 for component in required_components if component in contract_text and component in component_text)
field_hit_count = sum(1 for field in required_fields if field in contract_text)
tenant_required_count = count(r"\bYES\b", route_text)
auth_required_count = count(r"\bYES\b", route_text)
contract_only_count = count(r"\bcontract_only\b", route_text + component_text)
tenant_safety_count = count(r"tenant", standard_text + contract_text)
secret_safety_count = count(r"RAW_DSN_PRINTED=NO|AUTH_TOKEN_PRINTED=NO|QUERY_TEXT_PRINTED=NO", standard_text + contract_text)
page_route_count = count(r"/admin/runtime-flows/:flow_run_id", standard_text + contract_text)

detail(f"FLOW_DETAIL_PAGE_ROUTE_COUNT={route_data_rows}")
detail(f"FLOW_DETAIL_PAGE_REQUIRED_ROUTE_HIT_COUNT={route_hit_count}")
detail(f"FLOW_DETAIL_PAGE_COMPONENT_COUNT={component_data_rows}")
detail(f"FLOW_DETAIL_PAGE_REQUIRED_COMPONENT_HIT_COUNT={component_hit_count}")
detail(f"FLOW_DETAIL_PAGE_REQUIRED_FIELD_HIT_COUNT={field_hit_count}")
detail(f"FLOW_DETAIL_PAGE_TENANT_REQUIRED_MARK_COUNT={tenant_required_count}")
detail(f"FLOW_DETAIL_PAGE_AUTH_REQUIRED_MARK_COUNT={auth_required_count}")
detail(f"FLOW_DETAIL_PAGE_CONTRACT_ONLY_COUNT={contract_only_count}")
detail(f"FLOW_DETAIL_PAGE_TENANT_SAFETY_REF_COUNT={tenant_safety_count}")
detail(f"FLOW_DETAIL_PAGE_SECRET_SAFETY_REF_COUNT={secret_safety_count}")
detail(f"FLOW_DETAIL_PAGE_PANEL_ROUTE_COUNT={page_route_count}")

if route_data_rows != 6:
    fail("route manifest route count 6 degil")
if route_hit_count != 6:
    fail("required route hit count 6 degil")
if component_data_rows != 12:
    fail("component manifest component count 12 degil")
if component_hit_count != 12:
    fail("required component hit count 12 degil")
if field_hit_count < 15:
    fail("required field hit count 15 altinda")
if tenant_required_count < 12:
    fail("tenant/auth required YES count yetersiz")
if contract_only_count < 10:
    fail("contract_only count 10 altinda")
if tenant_safety_count < 10:
    fail("tenant safety reference count 10 altinda")
if secret_safety_count < 3:
    fail("secret safety reference count 3 altinda")
if page_route_count < 2:
    fail("page route count 2 altinda")

for route in required_routes:
    if route not in route_text:
        fail(f"route manifest eksik: {route}")
    if route not in contract_text:
        fail(f"contract route eksik: {route}")

for component in required_components:
    if component not in contract_text:
        fail(f"contract component eksik: {component}")
    if component not in component_text:
        fail(f"component manifest eksik: {component}")

secret_hits = []
for path in [standard_file, contract_file, route_manifest_file, component_manifest_file]:
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

detail(f"FLOW_DETAIL_PAGE_SECRET_HIT_COUNT={len(secret_hits)}")

if secret_hits:
    fail("secret/query leak bulundu: " + ",".join(secret_hits))

previous_status = "PASS" if prev_19_1_status == "PASS" and prev_19_1_domain == "PASS" and prev_19_1_apply == "NO" else "FAIL"
contract_status = "PASS" if field_hit_count >= 15 and route_hit_count == 6 and component_hit_count == 12 else "FAIL"
route_manifest_status = "PASS" if route_data_rows == 6 and route_hit_count == 6 else "FAIL"
component_manifest_status = "PASS" if component_data_rows == 12 and component_hit_count == 12 else "FAIL"
tenant_safety_status = "PASS" if tenant_safety_count >= 10 and tenant_required_count >= 12 else "FAIL"
no_apply_status = "PASS"
secret_status = "PASS" if not secret_hits and secret_safety_count >= 3 else "FAIL"

detail(f"FLOW_DETAIL_PAGE_PREVIOUS_19_1={previous_status}")
detail(f"FLOW_DETAIL_PAGE_CONTRACT={contract_status}")
detail(f"FLOW_DETAIL_PAGE_ROUTE_MANIFEST={route_manifest_status}")
detail(f"FLOW_DETAIL_PAGE_COMPONENT_MANIFEST={component_manifest_status}")
detail(f"FLOW_DETAIL_PAGE_TENANT_SAFETY={tenant_safety_status}")
detail(f"FLOW_DETAIL_PAGE_NO_APPLY={no_apply_status}")
detail(f"FLOW_DETAIL_PAGE_SECRET_SAFETY={secret_status}")

for name, status in [
    ("previous_19_1", previous_status),
    ("contract", contract_status),
    ("route_manifest", route_manifest_status),
    ("component_manifest", component_manifest_status),
    ("tenant_safety", tenant_safety_status),
    ("no_apply", no_apply_status),
    ("secret_safety", secret_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_19_1\t{previous_status}\truntime flow history prerequisite",
    f"contract\t{contract_status}\tfields={field_hit_count} routes={route_hit_count} components={component_hit_count}",
    f"route_manifest\t{route_manifest_status}\troute_count={route_data_rows}",
    f"component_manifest\t{component_manifest_status}\tcomponent_count={component_data_rows}",
    f"tenant_safety\t{tenant_safety_status}\ttenant_refs={tenant_safety_count} tenant_required={tenant_required_count}",
    f"no_apply\t{no_apply_status}\tcontract only",
    f"secret_safety\t{secret_status}\tsecret_hits={len(secret_hits)}",
    "db_mutation\tNO\tcontract only",
    "db_apply_executed\tNO\tcontract only",
    "migration_created\tNO\tcontract only",
    "panel_route_deployed\tNO\tcontract only",
    "panel_build_executed\tNO\tcontract only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"FLOW_DETAIL_PAGE={final_status}")
detail(f"FAZ4B_19_2_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 19.2 - Flow Detail Page Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"FLOW_DETAIL_PAGE={final_status}",
    f"FAZ4B_19_2_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/19_2_flow_detail_page_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Artifacts",
    "STANDARD_FILE=docs/phase4/19_2_flow_detail_page_standard.md",
    "CONTRACT_FILE=docs/phase4/19_2_flow_detail_page_contract.md",
    "ROUTE_MANIFEST_FILE=docs/phase4/19_2_flow_detail_page_route_manifest.tsv",
    "COMPONENT_MANIFEST_FILE=docs/phase4/19_2_flow_detail_page_component_manifest.tsv",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "PANEL_ROUTE_DEPLOYED=NO",
    "PANEL_BUILD_EXECUTED=NO",
    "PANEL_RUNTIME_HISTORY_EXECUTED=NO",
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
print(f"COMPONENT_MANIFEST_FILE={component_manifest_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"FLOW_DETAIL_PAGE_ROUTE_COUNT={route_data_rows}")
print(f"FLOW_DETAIL_PAGE_COMPONENT_COUNT={component_data_rows}")
print(f"FLOW_DETAIL_PAGE_REQUIRED_FIELD_HIT_COUNT={field_hit_count}")
print(f"FLOW_DETAIL_PAGE_PREVIOUS_19_1={previous_status}")
print(f"FLOW_DETAIL_PAGE_CONTRACT={contract_status}")
print(f"FLOW_DETAIL_PAGE_ROUTE_MANIFEST={route_manifest_status}")
print(f"FLOW_DETAIL_PAGE_COMPONENT_MANIFEST={component_manifest_status}")
print(f"FLOW_DETAIL_PAGE_TENANT_SAFETY={tenant_safety_status}")
print(f"FLOW_DETAIL_PAGE_NO_APPLY={no_apply_status}")
print(f"FLOW_DETAIL_PAGE_SECRET_SAFETY={secret_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("PANEL_ROUTE_DEPLOYED=NO")
print("PANEL_BUILD_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"FLOW_DETAIL_PAGE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_19_2_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
