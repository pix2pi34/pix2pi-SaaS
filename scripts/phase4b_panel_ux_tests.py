#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "19_7_panel_ux_tests_standard.md"
report_file = report_dir / "19_7_panel_ux_tests_report.md"
matrix_file = report_dir / "19_7_panel_ux_tests_matrix.tsv"
inventory_file = report_dir / "19_7_panel_ux_tests_inventory.tsv"
closure_file = report_dir / "19_panel_admin_professionalization_final_closure_report.md"

reports = {
    "14": report_dir / "14_migration_lifecycle_import_final_closure_report.md",
    "15": report_dir / "15_readmodel_reporting_final_closure_report.md",
    "18": report_dir / "18_inventory_pilot_motor_final_closure_report.md",
    "19.1": report_dir / "19_1_runtime_flow_history_report.md",
    "19.2": report_dir / "19_2_flow_detail_page_report.md",
    "19.3": report_dir / "19_3_admin_dashboard_cards_report.md",
    "19.4": report_dir / "19_4_import_wizard_ui_report.md",
    "19.5": report_dir / "19_5_uat_checklist_ui_report.md",
    "19.6": report_dir / "19_6_issue_feedback_ui_report.md",
}

domain_keys = {
    "19.1": "RUNTIME_FLOW_HISTORY",
    "19.2": "FLOW_DETAIL_PAGE",
    "19.3": "ADMIN_DASHBOARD_CARDS",
    "19.4": "IMPORT_WIZARD_UI",
    "19.5": "UAT_CHECKLIST_UI",
    "19.6": "ISSUE_FEEDBACK_UI",
}

test_names = {
    "19.1": "RUNTIME_FLOW_HISTORY_TEST",
    "19.2": "FLOW_DETAIL_PAGE_TEST",
    "19.3": "ADMIN_DASHBOARD_CARDS_TEST",
    "19.4": "IMPORT_WIZARD_UI_TEST",
    "19.5": "UAT_CHECKLIST_UI_TEST",
    "19.6": "ISSUE_FEEDBACK_UI_TEST",
}

artifact_sets = {
    "19.1": [
        "docs/phase4/19_1_runtime_flow_history_standard.md",
        "docs/phase4/19_1_runtime_flow_history_report.md",
        "docs/phase4/19_1_runtime_flow_history_inventory.tsv",
        "docs/phase4/19_1_runtime_flow_history_matrix.tsv",
        "db/migrations/20260428_191001_panel_runtime_flow_history.up.sql",
        "db/migrations/20260428_191001_panel_runtime_flow_history.down.sql",
    ],
    "19.2": [
        "docs/phase4/19_2_flow_detail_page_standard.md",
        "docs/phase4/19_2_flow_detail_page_contract.md",
        "docs/phase4/19_2_flow_detail_page_route_manifest.tsv",
        "docs/phase4/19_2_flow_detail_page_component_manifest.tsv",
        "docs/phase4/19_2_flow_detail_page_report.md",
        "docs/phase4/19_2_flow_detail_page_matrix.tsv",
    ],
    "19.3": [
        "docs/phase4/19_3_admin_dashboard_cards_standard.md",
        "docs/phase4/19_3_admin_dashboard_cards_contract.md",
        "docs/phase4/19_3_admin_dashboard_cards_manifest.tsv",
        "docs/phase4/19_3_admin_dashboard_metrics_manifest.tsv",
        "docs/phase4/19_3_admin_dashboard_cards_report.md",
        "docs/phase4/19_3_admin_dashboard_cards_matrix.tsv",
    ],
    "19.4": [
        "docs/phase4/19_4_import_wizard_ui_standard.md",
        "docs/phase4/19_4_import_wizard_ui_contract.md",
        "docs/phase4/19_4_import_wizard_ui_route_manifest.tsv",
        "docs/phase4/19_4_import_wizard_ui_step_manifest.tsv",
        "docs/phase4/19_4_import_wizard_ui_component_manifest.tsv",
        "docs/phase4/19_4_import_wizard_ui_report.md",
        "docs/phase4/19_4_import_wizard_ui_matrix.tsv",
    ],
    "19.5": [
        "docs/phase4/19_5_uat_checklist_ui_standard.md",
        "docs/phase4/19_5_uat_checklist_ui_contract.md",
        "docs/phase4/19_5_uat_checklist_ui_route_manifest.tsv",
        "docs/phase4/19_5_uat_checklist_ui_scenario_manifest.tsv",
        "docs/phase4/19_5_uat_checklist_ui_component_manifest.tsv",
        "docs/phase4/19_5_uat_checklist_ui_report.md",
        "docs/phase4/19_5_uat_checklist_ui_matrix.tsv",
    ],
    "19.6": [
        "docs/phase4/19_6_issue_feedback_ui_standard.md",
        "docs/phase4/19_6_issue_feedback_ui_contract.md",
        "docs/phase4/19_6_issue_feedback_ui_route_manifest.tsv",
        "docs/phase4/19_6_issue_feedback_ui_type_manifest.tsv",
        "docs/phase4/19_6_issue_feedback_ui_component_manifest.tsv",
        "docs/phase4/19_6_issue_feedback_ui_report.md",
        "docs/phase4/19_6_issue_feedback_ui_matrix.tsv",
    ],
}

