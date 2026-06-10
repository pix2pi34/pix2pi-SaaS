#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "16_6_pilot_uat_onboarding_tests_standard.md"
report_file = report_dir / "16_6_pilot_uat_onboarding_tests_report.md"
matrix_file = report_dir / "16_6_pilot_uat_onboarding_tests_matrix.tsv"
inventory_file = report_dir / "16_6_pilot_uat_onboarding_tests_inventory.tsv"

reports = {
    "16.1": report_dir / "16_1_pilot_uat_onboarding_baseline_report.md",
    "16.2": report_dir / "16_2_pilot_tenant_readiness_contract_report.md",
    "16.3": report_dir / "16_3_uat_scenario_execution_contract_report.md",
    "16.4": report_dir / "16_4_pilot_data_readiness_contract_report.md",
    "16.5": report_dir / "16_5_go_no_go_rollout_gate_report.md",
    "17": report_dir / "17_workflow_realtime_ui_final_closure_report.md",
    "20": report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md",
    "21": report_dir / "21_security_rbac_audit_final_closure_report.md",
    "22": report_dir / "22_observability_ops_console_final_closure_report.md",
}

final_keys = {
    "16.1": "FAZ4B_16_1_FINAL_STATUS",
    "16.2": "FAZ4B_16_2_FINAL_STATUS",
    "16.3": "FAZ4B_16_3_FINAL_STATUS",
    "16.4": "FAZ4B_16_4_FINAL_STATUS",
    "16.5": "FAZ4B_16_5_FINAL_STATUS",
}

domain_keys = {
    "16.1": "PILOT_UAT_ONBOARDING_BASELINE",
    "16.2": "PILOT_TENANT_READINESS_CONTRACT",
    "16.3": "UAT_SCENARIO_EXECUTION_CONTRACT",
    "16.4": "PILOT_DATA_READINESS_CONTRACT",
    "16.5": "GO_NO_GO_ROLLOUT_GATE",
}

required_pass_keys = {
    "16.1": [
        "PILOT_PREVIOUS_FOUNDATION",
        "PILOT_SCOPE_INVENTORY",
        "PILOT_UAT_SCENARIO_CATALOG",
        "PILOT_ONBOARDING_CHECKLIST",
        "PILOT_ROLLOUT_GATE_MATRIX",
        "PILOT_NO_RUNTIME_CHANGE",
        "PILOT_NO_CONFIG_CHANGE",
        "PILOT_SECRET_SAFE",
    ],
    "16.2": [
        "PILOT_TENANT_PREVIOUS_16_1",
        "PILOT_TENANT_READINESS_CATALOG",
        "PILOT_ROLE_PERMISSION_MATRIX",
        "PILOT_ONBOARDING_OWNER_MATRIX",
        "PILOT_EVIDENCE_ACCEPTANCE_MATRIX",
        "PILOT_TRAINING_SUPPORT_PLAN",
        "PILOT_TENANT_NO_RUNTIME_CHANGE",
        "PILOT_TENANT_NO_CONFIG_CHANGE",
        "PILOT_TENANT_SECRET_SAFE",
    ],
    "16.3": [
        "UAT_PREVIOUS_16_2",
        "UAT_EXECUTION_PLAN",
        "UAT_ACTOR_MATRIX",
        "UAT_EVIDENCE_MATRIX",
        "UAT_BLOCKER_POLICY",
        "UAT_NO_RUNTIME_CHANGE",
        "UAT_NO_CONFIG_CHANGE",
        "UAT_SECRET_SAFE",
    ],
    "16.4": [
        "PILOT_DATA_PREVIOUS_16_3",
        "PILOT_PRODUCT_SAMPLE_DATASET",
        "PILOT_STOCK_SAMPLE_DATASET",
        "PILOT_PARTY_SAMPLE_DATASET",
        "PILOT_SALES_ACCOUNTING_SAMPLE_DATASET",
        "PILOT_DATA_QUALITY_GATE_MATRIX",
        "PILOT_DATA_NO_RUNTIME_CHANGE",
        "PILOT_DATA_NO_CONFIG_CHANGE",
        "PILOT_DATA_SECRET_SAFE",
    ],
    "16.5": [
        "GO_NO_GO_PREVIOUS_16_4",
        "GO_NO_GO_DECISION_MATRIX",
        "GO_NO_GO_BLOCKER_POLICY",
        "GO_NO_GO_SECURITY_TENANT_GATE",
        "GO_NO_GO_BUSINESS_CHAIN_GATE",
        "GO_NO_GO_SUPPORT_INCIDENT_GATE",
        "GO_NO_GO_NO_RUNTIME_CHANGE",
        "GO_NO_GO_NO_CONFIG_CHANGE",
        "GO_NO_GO_SECRET_SAFE",
    ],
}

