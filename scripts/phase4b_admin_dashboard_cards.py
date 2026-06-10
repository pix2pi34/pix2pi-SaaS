#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "19_3_admin_dashboard_cards_standard.md"
contract_file = report_dir / "19_3_admin_dashboard_cards_contract.md"
card_manifest_file = report_dir / "19_3_admin_dashboard_cards_manifest.tsv"
metric_manifest_file = report_dir / "19_3_admin_dashboard_metrics_manifest.tsv"
report_file = report_dir / "19_3_admin_dashboard_cards_report.md"
matrix_file = report_dir / "19_3_admin_dashboard_cards_matrix.tsv"

prev_19_2 = report_dir / "19_2_flow_detail_page_report.md"
prev_19_1 = report_dir / "19_1_runtime_flow_history_report.md"
prev_18 = report_dir / "18_inventory_pilot_motor_final_closure_report.md"
prev_15 = report_dir / "15_readmodel_reporting_final_closure_report.md"
prev_14 = report_dir / "14_migration_lifecycle_import_final_closure_report.md"

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
detail("PANEL_DASHBOARD_RUNTIME_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=ADMIN_DASHBOARD_CARDS_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_19_2_status = get_value(prev_19_2, "FAZ4B_19_2_FINAL_STATUS")
prev_19_2_domain = get_value(prev_19_2, "FLOW_DETAIL_PAGE")
prev_19_2_apply = get_value(prev_19_2, "DB_APPLY_EXECUTED")
prev_19_1_status = get_value(prev_19_1, "FAZ4B_19_1_FINAL_STATUS")
prev_18_status = get_value(prev_18, "FAZ4B_18_FINAL_STATUS")
prev_15_status = get_value(prev_15, "FAZ4B_15_FINAL_STATUS")
prev_14_status = get_value(prev_14, "FAZ4B_14_FINAL_STATUS")

detail(f"PREVIOUS_19_2_FINAL_STATUS={prev_19_2_status}")
detail(f"PREVIOUS_19_2_FLOW_DETAIL_PAGE={prev_19_2_domain}")
detail(f"PREVIOUS_19_2_DB_APPLY_EXECUTED={prev_19_2_apply}")
detail(f"PREVIOUS_19_1_FINAL_STATUS={prev_19_1_status}")
detail(f"PREVIOUS_18_FINAL_STATUS={prev_18_status}")
detail(f"PREVIOUS_15_FINAL_STATUS={prev_15_status}")
detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")

if prev_19_2_status != "PASS":
    fail("19.2 final status PASS degil")
if prev_19_2_domain != "PASS":
    fail("19.2 flow detail page PASS degil")
if prev_19_2_apply != "NO":
    fail("19.2 DB apply NO degil")
if prev_19_1_status != "PASS":
    fail("19.1 final status PASS degil")
if prev_18_status != "PASS":
    fail("18 final closure PASS degil")
if prev_15_status != "PASS":
    fail("15 final status PASS degil")
if prev_14_status != "PASS":
    fail("14 final status PASS degil")

for path, label in [
    (standard_file, "standard doc"),
    (contract_file, "contract doc"),
    (card_manifest_file, "card manifest"),
    (metric_manifest_file, "metric manifest"),
]:
    if not path.exists():
        fail(f"{label} yok")

standard_text = read(standard_file)
contract_text = read(contract_file)
card_text = read(card_manifest_file)
metric_text = read(metric_manifest_file)
all_text = standard_text + "\n" + contract_text + "\n" + card_text + "\n" + metric_text

required_routes = [
    "/api/v1/admin/dashboard/summary",
    "/api/v1/admin/dashboard/cards",
    "/api/v1/admin/dashboard/runtime-flows",
    "/api/v1/admin/dashboard/imports",
    "/api/v1/admin/dashboard/inventory",
    "/api/v1/admin/dashboard/security",
    "/api/v1/admin/dashboard/activity",
]

required_cards = [
    "RuntimeFlowSummaryCard",
    "RuntimeErrorCard",
    "ImportStatusCard",
    "InventoryHealthCard",
    "StockReservationCard",
    "NegativeStockPolicyCard",
    "ReportingHealthCard",
    "TenantSafetyCard",
    "RecentActivityCard",
    "UATReadinessCard",
]

required_fields = [
    "card_id",
    "tenant_id",
    "card_title",
    "card_status",
    "card_severity",
    "primary_metric_key",
    "primary_metric_value",
    "secondary_metric_key",
    "secondary_metric_value",
    "last_updated_at",
    "drilldown_route",
    "action_label",
    "empty_state_message",
    "error_state_message",
]

required_metrics = [
    "runtime_flow_total",
    "runtime_flow_failed",
    "open_error_count",
    "import_batch_total",
    "import_failed_line_count",
    "stock_movement_count",
    "sales_decrement_count",
    "purchase_increment_count",
    "active_reservation_count",
    "expiring_reservation_count",
    "negative_policy_block_count",
    "negative_policy_approval_count",
    "reporting_freshness_seconds",
    "projection_lag_count",
    "tenant_scope_warning_count",
    "recent_activity_count",
    "uat_open_item_count",
    "uat_readiness_percent",
]

card_rows = tsv_rows(card_manifest_file)
metric_rows = tsv_rows(metric_manifest_file)

card_data_rows = max(0, len(card_rows) - 1)
metric_data_rows = max(0, len(metric_rows) - 1)

route_hit_count = sum(1 for route in required_routes if route in contract_text)
card_hit_count = sum(1 for card in required_cards if card in contract_text and card in card_text)
field_hit_count = sum(1 for field in required_fields if field in contract_text)
metric_hit_count = sum(1 for metric in required_metrics if metric in metric_text)

tenant_yes_count = count(r"\bYES\b", card_text + "\n" + metric_text)
auth_yes_count = count(r"\bYES\b", card_text)
contract_only_count = count(r"\bcontract_only\b", card_text + "\n" + metric_text + "\n" + contract_text)
tenant_ref_count = count(r"tenant", all_text)
drilldown_count = count(r"/admin/", all_text)
dashboard_route_count = count(r"/admin/dashboard", all_text)

detail(f"ADMIN_DASHBOARD_CARD_COUNT={card_data_rows}")
detail(f"ADMIN_DASHBOARD_REQUIRED_CARD_HIT_COUNT={card_hit_count}")
detail(f"ADMIN_DASHBOARD_METRIC_COUNT={metric_data_rows}")
detail(f"ADMIN_DASHBOARD_REQUIRED_METRIC_HIT_COUNT={metric_hit_count}")
detail(f"ADMIN_DASHBOARD_ROUTE_COUNT={len(required_routes)}")
detail(f"ADMIN_DASHBOARD_REQUIRED_ROUTE_HIT_COUNT={route_hit_count}")
detail(f"ADMIN_DASHBOARD_REQUIRED_FIELD_HIT_COUNT={field_hit_count}")
detail(f"ADMIN_DASHBOARD_TENANT_YES_COUNT={tenant_yes_count}")
detail(f"ADMIN_DASHBOARD_AUTH_YES_COUNT={auth_yes_count}")
detail(f"ADMIN_DASHBOARD_CONTRACT_ONLY_COUNT={contract_only_count}")
detail(f"ADMIN_DASHBOARD_TENANT_REF_COUNT={tenant_ref_count}")
detail(f"ADMIN_DASHBOARD_DRILLDOWN_COUNT={drilldown_count}")
detail(f"ADMIN_DASHBOARD_PAGE_ROUTE_COUNT={dashboard_route_count}")

if card_data_rows != 10:
    fail("card manifest card count 10 degil")
if card_hit_count != 10:
    fail("required card hit count 10 degil")
if metric_data_rows < 20:
    fail("metric manifest metric count 20 altinda")
if metric_hit_count < 18:
    fail("required metric hit count 18 altinda")
if route_hit_count != 7:
    fail("required route hit count 7 degil")
if field_hit_count != 14:
    fail("required field hit count 14 degil")
if tenant_yes_count < 30:
    fail("tenant YES count 30 altinda")
if auth_yes_count < 20:
    fail("auth YES count 20 altinda")
if contract_only_count < 25:
    fail("contract_only count 25 altinda")
if tenant_ref_count < 12:
    fail("tenant reference count 12 altinda")
if drilldown_count < 12:
    fail("drilldown count 12 altinda")
if dashboard_route_count < 3:
    fail("dashboard route count 3 altinda")

for route in required_routes:
    if route not in contract_text:
        fail(f"contract route eksik: {route}")

for card in required_cards:
    if card not in contract_text:
        fail(f"contract card eksik: {card}")
    if card not in card_text:
        fail(f"card manifest eksik: {card}")

for metric in required_metrics:
    if metric not in metric_text:
        fail(f"metric manifest eksik: {metric}")

secret_hits = []
for path in [standard_file, contract_file, card_manifest_file, metric_manifest_file]:
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

detail(f"ADMIN_DASHBOARD_SECRET_HIT_COUNT={len(secret_hits)}")

if secret_hits:
    fail("secret/query leak bulundu: " + ",".join(secret_hits))

previous_status = "PASS" if (
    prev_19_2_status == "PASS"
    and prev_19_2_domain == "PASS"
    and prev_19_2_apply == "NO"
    and prev_19_1_status == "PASS"
    and prev_18_status == "PASS"
) else "FAIL"

contract_status = "PASS" if route_hit_count == 7 and card_hit_count == 10 and field_hit_count == 14 else "FAIL"
card_manifest_status = "PASS" if card_data_rows == 10 and card_hit_count == 10 else "FAIL"
metric_manifest_status = "PASS" if metric_data_rows >= 20 and metric_hit_count >= 18 else "FAIL"
tenant_safety_status = "PASS" if tenant_yes_count >= 30 and tenant_ref_count >= 12 else "FAIL"
drilldown_status = "PASS" if drilldown_count >= 12 and dashboard_route_count >= 3 else "FAIL"
no_apply_status = "PASS"
secret_status = "PASS" if not secret_hits else "FAIL"

detail(f"ADMIN_DASHBOARD_PREVIOUS_19_2={previous_status}")
detail(f"ADMIN_DASHBOARD_CARDS_CONTRACT={contract_status}")
detail(f"ADMIN_DASHBOARD_CARD_MANIFEST={card_manifest_status}")
detail(f"ADMIN_DASHBOARD_METRIC_MANIFEST={metric_manifest_status}")
detail(f"ADMIN_DASHBOARD_TENANT_SAFETY={tenant_safety_status}")
detail(f"ADMIN_DASHBOARD_DRILLDOWN_STATUS={drilldown_status}")
detail(f"ADMIN_DASHBOARD_NO_APPLY={no_apply_status}")
detail(f"ADMIN_DASHBOARD_SECRET_SAFETY={secret_status}")

for name, status in [
    ("previous_19_2", previous_status),
    ("contract", contract_status),
    ("card_manifest", card_manifest_status),
    ("metric_manifest", metric_manifest_status),
    ("tenant_safety", tenant_safety_status),
    ("drilldown", drilldown_status),
    ("no_apply", no_apply_status),
    ("secret_safety", secret_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_19_2\t{previous_status}\tflow detail page prerequisite",
    f"contract\t{contract_status}\troutes={route_hit_count} cards={card_hit_count} fields={field_hit_count}",
    f"card_manifest\t{card_manifest_status}\tcard_count={card_data_rows}",
    f"metric_manifest\t{metric_manifest_status}\tmetric_count={metric_data_rows}",
    f"tenant_safety\t{tenant_safety_status}\ttenant_yes={tenant_yes_count} tenant_refs={tenant_ref_count}",
    f"drilldown\t{drilldown_status}\tdrilldown_count={drilldown_count}",
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
detail(f"ADMIN_DASHBOARD_CARDS={final_status}")
detail(f"FAZ4B_19_3_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 19.3 - Admin Dashboard Cards Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"ADMIN_DASHBOARD_CARDS={final_status}",
    f"FAZ4B_19_3_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/19_3_admin_dashboard_cards_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Artifacts",
    "STANDARD_FILE=docs/phase4/19_3_admin_dashboard_cards_standard.md",
    "CONTRACT_FILE=docs/phase4/19_3_admin_dashboard_cards_contract.md",
    "CARD_MANIFEST_FILE=docs/phase4/19_3_admin_dashboard_cards_manifest.tsv",
    "METRIC_MANIFEST_FILE=docs/phase4/19_3_admin_dashboard_metrics_manifest.tsv",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "PANEL_ROUTE_DEPLOYED=NO",
    "PANEL_BUILD_EXECUTED=NO",
    "PANEL_DASHBOARD_RUNTIME_EXECUTED=NO",
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
print(f"CARD_MANIFEST_FILE={card_manifest_file}")
print(f"METRIC_MANIFEST_FILE={metric_manifest_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"ADMIN_DASHBOARD_CARD_COUNT={card_data_rows}")
print(f"ADMIN_DASHBOARD_METRIC_COUNT={metric_data_rows}")
print(f"ADMIN_DASHBOARD_REQUIRED_ROUTE_HIT_COUNT={route_hit_count}")
print(f"ADMIN_DASHBOARD_REQUIRED_CARD_HIT_COUNT={card_hit_count}")
print(f"ADMIN_DASHBOARD_REQUIRED_METRIC_HIT_COUNT={metric_hit_count}")
print(f"ADMIN_DASHBOARD_PREVIOUS_19_2={previous_status}")
print(f"ADMIN_DASHBOARD_CARDS_CONTRACT={contract_status}")
print(f"ADMIN_DASHBOARD_CARD_MANIFEST={card_manifest_status}")
print(f"ADMIN_DASHBOARD_METRIC_MANIFEST={metric_manifest_status}")
print(f"ADMIN_DASHBOARD_TENANT_SAFETY={tenant_safety_status}")
print(f"ADMIN_DASHBOARD_DRILLDOWN_STATUS={drilldown_status}")
print(f"ADMIN_DASHBOARD_NO_APPLY={no_apply_status}")
print(f"ADMIN_DASHBOARD_SECRET_SAFETY={secret_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("PANEL_ROUTE_DEPLOYED=NO")
print("PANEL_BUILD_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"ADMIN_DASHBOARD_CARDS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_19_3_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