no_apply_keys = {
    "19.1": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_APPLY_EXECUTED",
        "PANEL_RUNTIME_HISTORY_EXECUTED",
        "POSTGRES_CONFIG_CHANGED",
        "CONTAINER_RESTARTED",
        "QUERY_TEXT_PRINTED",
    ],
    "19.2": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "PANEL_ROUTE_DEPLOYED",
        "PANEL_BUILD_EXECUTED",
        "QUERY_TEXT_PRINTED",
    ],
    "19.3": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "PANEL_ROUTE_DEPLOYED",
        "PANEL_BUILD_EXECUTED",
        "PANEL_DASHBOARD_RUNTIME_EXECUTED",
        "QUERY_TEXT_PRINTED",
    ],
    "19.4": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "FILE_UPLOAD_EXECUTED",
        "IMPORT_RUNTIME_EXECUTED",
        "IMPORT_COMMIT_EXECUTED",
        "PANEL_ROUTE_DEPLOYED",
        "PANEL_BUILD_EXECUTED",
        "QUERY_TEXT_PRINTED",
    ],
    "19.5": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "UAT_RUNTIME_EXECUTED",
        "UAT_STATUS_UPDATE_EXECUTED",
        "UAT_EVIDENCE_UPLOAD_EXECUTED",
        "GO_LIVE_APPROVAL_EXECUTED",
        "PANEL_ROUTE_DEPLOYED",
        "PANEL_BUILD_EXECUTED",
        "QUERY_TEXT_PRINTED",
    ],
    "19.6": [
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "ISSUE_RUNTIME_EXECUTED",
        "ISSUE_CREATE_EXECUTED",
        "FEEDBACK_CREATE_EXECUTED",
        "ISSUE_STATUS_UPDATE_EXECUTED",
        "ISSUE_EVIDENCE_UPLOAD_EXECUTED",
        "PANEL_ROUTE_DEPLOYED",
        "PANEL_BUILD_EXECUTED",
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

def warn(msg):
    warnings.append(f"WARN ⚠️ {msg}")

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

def to_int(value):
    try:
        return int(str(value).strip())
    except Exception:
        return 0

def count(pattern, text, flags=re.IGNORECASE | re.MULTILINE):
    return len(re.findall(pattern, text, flags))

def all_current_migrations_valid():
    legacy_pattern = re.compile(
        r"^(?P<legacy_seq>\d{3})_(?P<name>[a-z0-9_]+)\.(?P<direction>up|down)\.sql$"
    )
    modern_pattern = re.compile(
        r"^(?P<date>\d{8})_(?P<seq>\d{4,8})_(?P<name>[a-z0-9_]+)\.(?P<direction>up|down)\.sql$"
    )

    all_sql = sorted(migration_dir.glob("*.sql")) if migration_dir.exists() else []
    invalid = []
    bases = {}

    for path in all_sql:
        m = modern_pattern.match(path.name)
        if m:
            base = f"{m.group('date')}_{m.group('seq')}_{m.group('name')}"
            direction = m.group("direction")
        else:
            m = legacy_pattern.match(path.name)
            if m:
                base = f"{m.group('legacy_seq')}_{m.group('name')}"
                direction = m.group("direction")
            else:
                invalid.append(path.name)
                continue

        bases.setdefault(base, {"up": 0, "down": 0})
        bases[base][direction] += 1

    missing = []
    duplicate = []
    for base, pair in bases.items():
        if pair["up"] != 1 or pair["down"] != 1:
            missing.append(base)
        if pair["up"] > 1 or pair["down"] > 1:
            duplicate.append(base)

    return {
        "sql_count": len(all_sql),
        "invalid_count": len(invalid),
        "pair_count": len(bases),
        "missing_pair_count": len(missing),
        "duplicate_pair_count": len(duplicate),
    }

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("PANEL_ROUTE_DEPLOYED=NO")
detail("PANEL_BUILD_EXECUTED=NO")
detail("PANEL_RUNTIME_EXECUTED=NO")
detail("FILE_UPLOAD_EXECUTED=NO")
detail("IMPORT_RUNTIME_EXECUTED=NO")
detail("IMPORT_COMMIT_EXECUTED=NO")
detail("UAT_RUNTIME_EXECUTED=NO")
detail("UAT_STATUS_UPDATE_EXECUTED=NO")
detail("UAT_EVIDENCE_UPLOAD_EXECUTED=NO")
detail("GO_LIVE_APPROVAL_EXECUTED=NO")
detail("ISSUE_RUNTIME_EXECUTED=NO")
detail("ISSUE_CREATE_EXECUTED=NO")
detail("FEEDBACK_CREATE_EXECUTED=NO")
detail("ISSUE_STATUS_UPDATE_EXECUTED=NO")
detail("ISSUE_EVIDENCE_UPLOAD_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=PANEL_UX_FINAL_EVIDENCE_ONLY")

for tool in ["python3", "bash", "grep", "wc"]:
    tool_status(tool)

if not standard_file.exists():
    fail("19.7 standard doc yok")

prev_14_status = get_value(reports["14"], "FAZ4B_14_FINAL_STATUS")
prev_15_status = get_value(reports["15"], "FAZ4B_15_FINAL_STATUS")
prev_18_status = get_value(reports["18"], "FAZ4B_18_FINAL_STATUS")

detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_15_FINAL_STATUS={prev_15_status}")
detail(f"PREVIOUS_18_FINAL_STATUS={prev_18_status}")

if prev_14_status != "PASS":
    fail("14 final status PASS degil")
if prev_15_status != "PASS":
    fail("15 final status PASS degil")
if prev_18_status != "PASS":
    fail("18 final status PASS degil")

block_results = {}
artifact_missing = []
no_apply_failures = []

for block in ["19.1", "19.2", "19.3", "19.4", "19.5", "19.6"]:
    path = reports[block]
    final_key = f"FAZ4B_19_{block.split('.')[1]}_FINAL_STATUS"
    domain_key = domain_keys[block]
    final_status = get_value(path, final_key)
    domain_status = get_value(path, domain_key)
    query_text = get_value(path, "QUERY_TEXT_PRINTED")

    status = "PASS" if final_status == "PASS" and domain_status == "PASS" and query_text == "NO" else "FAIL"

    detail(f"PREVIOUS_{block.replace('.', '_')}_FINAL_STATUS={final_status}")
    detail(f"PREVIOUS_{block.replace('.', '_')}_{domain_key}={domain_status}")
    detail(f"PREVIOUS_{block.replace('.', '_')}_QUERY_TEXT_PRINTED={query_text}")

    if status != "PASS":
        fail(f"{block} final/domain/query gate PASS degil")

    for key in no_apply_keys[block]:
        value = get_value(path, key)
        detail(f"PREVIOUS_{block.replace('.', '_')}_{key}={value}")
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

    detail(f"PANEL_{block.replace('.', '_')}_ARTIFACT_EXPECTED_COUNT={expected_artifact_count}")
    detail(f"PANEL_{block.replace('.', '_')}_ARTIFACT_EXISTING_COUNT={existing_artifact_count}")

    block_results[block] = {
        "status": status,
        "final_status": final_status,
        "domain_key": domain_key,
        "domain_status": domain_status,
        "report": path,
        "artifact_expected": expected_artifact_count,
        "artifact_existing": existing_artifact_count,
    }

if artifact_missing:
    fail("panel artifact eksik: " + ",".join(artifact_missing[:20]))

if no_apply_failures:
    fail("panel no-apply failure: " + ",".join(no_apply_failures[:30]))

# Coverage numbers from prior reports
flow_detail_routes = to_int(get_value(reports["19.2"], "FLOW_DETAIL_PAGE_ROUTE_COUNT"))
flow_detail_components = to_int(get_value(reports["19.2"], "FLOW_DETAIL_PAGE_COMPONENT_COUNT"))

dashboard_cards = to_int(get_value(reports["19.3"], "ADMIN_DASHBOARD_CARD_COUNT"))
dashboard_metrics = to_int(get_value(reports["19.3"], "ADMIN_DASHBOARD_METRIC_COUNT"))

import_routes = to_int(get_value(reports["19.4"], "IMPORT_WIZARD_ROUTE_COUNT"))
import_steps = to_int(get_value(reports["19.4"], "IMPORT_WIZARD_STEP_COUNT"))
import_components = to_int(get_value(reports["19.4"], "IMPORT_WIZARD_COMPONENT_COUNT"))

uat_routes = to_int(get_value(reports["19.5"], "UAT_CHECKLIST_ROUTE_COUNT"))
uat_scenarios = to_int(get_value(reports["19.5"], "UAT_CHECKLIST_SCENARIO_COUNT"))
uat_components = to_int(get_value(reports["19.5"], "UAT_CHECKLIST_COMPONENT_COUNT"))

issue_routes = to_int(get_value(reports["19.6"], "ISSUE_FEEDBACK_ROUTE_COUNT"))
issue_types = to_int(get_value(reports["19.6"], "ISSUE_FEEDBACK_TYPE_COUNT"))
issue_components = to_int(get_value(reports["19.6"], "ISSUE_FEEDBACK_COMPONENT_COUNT"))

detail(f"PANEL_FLOW_DETAIL_ROUTE_COUNT={flow_detail_routes}")
detail(f"PANEL_FLOW_DETAIL_COMPONENT_COUNT={flow_detail_components}")
detail(f"PANEL_DASHBOARD_CARD_COUNT={dashboard_cards}")
detail(f"PANEL_DASHBOARD_METRIC_COUNT={dashboard_metrics}")
detail(f"PANEL_IMPORT_ROUTE_COUNT={import_routes}")
detail(f"PANEL_IMPORT_STEP_COUNT={import_steps}")
detail(f"PANEL_IMPORT_COMPONENT_COUNT={import_components}")
detail(f"PANEL_UAT_ROUTE_COUNT={uat_routes}")
detail(f"PANEL_UAT_SCENARIO_COUNT={uat_scenarios}")
detail(f"PANEL_UAT_COMPONENT_COUNT={uat_components}")
detail(f"PANEL_ISSUE_ROUTE_COUNT={issue_routes}")
detail(f"PANEL_ISSUE_TYPE_COUNT={issue_types}")
detail(f"PANEL_ISSUE_COMPONENT_COUNT={issue_components}")

manifest_coverage_test = "PASS" if (
    flow_detail_routes >= 6
    and flow_detail_components >= 12
    and dashboard_cards >= 10
    and dashboard_metrics >= 20
    and import_routes >= 8
    and import_steps >= 8
    and import_components >= 15
    and uat_routes >= 8
    and uat_scenarios >= 15
    and uat_components >= 16
    and issue_routes >= 9
    and issue_types >= 10
    and issue_components >= 20
) else "FAIL"

if manifest_coverage_test != "PASS":
    fail("panel manifest coverage test PASS degil")

panel_contract_artifact_test = "PASS" if not artifact_missing else "FAIL"
panel_no_apply_test = "PASS" if not no_apply_failures else "FAIL"

# Tenant safety statuses from reports
tenant_status_keys = {
    "19.1": "RUNTIME_FLOW_HISTORY_TENANT_SAFETY_STATUS",
    "19.2": "FLOW_DETAIL_PAGE_TENANT_SAFETY",
    "19.3": "ADMIN_DASHBOARD_TENANT_SAFETY",
    "19.4": "IMPORT_WIZARD_TENANT_SAFETY",
    "19.5": "UAT_CHECKLIST_TENANT_SAFETY",
    "19.6": "ISSUE_FEEDBACK_TENANT_SAFETY",
}

tenant_failures = []
for block, key in tenant_status_keys.items():
    value = get_value(reports[block], key)
    detail(f"PANEL_{block.replace('.', '_')}_{key}={value}")
    if value != "PASS":
        tenant_failures.append(f"{block}:{key}={value}")

panel_tenant_safety_test = "PASS" if not tenant_failures else "FAIL"
if panel_tenant_safety_test != "PASS":
    fail("panel tenant safety test PASS degil: " + ",".join(tenant_failures))

# Linkage / drilldown checks
link_status_pairs = {
    "19.2": ["FLOW_DETAIL_PAGE_ROUTE_MANIFEST", "FLOW_DETAIL_PAGE_COMPONENT_MANIFEST"],
    "19.3": ["ADMIN_DASHBOARD_DRILLDOWN_STATUS"],
    "19.4": ["IMPORT_WIZARD_FLOW_LINK_STATUS"],
    "19.5": ["UAT_CHECKLIST_FLOW_ISSUE_STATUS", "UAT_CHECKLIST_READINESS_STATUS"],
    "19.6": ["ISSUE_FEEDBACK_LINKAGE_STATUS", "ISSUE_FEEDBACK_CLASSIFICATION_STATUS"],
}

link_failures = []
for block, keys in link_status_pairs.items():
    for key in keys:
        value = get_value(reports[block], key)
        detail(f"PANEL_{block.replace('.', '_')}_{key}={value}")
        if value != "PASS":
            link_failures.append(f"{block}:{key}={value}")

panel_ux_linkage_test = "PASS" if not link_failures else "FAIL"
if panel_ux_linkage_test != "PASS":
    fail("panel UX linkage test PASS degil: " + ",".join(link_failures))

# Migration chain still valid after 19.1 migration
chain = all_current_migrations_valid()
detail(f"CURRENT_MIGRATION_SQL_FILE_COUNT={chain['sql_count']}")
detail(f"CURRENT_MIGRATION_INVALID_NAME_COUNT={chain['invalid_count']}")
detail(f"CURRENT_MIGRATION_PAIR_COUNT={chain['pair_count']}")
detail(f"CURRENT_MIGRATION_MISSING_PAIR_COUNT={chain['missing_pair_count']}")
detail(f"CURRENT_MIGRATION_DUPLICATE_PAIR_COUNT={chain['duplicate_pair_count']}")

panel_migration_chain_test = "PASS" if (
    chain["invalid_count"] == 0
    and chain["missing_pair_count"] == 0
    and chain["duplicate_pair_count"] == 0
) else "FAIL"

if panel_migration_chain_test != "PASS":
    fail("panel migration chain test PASS degil")

# Secret scan
scan_files = []
for block, rels in artifact_sets.items():
    for rel in rels:
        p = root / rel
        if p.exists() and p.suffix in [".md", ".tsv"]:
            scan_files.append(p)
scan_files.append(standard_file)

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

detail(f"PANEL_SECRET_HIT_COUNT={len(secret_hits)}")
detail(f"PANEL_QUERY_TEXT_HIT_COUNT={len(query_hits)}")

panel_secret_safety_test = "PASS" if not secret_hits and not query_hits else "FAIL"
if panel_secret_safety_test != "PASS":
    fail("panel secret/query leak test PASS degil")

runtime_flow_history_test = block_results["19.1"]["status"]
flow_detail_page_test = block_results["19.2"]["status"]
admin_dashboard_cards_test = block_results["19.3"]["status"]
import_wizard_ui_test = block_results["19.4"]["status"]
uat_checklist_ui_test = block_results["19.5"]["status"]
issue_feedback_ui_test = block_results["19.6"]["status"]

for label, status in [
    ("RUNTIME_FLOW_HISTORY_TEST", runtime_flow_history_test),
    ("FLOW_DETAIL_PAGE_TEST", flow_detail_page_test),
    ("ADMIN_DASHBOARD_CARDS_TEST", admin_dashboard_cards_test),
    ("IMPORT_WIZARD_UI_TEST", import_wizard_ui_test),
    ("UAT_CHECKLIST_UI_TEST", uat_checklist_ui_test),
    ("ISSUE_FEEDBACK_UI_TEST", issue_feedback_ui_test),
    ("PANEL_CONTRACT_ARTIFACT_TEST", panel_contract_artifact_test),
    ("PANEL_MANIFEST_COVERAGE_TEST", manifest_coverage_test),
    ("PANEL_TENANT_SAFETY_TEST", panel_tenant_safety_test),
    ("PANEL_UX_LINKAGE_TEST", panel_ux_linkage_test),
    ("PANEL_MIGRATION_CHAIN_TEST", panel_migration_chain_test),
    ("PANEL_NO_APPLY_TEST", panel_no_apply_test),
    ("PANEL_SECRET_SAFETY_TEST", panel_secret_safety_test),
]:
    detail(f"{label}={status}")
    if status != "PASS":
        fail(f"{label} PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"runtime_flow_history_test\t{runtime_flow_history_test}\t19.1 runtime flow history evidence",
    f"flow_detail_page_test\t{flow_detail_page_test}\t19.2 flow detail page evidence",
    f"admin_dashboard_cards_test\t{admin_dashboard_cards_test}\t19.3 dashboard cards evidence",
    f"import_wizard_ui_test\t{import_wizard_ui_test}\t19.4 import wizard evidence",
    f"uat_checklist_ui_test\t{uat_checklist_ui_test}\t19.5 UAT checklist evidence",
    f"issue_feedback_ui_test\t{issue_feedback_ui_test}\t19.6 issue feedback evidence",
    f"panel_contract_artifact_test\t{panel_contract_artifact_test}\tmissing_artifacts={len(artifact_missing)}",
    f"panel_manifest_coverage_test\t{manifest_coverage_test}\tdashboard_cards={dashboard_cards} import_steps={import_steps} uat_scenarios={uat_scenarios} issue_types={issue_types}",
    f"panel_tenant_safety_test\t{panel_tenant_safety_test}\ttenant_failures={len(tenant_failures)}",
    f"panel_ux_linkage_test\t{panel_ux_linkage_test}\tlink_failures={len(link_failures)}",
    f"panel_migration_chain_test\t{panel_migration_chain_test}\tpairs={chain['pair_count']}",
    f"panel_no_apply_test\t{panel_no_apply_test}\tno_apply_failures={len(no_apply_failures)}",
    f"panel_secret_safety_test\t{panel_secret_safety_test}\tsecret_hits={len(secret_hits)} query_hits={len(query_hits)}",
    "db_mutation\tNO\tfinal evidence only",
    "db_apply_executed\tNO\tfinal evidence only",
    "migration_apply_executed\tNO\tfinal evidence only",
    "panel_route_deployed\tNO\tfinal evidence only",
    "panel_build_executed\tNO\tfinal evidence only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = ["block\tstatus\tdomain_key\treport_file\tartifact_expected\tartifact_existing\tprimary_evidence"]
for block in ["19.1", "19.2", "19.3", "19.4", "19.5", "19.6"]:
    result = block_results[block]
    inventory_lines.append(
        f"{block}\t{result['status']}\t{result['domain_key']}\t{str(result['report'].relative_to(root))}\t{result['artifact_expected']}\t{result['artifact_existing']}\t{result['domain_key']}={result['domain_status']}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

detail(f"PANEL_UX_TEST_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"PANEL_UX_TEST_INVENTORY_LINE_COUNT={len(inventory_lines)}")

final_status = "PASS" if not failures else "FAIL"

detail(f"PANEL_UX_TEST_SET={final_status}")
detail(f"PANEL_ADMIN_FINAL_CLOSURE={final_status}")
detail(f"FAZ4B_19_7_FINAL_STATUS={final_status}")
detail(f"FAZ4B_19_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 19.7 - Panel UX Tests + Final Closure Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"PANEL_UX_TEST_SET={final_status}",
    f"PANEL_ADMIN_FINAL_CLOSURE={final_status}",
    f"FAZ4B_19_7_FINAL_STATUS={final_status}",
    f"FAZ4B_19_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/19_7_panel_ux_tests_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/19_7_panel_ux_tests_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "PANEL_ROUTE_DEPLOYED=NO",
    "PANEL_BUILD_EXECUTED=NO",
    "PANEL_RUNTIME_EXECUTED=NO",
    "FILE_UPLOAD_EXECUTED=NO",
    "IMPORT_RUNTIME_EXECUTED=NO",
    "IMPORT_COMMIT_EXECUTED=NO",
    "UAT_RUNTIME_EXECUTED=NO",
    "UAT_STATUS_UPDATE_EXECUTED=NO",
    "UAT_EVIDENCE_UPLOAD_EXECUTED=NO",
    "GO_LIVE_APPROVAL_EXECUTED=NO",
    "ISSUE_RUNTIME_EXECUTED=NO",
    "ISSUE_CREATE_EXECUTED=NO",
    "FEEDBACK_CREATE_EXECUTED=NO",
    "ISSUE_STATUS_UPDATE_EXECUTED=NO",
    "ISSUE_EVIDENCE_UPLOAD_EXECUTED=NO",
    "POSTGRES_CONFIG_CHANGED=NO",
    "CONTAINER_RESTARTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
    "",
    "## Secret Safety",
    "RAW_DSN_PRINTED=NO",
    "POSTGRES_PASSWORD_PRINTED=NO",
    "AUTH_TOKEN_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

closure_lines = [
    "# FAZ 4B / 19 - Panel / Admin Profesyonelleştirme Final Closure",
    "",
    f"Generated at: {now()}",
    "",
    f"FAZ4B_19_FINAL_STATUS={final_status}",
    f"FAZ4B_19_7_FINAL_STATUS={final_status}",
    f"PANEL_UX_TEST_SET={final_status}",
    f"PANEL_ADMIN_FINAL_CLOSURE={final_status}",
    "",
    "## Closed Items",
    f"19.1 Runtime flow history={runtime_flow_history_test}",
    f"19.2 Flow detail page={flow_detail_page_test}",
    f"19.3 Admin dashboard cards={admin_dashboard_cards_test}",
    f"19.4 Import wizard UI={import_wizard_ui_test}",
    f"19.5 UAT checklist UI={uat_checklist_ui_test}",
    f"19.6 Issue / feedback UI={issue_feedback_ui_test}",
    f"19.7 Panel UX tests={final_status}",
    "",
    "## Final Gates",
    f"RUNTIME_FLOW_HISTORY_TEST={runtime_flow_history_test}",
    f"FLOW_DETAIL_PAGE_TEST={flow_detail_page_test}",
    f"ADMIN_DASHBOARD_CARDS_TEST={admin_dashboard_cards_test}",
    f"IMPORT_WIZARD_UI_TEST={import_wizard_ui_test}",
    f"UAT_CHECKLIST_UI_TEST={uat_checklist_ui_test}",
    f"ISSUE_FEEDBACK_UI_TEST={issue_feedback_ui_test}",
    f"PANEL_CONTRACT_ARTIFACT_TEST={panel_contract_artifact_test}",
    f"PANEL_MANIFEST_COVERAGE_TEST={manifest_coverage_test}",
    f"PANEL_TENANT_SAFETY_TEST={panel_tenant_safety_test}",
    f"PANEL_UX_LINKAGE_TEST={panel_ux_linkage_test}",
    f"PANEL_MIGRATION_CHAIN_TEST={panel_migration_chain_test}",
    f"PANEL_NO_APPLY_TEST={panel_no_apply_test}",
    f"PANEL_SECRET_SAFETY_TEST={panel_secret_safety_test}",
    "",
    "## Safety",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "PANEL_ROUTE_DEPLOYED=NO",
    "PANEL_BUILD_EXECUTED=NO",
    "QUERY_TEXT_PRINTED=NO",
]
closure_file.write_text("\n".join(closure_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"CLOSURE_FILE={closure_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"RUNTIME_FLOW_HISTORY_TEST={runtime_flow_history_test}")
print(f"FLOW_DETAIL_PAGE_TEST={flow_detail_page_test}")
print(f"ADMIN_DASHBOARD_CARDS_TEST={admin_dashboard_cards_test}")
print(f"IMPORT_WIZARD_UI_TEST={import_wizard_ui_test}")
print(f"UAT_CHECKLIST_UI_TEST={uat_checklist_ui_test}")
print(f"ISSUE_FEEDBACK_UI_TEST={issue_feedback_ui_test}")
print(f"PANEL_CONTRACT_ARTIFACT_TEST={panel_contract_artifact_test}")
print(f"PANEL_MANIFEST_COVERAGE_TEST={manifest_coverage_test}")
print(f"PANEL_TENANT_SAFETY_TEST={panel_tenant_safety_test}")
print(f"PANEL_UX_LINKAGE_TEST={panel_ux_linkage_test}")
print(f"PANEL_MIGRATION_CHAIN_TEST={panel_migration_chain_test}")
print(f"PANEL_NO_APPLY_TEST={panel_no_apply_test}")
print(f"PANEL_SECRET_SAFETY_TEST={panel_secret_safety_test}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("PANEL_ROUTE_DEPLOYED=NO")
print("PANEL_BUILD_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"PANEL_UX_TEST_SET={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"PANEL_ADMIN_FINAL_CLOSURE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_19_7_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_19_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