required_no_keys = {
    "16.1": [
        "SERVICE_RESTARTED", "CONTAINER_RESTARTED", "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED", "FIREWALL_CHANGED", "PORT_CHANGED",
        "CONFIG_CHANGED", "ENV_CHANGED", "UI_CODE_CHANGED", "API_ROUTE_CREATED",
        "API_IMPLEMENTATION_CHANGED", "DB_MUTATION", "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED", "MIGRATION_APPLY_EXECUTED", "EVENT_PUBLISHED",
        "EVENT_CONSUMED", "NOTIFICATION_SENT", "CUSTOMER_PRIVATE_DATA_PRINTED",
        "RAW_DSN_PRINTED", "SECRET_VALUE_PRINTED", "TOKEN_PRINTED",
    ],
    "16.2": [
        "SERVICE_RESTARTED", "CONTAINER_RESTARTED", "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED", "FIREWALL_CHANGED", "PORT_CHANGED",
        "CONFIG_CHANGED", "ENV_CHANGED", "TENANT_CREATED", "USER_CREATED",
        "PASSWORD_CREATED", "TOKEN_CREATED", "UI_CODE_CHANGED", "API_ROUTE_CREATED",
        "API_IMPLEMENTATION_CHANGED", "DB_MUTATION", "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED", "MIGRATION_APPLY_EXECUTED", "EVENT_PUBLISHED",
        "EVENT_CONSUMED", "NOTIFICATION_SENT", "CUSTOMER_PRIVATE_DATA_PRINTED",
        "RAW_DSN_PRINTED", "SECRET_VALUE_PRINTED", "TOKEN_PRINTED",
    ],
    "16.3": [
        "SERVICE_RESTARTED", "CONTAINER_RESTARTED", "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED", "FIREWALL_CHANGED", "PORT_CHANGED",
        "CONFIG_CHANGED", "ENV_CHANGED", "TENANT_CREATED", "USER_CREATED",
        "PASSWORD_CREATED", "TOKEN_CREATED", "UAT_EXECUTED", "REAL_SALE_CREATED",
        "REAL_STOCK_MUTATED", "REAL_ACCOUNTING_ENTRY_CREATED", "UI_CODE_CHANGED",
        "API_ROUTE_CREATED", "API_IMPLEMENTATION_CHANGED", "DB_MUTATION",
        "DB_APPLY_EXECUTED", "MIGRATION_CREATED", "MIGRATION_APPLY_EXECUTED",
        "EVENT_PUBLISHED", "EVENT_CONSUMED", "NOTIFICATION_SENT",
        "CUSTOMER_PRIVATE_DATA_PRINTED", "RAW_DSN_PRINTED", "SECRET_VALUE_PRINTED",
        "TOKEN_PRINTED",
    ],
    "16.4": [
        "SERVICE_RESTARTED", "CONTAINER_RESTARTED", "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED", "FIREWALL_CHANGED", "PORT_CHANGED",
        "CONFIG_CHANGED", "ENV_CHANGED", "SAMPLE_DATA_INSERTED",
        "REAL_CUSTOMER_DATA_CREATED", "REAL_PRODUCT_CREATED", "REAL_STOCK_MUTATED",
        "REAL_SALE_CREATED", "REAL_ACCOUNTING_ENTRY_CREATED", "DATA_IMPORT_EXECUTED",
        "FILE_EXPORT_EXECUTED", "UI_CODE_CHANGED", "API_ROUTE_CREATED",
        "API_IMPLEMENTATION_CHANGED", "DB_MUTATION", "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED", "MIGRATION_APPLY_EXECUTED", "EVENT_PUBLISHED",
        "EVENT_CONSUMED", "NOTIFICATION_SENT", "CUSTOMER_PRIVATE_DATA_PRINTED",
        "RAW_DSN_PRINTED", "SECRET_VALUE_PRINTED", "TOKEN_PRINTED",
    ],
    "16.5": [
        "SERVICE_RESTARTED", "CONTAINER_RESTARTED", "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED", "FIREWALL_CHANGED", "PORT_CHANGED",
        "CONFIG_CHANGED", "ENV_CHANGED", "ROLLOUT_EXECUTED", "GO_LIVE_SWITCHED",
        "PRODUCTION_TRAFFIC_CHANGED", "TENANT_ENABLED_FOR_LIVE", "REAL_CUSTOMER_NOTIFIED",
        "UAT_EXECUTED", "SAMPLE_DATA_INSERTED", "REAL_CUSTOMER_DATA_CREATED",
        "REAL_PRODUCT_CREATED", "REAL_STOCK_MUTATED", "REAL_SALE_CREATED",
        "REAL_ACCOUNTING_ENTRY_CREATED", "DATA_IMPORT_EXECUTED", "FILE_EXPORT_EXECUTED",
        "UI_CODE_CHANGED", "API_ROUTE_CREATED", "API_IMPLEMENTATION_CHANGED",
        "DB_MUTATION", "DB_APPLY_EXECUTED", "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED", "EVENT_PUBLISHED", "EVENT_CONSUMED",
        "NOTIFICATION_SENT", "CUSTOMER_PRIVATE_DATA_PRINTED", "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED", "TOKEN_PRINTED",
    ],
}

metric_keys = {
    "16.1": [
        "PILOT_SCOPE_COUNT",
        "PILOT_CRITICAL_SCOPE_COUNT",
        "PILOT_UAT_SCENARIO_COUNT",
        "PILOT_UAT_P0_SCENARIO_COUNT",
        "PILOT_ONBOARDING_CHECKLIST_COUNT",
        "PILOT_ROLLOUT_GATE_COUNT",
    ],
    "16.2": [
        "PILOT_TENANT_READINESS_ITEM_COUNT",
        "PILOT_TENANT_CRITICAL_READINESS_COUNT",
        "PILOT_ROLE_COUNT",
        "PILOT_AUDIT_ROLE_COUNT",
        "PILOT_ONBOARDING_ROLE_COUNT",
        "PILOT_ONBOARDING_OWNER_COUNT",
        "PILOT_EVIDENCE_COUNT",
        "PILOT_TRAINING_PLAN_COUNT",
    ],
    "16.3": [
        "UAT_SCENARIO_COUNT",
        "UAT_P0_SCENARIO_COUNT",
        "UAT_P1_SCENARIO_COUNT",
        "UAT_AUDIT_REQUIRED_COUNT",
        "UAT_TENANT_CHECK_COUNT",
        "UAT_RBAC_CHECK_COUNT",
        "UAT_EVIDENCE_COUNT",
        "UAT_NO_GO_POLICY_COUNT",
    ],
    "16.4": [
        "PILOT_DATA_PRODUCT_SAMPLE_COUNT",
        "PILOT_DATA_STOCK_SAMPLE_COUNT",
        "PILOT_DATA_PARTY_SAMPLE_COUNT",
        "PILOT_DATA_SALES_ACCOUNTING_SAMPLE_COUNT",
        "PILOT_DATA_QUALITY_GATE_COUNT",
        "PILOT_DATA_TDHP_FLOW_COUNT",
        "PILOT_DATA_SYNTHETIC_PARTY_COUNT",
    ],
    "16.5": [
        "GO_NO_GO_DECISION_GATE_COUNT",
        "GO_NO_GO_DECISION_P0_COUNT",
        "GO_NO_GO_BLOCKER_POLICY_COUNT",
        "GO_NO_GO_NO_GO_BLOCKER_COUNT",
        "GO_NO_GO_SECURITY_GATE_COUNT",
        "GO_NO_GO_BUSINESS_GATE_COUNT",
        "GO_NO_GO_SUPPORT_GATE_COUNT",
    ],
}

artifact_sets = {
    "16.1": [
        "docs/phase4/16_1_pilot_uat_onboarding_baseline_standard.md",
        "docs/phase4/16_1_pilot_uat_onboarding_baseline_policy.md",
        "docs/phase4/16_1_pilot_scope_inventory.tsv",
        "docs/phase4/16_1_uat_scenario_catalog.tsv",
        "docs/phase4/16_1_onboarding_checklist.tsv",
        "docs/phase4/16_1_rollout_gate_matrix.tsv",
        "docs/phase4/16_1_pilot_uat_onboarding_baseline_matrix.tsv",
        "docs/phase4/16_1_pilot_uat_onboarding_baseline_report.md",
        "scripts/phase4b_pilot_uat_onboarding_baseline.sh",
        "scripts/phase4b_pilot_uat_onboarding_baseline.py",
        "scripts/test_phase4b_pilot_uat_onboarding_baseline.sh",
    ],
    "16.2": [
        "docs/phase4/16_2_pilot_tenant_readiness_contract_standard.md",
        "docs/phase4/16_2_pilot_tenant_readiness_contract_policy.md",
        "docs/phase4/16_2_pilot_tenant_readiness_catalog.tsv",
        "docs/phase4/16_2_pilot_role_permission_matrix.tsv",
        "docs/phase4/16_2_pilot_onboarding_owner_matrix.tsv",
        "docs/phase4/16_2_pilot_evidence_acceptance_matrix.tsv",
        "docs/phase4/16_2_pilot_training_support_plan.tsv",
        "docs/phase4/16_2_pilot_tenant_readiness_contract_matrix.tsv",
        "docs/phase4/16_2_pilot_tenant_readiness_contract_report.md",
        "scripts/phase4b_pilot_tenant_readiness_contract.sh",
        "scripts/phase4b_pilot_tenant_readiness_contract.py",
        "scripts/test_phase4b_pilot_tenant_readiness_contract.sh",
    ],
    "16.3": [
        "docs/phase4/16_3_uat_scenario_execution_contract_standard.md",
        "docs/phase4/16_3_uat_scenario_execution_contract_policy.md",
        "docs/phase4/16_3_uat_execution_plan.tsv",
        "docs/phase4/16_3_uat_actor_matrix.tsv",
        "docs/phase4/16_3_uat_evidence_matrix.tsv",
        "docs/phase4/16_3_uat_blocker_policy.tsv",
        "docs/phase4/16_3_uat_execution_contract_matrix.tsv",
        "docs/phase4/16_3_uat_scenario_execution_contract_report.md",
        "scripts/phase4b_uat_scenario_execution_contract.sh",
        "scripts/phase4b_uat_scenario_execution_contract.py",
        "scripts/test_phase4b_uat_scenario_execution_contract.sh",
    ],
    "16.4": [
        "docs/phase4/16_4_pilot_data_readiness_contract_standard.md",
        "docs/phase4/16_4_pilot_data_readiness_contract_policy.md",
        "docs/phase4/16_4_pilot_sample_product_dataset.tsv",
        "docs/phase4/16_4_pilot_sample_stock_dataset.tsv",
        "docs/phase4/16_4_pilot_sample_party_dataset.tsv",
        "docs/phase4/16_4_pilot_sample_sales_accounting_dataset.tsv",
        "docs/phase4/16_4_pilot_data_quality_gate_matrix.tsv",
        "docs/phase4/16_4_pilot_data_readiness_contract_matrix.tsv",
        "docs/phase4/16_4_pilot_data_readiness_contract_report.md",
        "scripts/phase4b_pilot_data_readiness_contract.sh",
        "scripts/phase4b_pilot_data_readiness_contract.py",
        "scripts/test_phase4b_pilot_data_readiness_contract.sh",
    ],
    "16.5": [
        "docs/phase4/16_5_go_no_go_rollout_gate_standard.md",
        "docs/phase4/16_5_go_no_go_rollout_gate_policy.md",
        "docs/phase4/16_5_go_no_go_decision_matrix.tsv",
        "docs/phase4/16_5_rollout_blocker_policy.tsv",
        "docs/phase4/16_5_security_tenant_gate.tsv",
        "docs/phase4/16_5_business_chain_gate.tsv",
        "docs/phase4/16_5_support_incident_gate.tsv",
        "docs/phase4/16_5_go_no_go_rollout_gate_matrix.tsv",
        "docs/phase4/16_5_go_no_go_rollout_gate_report.md",
        "scripts/phase4b_go_no_go_rollout_gate.sh",
        "scripts/phase4b_go_no_go_rollout_gate.py",
        "scripts/test_phase4b_go_no_go_rollout_gate.sh",
    ],
}

failures = []
warnings = []
details = []
tools = []

def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")

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

def fail(msg):
    failures.append(f"FAIL ❌ {msg}")

def detail(line):
    details.append(line)

def tool_status(name):
    status = "FOUND" if which(name) else "NOT_FOUND"
    tools.append(f"TOOL_{name}={status}")

def as_int(value):
    try:
        return int(str(value).strip())
    except Exception:
        return 0

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("SERVICE_RESTARTED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("DOCKER_COMPOSE_EXECUTED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
detail("FIREWALL_CHANGED=NO")
detail("PORT_CHANGED=NO")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("ROLLOUT_EXECUTED=NO")
detail("GO_LIVE_SWITCHED=NO")
detail("PRODUCTION_TRAFFIC_CHANGED=NO")
detail("TENANT_ENABLED_FOR_LIVE=NO")
detail("REAL_CUSTOMER_NOTIFIED=NO")
detail("TENANT_CREATED=NO")
detail("USER_CREATED=NO")
detail("PASSWORD_CREATED=NO")
detail("TOKEN_CREATED=NO")
detail("UAT_EXECUTED=NO")
detail("SAMPLE_DATA_INSERTED=NO")
detail("REAL_CUSTOMER_DATA_CREATED=NO")
detail("REAL_PRODUCT_CREATED=NO")
detail("REAL_STOCK_MUTATED=NO")
detail("REAL_SALE_CREATED=NO")
detail("REAL_ACCOUNTING_ENTRY_CREATED=NO")
detail("DATA_IMPORT_EXECUTED=NO")
detail("FILE_EXPORT_EXECUTED=NO")
detail("UI_CODE_CHANGED=NO")
detail("API_ROUTE_CREATED=NO")
detail("API_IMPLEMENTATION_CHANGED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("EVENT_PUBLISHED=NO")
detail("EVENT_CONSUMED=NO")
detail("NOTIFICATION_SENT=NO")
detail("CUSTOMER_PRIVATE_DATA_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("TOKEN_PRINTED=NO")
detail("VALIDATION_MODE=PILOT_UAT_ONBOARDING_TESTS_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

if not standard_file.exists():
    fail("16.6 standard doc yok")

prev_17_status = get_value(reports["17"], "FAZ4B_17_FINAL_STATUS")
prev_20_status = get_value(reports["20"], "FAZ4B_20_FINAL_STATUS")
prev_21_status = get_value(reports["21"], "FAZ4B_21_FINAL_STATUS")
prev_22_status = get_value(reports["22"], "FAZ4B_22_FINAL_STATUS")

detail(f"PREVIOUS_17_FINAL_STATUS={prev_17_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")

if prev_17_status != "PASS":
    fail("17 final status PASS degil")
if prev_20_status != "PASS":
    fail("20 final status PASS degil")
if prev_21_status != "PASS":
    fail("21 final status PASS degil")
if prev_22_status != "PASS":
    fail("22 final status PASS degil")

block_results = {}
artifact_missing = []
gate_failures = []
no_change_failures = []
metric_missing = []
metric_total = 0

for block in ["16.1", "16.2", "16.3", "16.4", "16.5"]:
    report = reports[block]
    final_status = get_value(report, final_keys[block])
    domain_status = get_value(report, domain_keys[block])

    detail(f"PILOT_TEST_{block.replace('.', '_')}_FINAL_STATUS={final_status}")
    detail(f"PILOT_TEST_{block.replace('.', '_')}_{domain_keys[block]}={domain_status}")

    local_failures = []

    if final_status != "PASS":
        local_failures.append(f"{final_keys[block]}={final_status}")
    if domain_status != "PASS":
        local_failures.append(f"{domain_keys[block]}={domain_status}")

    for key in required_pass_keys[block]:
        value = get_value(report, key)
        detail(f"PILOT_TEST_{block.replace('.', '_')}_{key}={value}")
        if value != "PASS":
            local_failures.append(f"{key}={value}")

    for key in required_no_keys[block]:
        value = get_value(report, key)
        detail(f"PILOT_TEST_{block.replace('.', '_')}_{key}={value}")
        if value != "NO":
            no_change_failures.append(f"{block}:{key}={value}")

    metric_hit_count = 0
    metric_sum = 0
    for key in metric_keys[block]:
        value = get_value(report, key)
        detail(f"PILOT_TEST_{block.replace('.', '_')}_{key}={value}")
        if value != "":
            metric_hit_count += 1
            metric_sum += as_int(value)

    if metric_hit_count != len(metric_keys[block]):
        metric_missing.append(f"{block}:metric_keys={metric_hit_count}/{len(metric_keys[block])}")

    metric_total += metric_sum

    expected_artifact_count = len(artifact_sets[block])
    existing_artifact_count = 0

    for rel in artifact_sets[block]:
        p = root / rel
        if p.exists():
            existing_artifact_count += 1
        else:
            artifact_missing.append(f"{block}:{rel}")

    detail(f"PILOT_TEST_{block.replace('.', '_')}_ARTIFACT_EXPECTED_COUNT={expected_artifact_count}")
    detail(f"PILOT_TEST_{block.replace('.', '_')}_ARTIFACT_EXISTING_COUNT={existing_artifact_count}")

    if local_failures:
        gate_failures.extend([f"{block}:{x}" for x in local_failures])

    block_results[block] = {
        "status": "PASS" if not local_failures else "FAIL",
        "artifact_expected": expected_artifact_count,
        "artifact_existing": existing_artifact_count,
        "metric_hit_count": metric_hit_count,
        "metric_expected": len(metric_keys[block]),
        "metric_sum": metric_sum,
        "gate_failures": len(local_failures),
    }

if gate_failures:
    fail("pilot UAT onboarding gate failure: " + ",".join(gate_failures[:90]))

if no_change_failures:
    fail("pilot UAT onboarding no-change failure: " + ",".join(no_change_failures[:90]))

if artifact_missing:
    fail("pilot UAT onboarding artifact eksik: " + ",".join(artifact_missing[:90]))

if metric_missing:
    fail("pilot UAT onboarding metric evidence eksik: " + ",".join(metric_missing[:90]))

baseline_status = block_results["16.1"]["status"]
tenant_readiness_status = block_results["16.2"]["status"]
uat_execution_status = block_results["16.3"]["status"]
data_readiness_status = block_results["16.4"]["status"]
go_no_go_status = block_results["16.5"]["status"]

artifact_coverage_status = "PASS" if not artifact_missing else "FAIL"
no_runtime_change_status = "PASS" if not no_change_failures else "FAIL"
no_config_change_status = "PASS" if not no_change_failures else "FAIL"
secret_safe_status = "PASS" if not no_change_failures else "FAIL"

for label, status in [
    ("PILOT_TEST_BASELINE", baseline_status),
    ("PILOT_TEST_TENANT_READINESS", tenant_readiness_status),
    ("PILOT_TEST_UAT_EXECUTION", uat_execution_status),
    ("PILOT_TEST_DATA_READINESS", data_readiness_status),
    ("PILOT_TEST_GO_NO_GO", go_no_go_status),
    ("PILOT_TEST_ARTIFACT_COVERAGE", artifact_coverage_status),
    ("PILOT_TEST_NO_RUNTIME_CHANGE", no_runtime_change_status),
    ("PILOT_TEST_NO_CONFIG_CHANGE", no_config_change_status),
    ("PILOT_TEST_SECRET_SAFE", secret_safe_status),
]:
    detail(f"{label}={status}")
    if status != "PASS":
        fail(f"{label} PASS degil")

detail(f"PILOT_TEST_METRIC_EVIDENCE_TOTAL={metric_total}")
detail(f"PILOT_TEST_GATE_FAILURE_COUNT={len(gate_failures)}")
detail(f"PILOT_TEST_NO_CHANGE_FAILURE_COUNT={len(no_change_failures)}")
detail(f"PILOT_TEST_ARTIFACT_MISSING_COUNT={len(artifact_missing)}")
detail(f"PILOT_TEST_METRIC_MISSING_COUNT={len(metric_missing)}")

matrix_lines = [
    "gate\tstatus\tnote",
    f"baseline\t{baseline_status}\t16.1 pilot baseline",
    f"tenant_readiness\t{tenant_readiness_status}\t16.2 tenant readiness",
    f"uat_execution\t{uat_execution_status}\t16.3 UAT execution contract",
    f"data_readiness\t{data_readiness_status}\t16.4 pilot data readiness",
    f"go_no_go\t{go_no_go_status}\t16.5 go/no-go rollout gate",
    f"artifact_coverage\t{artifact_coverage_status}\tmissing={len(artifact_missing)}",
    f"no_runtime_change\t{no_runtime_change_status}\tfailures={len(no_change_failures)}",
    f"no_config_change\t{no_config_change_status}\tfailures={len(no_change_failures)}",
    f"secret_safe\t{secret_safe_status}\tfailures={len(no_change_failures)}",
    f"metric_evidence\tPASS\ttotal={metric_total} missing={len(metric_missing)}",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "port_changed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "rollout_executed\tNO\ttest only",
    "go_live_switched\tNO\ttest only",
    "production_traffic_changed\tNO\ttest only",
    "tenant_enabled_for_live\tNO\ttest only",
    "real_customer_notified\tNO\ttest only",
    "tenant_created\tNO\ttest only",
    "user_created\tNO\ttest only",
    "password_created\tNO\ttest only",
    "token_created\tNO\ttest only",
    "uat_executed\tNO\ttest only",
    "sample_data_inserted\tNO\ttest only",
    "real_customer_data_created\tNO\ttest only",
    "real_product_created\tNO\ttest only",
    "real_stock_mutated\tNO\ttest only",
    "real_sale_created\tNO\ttest only",
    "real_accounting_entry_created\tNO\ttest only",
    "data_import_executed\tNO\ttest only",
    "file_export_executed\tNO\ttest only",
    "ui_code_changed\tNO\ttest only",
    "api_route_created\tNO\ttest only",
    "api_implementation_changed\tNO\ttest only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "event_published\tNO\ttest only",
    "event_consumed\tNO\ttest only",
    "notification_sent\tNO\ttest only",
    "customer_private_data_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
    "token_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = [
    "block\tstatus\tdomain_key\treport_file\tartifact_expected\tartifact_existing\tmetric_hit_count\tmetric_expected\tmetric_sum\tgate_failures"
]

for block in ["16.1", "16.2", "16.3", "16.4", "16.5"]:
    result = block_results[block]
    inventory_lines.append(
        f"{block}\t{result['status']}\t{domain_keys[block]}\t{str(reports[block].relative_to(root))}\t{result['artifact_expected']}\t{result['artifact_existing']}\t{result['metric_hit_count']}\t{result['metric_expected']}\t{result['metric_sum']}\t{result['gate_failures']}"
    )

inventory_file.write_text("\n".join(inventory_lines) + "\n")

detail(f"PILOT_TEST_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"PILOT_TEST_INVENTORY_LINE_COUNT={len(inventory_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"PILOT_UAT_ONBOARDING_TESTS={final_status}")
detail(f"FAZ4B_16_6_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 16.6 - Pilot / UAT / Onboarding Tests Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"PILOT_UAT_ONBOARDING_TESTS={final_status}",
    f"FAZ4B_16_6_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/16_6_pilot_uat_onboarding_tests_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/16_6_pilot_uat_onboarding_tests_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Safety Decision",
    "SERVICE_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "FIREWALL_CHANGED=NO",
    "PORT_CHANGED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "ROLLOUT_EXECUTED=NO",
    "GO_LIVE_SWITCHED=NO",
    "PRODUCTION_TRAFFIC_CHANGED=NO",
    "TENANT_ENABLED_FOR_LIVE=NO",
    "REAL_CUSTOMER_NOTIFIED=NO",
    "TENANT_CREATED=NO",
    "USER_CREATED=NO",
    "PASSWORD_CREATED=NO",
    "TOKEN_CREATED=NO",
    "UAT_EXECUTED=NO",
    "SAMPLE_DATA_INSERTED=NO",
    "REAL_CUSTOMER_DATA_CREATED=NO",
    "REAL_PRODUCT_CREATED=NO",
    "REAL_STOCK_MUTATED=NO",
    "REAL_SALE_CREATED=NO",
    "REAL_ACCOUNTING_ENTRY_CREATED=NO",
    "DATA_IMPORT_EXECUTED=NO",
    "FILE_EXPORT_EXECUTED=NO",
    "UI_CODE_CHANGED=NO",
    "API_ROUTE_CREATED=NO",
    "API_IMPLEMENTATION_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "EVENT_PUBLISHED=NO",
    "EVENT_CONSUMED=NO",
    "NOTIFICATION_SENT=NO",
    "CUSTOMER_PRIVATE_DATA_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
    "TOKEN_PRINTED=NO",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"PILOT_TEST_BASELINE={baseline_status}")
print(f"PILOT_TEST_TENANT_READINESS={tenant_readiness_status}")
print(f"PILOT_TEST_UAT_EXECUTION={uat_execution_status}")
print(f"PILOT_TEST_DATA_READINESS={data_readiness_status}")
print(f"PILOT_TEST_GO_NO_GO={go_no_go_status}")
print(f"PILOT_TEST_ARTIFACT_COVERAGE={artifact_coverage_status}")
print(f"PILOT_TEST_NO_RUNTIME_CHANGE={no_runtime_change_status}")
print(f"PILOT_TEST_NO_CONFIG_CHANGE={no_config_change_status}")
print(f"PILOT_TEST_SECRET_SAFE={secret_safe_status}")
print(f"PILOT_TEST_METRIC_EVIDENCE_TOTAL={metric_total}")
print(f"PILOT_TEST_GATE_FAILURE_COUNT={len(gate_failures)}")
print(f"PILOT_TEST_NO_CHANGE_FAILURE_COUNT={len(no_change_failures)}")
print(f"PILOT_TEST_ARTIFACT_MISSING_COUNT={len(artifact_missing)}")
print(f"PILOT_TEST_METRIC_MISSING_COUNT={len(metric_missing)}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("ROLLOUT_EXECUTED=NO")
print("GO_LIVE_SWITCHED=NO")
print("PRODUCTION_TRAFFIC_CHANGED=NO")
print("TENANT_ENABLED_FOR_LIVE=NO")
print("REAL_CUSTOMER_NOTIFIED=NO")
print("TENANT_CREATED=NO")
print("USER_CREATED=NO")
print("PASSWORD_CREATED=NO")
print("TOKEN_CREATED=NO")
print("UAT_EXECUTED=NO")
print("SAMPLE_DATA_INSERTED=NO")
print("REAL_CUSTOMER_DATA_CREATED=NO")
print("REAL_PRODUCT_CREATED=NO")
print("REAL_STOCK_MUTATED=NO")
print("REAL_SALE_CREATED=NO")
print("REAL_ACCOUNTING_ENTRY_CREATED=NO")
print("DATA_IMPORT_EXECUTED=NO")
print("FILE_EXPORT_EXECUTED=NO")
print("UI_CODE_CHANGED=NO")
print("API_ROUTE_CREATED=NO")
print("API_IMPLEMENTATION_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("EVENT_PUBLISHED=NO")
print("EVENT_CONSUMED=NO")
print("NOTIFICATION_SENT=NO")
print("CUSTOMER_PRIVATE_DATA_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print("TOKEN_PRINTED=NO")
print(f"PILOT_UAT_ONBOARDING_TESTS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_16_6_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
