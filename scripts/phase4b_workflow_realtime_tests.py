#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "17_6_workflow_realtime_tests_standard.md"
report_file = report_dir / "17_6_workflow_realtime_tests_report.md"
matrix_file = report_dir / "17_6_workflow_realtime_tests_matrix.tsv"
inventory_file = report_dir / "17_6_workflow_realtime_tests_inventory.tsv"

reports = {
    "17.1": report_dir / "17_1_workflow_realtime_baseline_report.md",
    "17.2": report_dir / "17_2_workflow_state_machine_contract_report.md",
    "17.3": report_dir / "17_3_workflow_action_approval_contract_report.md",
    "17.4": report_dir / "17_4_realtime_channel_contract_report.md",
    "17.5": report_dir / "17_5_ui_api_implementation_plan_report.md",
    "22": report_dir / "22_observability_ops_console_final_closure_report.md",
    "20": report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md",
    "21": report_dir / "21_security_rbac_audit_final_closure_report.md",
}

final_keys = {
    "17.1": "FAZ4B_17_1_FINAL_STATUS",
    "17.2": "FAZ4B_17_2_FINAL_STATUS",
    "17.3": "FAZ4B_17_3_FINAL_STATUS",
    "17.4": "FAZ4B_17_4_FINAL_STATUS",
    "17.5": "FAZ4B_17_5_FINAL_STATUS",
}

domain_keys = {
    "17.1": "WORKFLOW_REALTIME_BASELINE",
    "17.2": "WORKFLOW_STATE_MACHINE_CONTRACT",
    "17.3": "WORKFLOW_ACTION_APPROVAL_CONTRACT",
    "17.4": "REALTIME_CHANNEL_CONTRACT",
    "17.5": "UI_API_IMPLEMENTATION_PLAN",
}

required_pass_keys = {
    "17.1": [
        "WORKFLOW_PREVIOUS_22",
        "WORKFLOW_DOMAIN_INVENTORY",
        "WORKFLOW_REALTIME_SIGNAL_CONTRACT",
        "WORKFLOW_UI_SURFACE_CONTRACT",
        "WORKFLOW_API_SURFACE_CANDIDATES",
        "WORKFLOW_NO_RUNTIME_CHANGE",
        "WORKFLOW_NO_CONFIG_CHANGE",
        "WORKFLOW_SECRET_SAFE",
    ],
    "17.2": [
        "WORKFLOW_STATE_PREVIOUS_17_1",
        "WORKFLOW_STATE_CATALOG",
        "WORKFLOW_TRANSITION_CATALOG",
        "WORKFLOW_STATE_PERMISSION_MATRIX",
        "WORKFLOW_STATE_INVARIANT_CATALOG",
        "WORKFLOW_STATE_NO_RUNTIME_CHANGE",
        "WORKFLOW_STATE_NO_CONFIG_CHANGE",
        "WORKFLOW_STATE_SECRET_SAFE",
    ],
    "17.3": [
        "WORKFLOW_ACTION_PREVIOUS_17_2",
        "WORKFLOW_ACTION_CATALOG",
        "WORKFLOW_APPROVAL_RULE_CATALOG",
        "WORKFLOW_ACTION_PERMISSION_MATRIX",
        "WORKFLOW_ACTION_AUDIT_REALTIME_BINDING",
        "WORKFLOW_ACTION_NO_RUNTIME_CHANGE",
        "WORKFLOW_ACTION_NO_CONFIG_CHANGE",
        "WORKFLOW_ACTION_SECRET_SAFE",
    ],
    "17.4": [
        "REALTIME_PREVIOUS_17_3",
        "REALTIME_CHANNEL_CATALOG",
        "REALTIME_PAYLOAD_ENVELOPE",
        "REALTIME_DELIVERY_POLICY",
        "REALTIME_RBAC_TENANT_MATRIX",
        "REALTIME_RECONNECT_HEARTBEAT_POLICY",
        "REALTIME_NO_RUNTIME_CHANGE",
        "REALTIME_NO_CONFIG_CHANGE",
        "REALTIME_SECRET_SAFE",
    ],
    "17.5": [
        "UI_API_PREVIOUS_17_4",
        "UI_PAGE_IMPLEMENTATION_PLAN",
        "API_ENDPOINT_IMPLEMENTATION_PLAN",
        "UI_API_PERMISSION_MAPPING",
        "UI_API_SEQUENCE_PLAN",
        "UI_API_TEST_PLAN",
        "UI_API_NO_RUNTIME_CHANGE",
        "UI_API_NO_CONFIG_CHANGE",
        "UI_API_SECRET_SAFE",
    ],
}

required_no_keys = {
    "17.1": [
        "SERVICE_RESTARTED",
        "CONTAINER_RESTARTED",
        "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED",
        "FIREWALL_CHANGED",
        "PORT_CHANGED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "UI_CODE_CHANGED",
        "API_ROUTE_CREATED",
        "API_IMPLEMENTATION_CHANGED",
        "WEBSOCKET_SERVER_STARTED",
        "SSE_SERVER_STARTED",
        "WORKFLOW_RUNTIME_CHANGED",
        "EVENT_PUBLISHED",
        "EVENT_CONSUMED",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
        "TOKEN_PRINTED",
    ],
    "17.2": [
        "SERVICE_RESTARTED",
        "CONTAINER_RESTARTED",
        "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED",
        "FIREWALL_CHANGED",
        "PORT_CHANGED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "UI_CODE_CHANGED",
        "API_ROUTE_CREATED",
        "API_IMPLEMENTATION_CHANGED",
        "WEBSOCKET_SERVER_STARTED",
        "SSE_SERVER_STARTED",
        "WORKFLOW_RUNTIME_CHANGED",
        "WORKFLOW_ENGINE_CODE_CHANGED",
        "STATE_MACHINE_RUNTIME_CREATED",
        "EVENT_PUBLISHED",
        "EVENT_CONSUMED",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
        "TOKEN_PRINTED",
    ],
    "17.3": [
        "SERVICE_RESTARTED",
        "CONTAINER_RESTARTED",
        "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED",
        "FIREWALL_CHANGED",
        "PORT_CHANGED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "UI_CODE_CHANGED",
        "API_ROUTE_CREATED",
        "API_IMPLEMENTATION_CHANGED",
        "WEBSOCKET_SERVER_STARTED",
        "SSE_SERVER_STARTED",
        "WORKFLOW_RUNTIME_CHANGED",
        "WORKFLOW_ENGINE_CODE_CHANGED",
        "APPROVAL_RUNTIME_CHANGED",
        "ACTION_RUNTIME_CREATED",
        "EVENT_PUBLISHED",
        "EVENT_CONSUMED",
        "NOTIFICATION_SENT",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
        "TOKEN_PRINTED",
    ],
    "17.4": [
        "SERVICE_RESTARTED",
        "CONTAINER_RESTARTED",
        "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED",
        "FIREWALL_CHANGED",
        "PORT_CHANGED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "UI_CODE_CHANGED",
        "API_ROUTE_CREATED",
        "API_IMPLEMENTATION_CHANGED",
        "WEBSOCKET_SERVER_STARTED",
        "SSE_SERVER_STARTED",
        "REALTIME_RUNTIME_CHANGED",
        "REALTIME_SERVER_STARTED",
        "WORKFLOW_RUNTIME_CHANGED",
        "APPROVAL_RUNTIME_CHANGED",
        "EVENT_PUBLISHED",
        "EVENT_CONSUMED",
        "NOTIFICATION_SENT",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "RAW_PAYLOAD_PRINTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
        "TOKEN_PRINTED",
    ],
    "17.5": [
        "SERVICE_RESTARTED",
        "CONTAINER_RESTARTED",
        "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED",
        "FIREWALL_CHANGED",
        "PORT_CHANGED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "UI_CODE_CHANGED",
        "FRONTEND_FILE_CREATED",
        "API_ROUTE_CREATED",
        "API_IMPLEMENTATION_CHANGED",
        "DTO_CODE_CREATED",
        "HANDLER_CODE_CREATED",
        "MIDDLEWARE_CHANGED",
        "WEBSOCKET_SERVER_STARTED",
        "SSE_SERVER_STARTED",
        "REALTIME_RUNTIME_CHANGED",
        "WORKFLOW_RUNTIME_CHANGED",
        "APPROVAL_RUNTIME_CHANGED",
        "EVENT_PUBLISHED",
        "EVENT_CONSUMED",
        "NOTIFICATION_SENT",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "RAW_PAYLOAD_PRINTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
        "TOKEN_PRINTED",
    ],
}

metric_keys = {
    "17.1": [
        "WORKFLOW_DOMAIN_COUNT",
        "WORKFLOW_REALTIME_SIGNAL_COUNT",
        "WORKFLOW_UI_SURFACE_COUNT",
        "WORKFLOW_API_CANDIDATE_COUNT",
        "WORKFLOW_AUDIT_REQUIRED_UI_COUNT",
    ],
    "17.2": [
        "WORKFLOW_STATE_COUNT",
        "WORKFLOW_TRANSITION_COUNT",
        "WORKFLOW_PERMISSION_COUNT",
        "WORKFLOW_INVARIANT_COUNT",
        "WORKFLOW_AUDIT_TRANSITION_COUNT",
        "WORKFLOW_EVENT_BINDING_COUNT",
        "WORKFLOW_TENANT_SCOPED_STATE_COUNT",
    ],
    "17.3": [
        "WORKFLOW_ACTION_COUNT",
        "WORKFLOW_APPROVAL_ACTION_COUNT",
        "WORKFLOW_IDEMPOTENCY_REQUIRED_ACTION_COUNT",
        "WORKFLOW_AUDIT_ACTION_COUNT",
        "WORKFLOW_EVENT_BINDING_COUNT",
        "WORKFLOW_TENANT_SCOPED_ACTION_COUNT",
        "WORKFLOW_APPROVAL_RULE_COUNT",
    ],
    "17.4": [
        "REALTIME_CHANNEL_COUNT",
        "REALTIME_TENANT_CHANNEL_COUNT",
        "REALTIME_PLATFORM_CHANNEL_COUNT",
        "REALTIME_SSE_CHANNEL_COUNT",
        "REALTIME_WEBSOCKET_CHANNEL_COUNT",
        "REALTIME_AUTH_REQUIRED_COUNT",
        "REALTIME_AUDIT_REQUIRED_COUNT",
        "REALTIME_METADATA_ONLY_CHANNEL_COUNT",
        "REALTIME_PAYLOAD_FIELD_COUNT",
    ],
    "17.5": [
        "UI_API_UI_PAGE_COUNT",
        "UI_API_ENDPOINT_COUNT",
        "UI_API_PERMISSION_COUNT",
        "UI_API_SEQUENCE_COUNT",
        "UI_API_TEST_COUNT",
        "UI_API_TENANT_TEST_COUNT",
        "UI_API_RBAC_TEST_COUNT",
        "UI_API_REALTIME_TEST_COUNT",
    ],
}

artifact_sets = {
    "17.1": [
        "docs/phase4/17_1_workflow_realtime_baseline_standard.md",
        "docs/phase4/17_1_workflow_realtime_baseline_policy.md",
        "docs/phase4/17_1_workflow_domain_inventory.tsv",
        "docs/phase4/17_1_realtime_signal_contract.tsv",
        "docs/phase4/17_1_ui_surface_contract.tsv",
        "docs/phase4/17_1_api_surface_candidate_inventory.tsv",
        "docs/phase4/17_1_workflow_realtime_baseline_matrix.tsv",
        "docs/phase4/17_1_workflow_realtime_baseline_report.md",
        "scripts/phase4b_workflow_realtime_baseline.sh",
        "scripts/phase4b_workflow_realtime_baseline.py",
        "scripts/test_phase4b_workflow_realtime_baseline.sh",
    ],
    "17.2": [
        "docs/phase4/17_2_workflow_state_machine_contract_standard.md",
        "docs/phase4/17_2_workflow_state_machine_contract_policy.md",
        "docs/phase4/17_2_workflow_state_catalog.tsv",
        "docs/phase4/17_2_workflow_transition_catalog.tsv",
        "docs/phase4/17_2_workflow_state_permission_matrix.tsv",
        "docs/phase4/17_2_workflow_state_invariant_catalog.tsv",
        "docs/phase4/17_2_workflow_state_machine_contract_matrix.tsv",
        "docs/phase4/17_2_workflow_state_machine_contract_report.md",
        "scripts/phase4b_workflow_state_machine_contract.sh",
        "scripts/phase4b_workflow_state_machine_contract.py",
        "scripts/test_phase4b_workflow_state_machine_contract.sh",
    ],
    "17.3": [
        "docs/phase4/17_3_workflow_action_approval_contract_standard.md",
        "docs/phase4/17_3_workflow_action_approval_contract_policy.md",
        "docs/phase4/17_3_workflow_action_catalog.tsv",
        "docs/phase4/17_3_workflow_approval_rule_catalog.tsv",
        "docs/phase4/17_3_workflow_action_permission_matrix.tsv",
        "docs/phase4/17_3_workflow_action_audit_realtime_binding.tsv",
        "docs/phase4/17_3_workflow_action_approval_contract_matrix.tsv",
        "docs/phase4/17_3_workflow_action_approval_contract_report.md",
        "scripts/phase4b_workflow_action_approval_contract.sh",
        "scripts/phase4b_workflow_action_approval_contract.py",
        "scripts/test_phase4b_workflow_action_approval_contract.sh",
    ],
    "17.4": [
        "docs/phase4/17_4_realtime_channel_contract_standard.md",
        "docs/phase4/17_4_realtime_channel_contract_policy.md",
        "docs/phase4/17_4_realtime_channel_catalog.tsv",
        "docs/phase4/17_4_realtime_payload_envelope.tsv",
        "docs/phase4/17_4_realtime_delivery_policy.tsv",
        "docs/phase4/17_4_realtime_rbac_tenant_matrix.tsv",
        "docs/phase4/17_4_realtime_reconnect_heartbeat_policy.tsv",
        "docs/phase4/17_4_realtime_channel_contract_matrix.tsv",
        "docs/phase4/17_4_realtime_channel_contract_report.md",
        "scripts/phase4b_realtime_channel_contract.sh",
        "scripts/phase4b_realtime_channel_contract.py",
        "scripts/test_phase4b_realtime_channel_contract.sh",
    ],
    "17.5": [
        "docs/phase4/17_5_ui_api_implementation_plan_standard.md",
        "docs/phase4/17_5_ui_api_implementation_plan_policy.md",
        "docs/phase4/17_5_ui_page_implementation_plan.tsv",
        "docs/phase4/17_5_api_endpoint_implementation_plan.tsv",
        "docs/phase4/17_5_ui_api_permission_mapping.tsv",
        "docs/phase4/17_5_implementation_sequence.tsv",
        "docs/phase4/17_5_ui_api_test_plan.tsv",
        "docs/phase4/17_5_ui_api_implementation_plan_matrix.tsv",
        "docs/phase4/17_5_ui_api_implementation_plan_report.md",
        "scripts/phase4b_ui_api_implementation_plan.sh",
        "scripts/phase4b_ui_api_implementation_plan.py",
        "scripts/test_phase4b_ui_api_implementation_plan.sh",
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
detail("UI_CODE_CHANGED=NO")
detail("FRONTEND_FILE_CREATED=NO")
detail("API_ROUTE_CREATED=NO")
detail("API_IMPLEMENTATION_CHANGED=NO")
detail("DTO_CODE_CREATED=NO")
detail("HANDLER_CODE_CREATED=NO")
detail("MIDDLEWARE_CHANGED=NO")
detail("WEBSOCKET_SERVER_STARTED=NO")
detail("SSE_SERVER_STARTED=NO")
detail("REALTIME_RUNTIME_CHANGED=NO")
detail("REALTIME_SERVER_STARTED=NO")
detail("WORKFLOW_RUNTIME_CHANGED=NO")
detail("WORKFLOW_ENGINE_CODE_CHANGED=NO")
detail("APPROVAL_RUNTIME_CHANGED=NO")
detail("ACTION_RUNTIME_CREATED=NO")
detail("STATE_MACHINE_RUNTIME_CREATED=NO")
detail("EVENT_PUBLISHED=NO")
detail("EVENT_CONSUMED=NO")
detail("NOTIFICATION_SENT=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("RAW_PAYLOAD_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("TOKEN_PRINTED=NO")
detail("VALIDATION_MODE=WORKFLOW_REALTIME_TESTS_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

if not standard_file.exists():
    fail("17.6 standard doc yok")

prev_22_status = get_value(reports["22"], "FAZ4B_22_FINAL_STATUS")
prev_22_closure = get_value(reports["22"], "OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE")
prev_20_status = get_value(reports["20"], "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(reports["20"], "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(reports["21"], "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(reports["21"], "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")
detail(f"PREVIOUS_22_OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE={prev_22_closure}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_22_status != "PASS":
    fail("22 final status PASS degil")
if prev_22_closure != "PASS":
    fail("22 observability closure PASS degil")
if prev_20_status != "PASS":
    fail("20 final status PASS degil")
if prev_20_closure != "PASS":
    fail("20 infra closure PASS degil")
if prev_21_status != "PASS":
    fail("21 final status PASS degil")
if prev_21_closure != "PASS":
    fail("21 security closure PASS degil")

block_results = {}
artifact_missing = []
gate_failures = []
no_change_failures = []
metric_missing = []
metric_total = 0

for block in ["17.1", "17.2", "17.3", "17.4", "17.5"]:
    report = reports[block]
    final_status = get_value(report, final_keys[block])
    domain_status = get_value(report, domain_keys[block])

    detail(f"WORKFLOW_TEST_{block.replace('.', '_')}_FINAL_STATUS={final_status}")
    detail(f"WORKFLOW_TEST_{block.replace('.', '_')}_{domain_keys[block]}={domain_status}")

    local_failures = []

    if final_status != "PASS":
        local_failures.append(f"{final_keys[block]}={final_status}")
    if domain_status != "PASS":
        local_failures.append(f"{domain_keys[block]}={domain_status}")

    for key in required_pass_keys[block]:
        value = get_value(report, key)
        detail(f"WORKFLOW_TEST_{block.replace('.', '_')}_{key}={value}")
        if value != "PASS":
            local_failures.append(f"{key}={value}")

    for key in required_no_keys[block]:
        value = get_value(report, key)
        detail(f"WORKFLOW_TEST_{block.replace('.', '_')}_{key}={value}")
        if value != "NO":
            no_change_failures.append(f"{block}:{key}={value}")

    metric_hit_count = 0
    metric_sum = 0
    for key in metric_keys[block]:
        value = get_value(report, key)
        detail(f"WORKFLOW_TEST_{block.replace('.', '_')}_{key}={value}")
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

    detail(f"WORKFLOW_TEST_{block.replace('.', '_')}_ARTIFACT_EXPECTED_COUNT={expected_artifact_count}")
    detail(f"WORKFLOW_TEST_{block.replace('.', '_')}_ARTIFACT_EXISTING_COUNT={existing_artifact_count}")

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
    fail("workflow realtime gate failure: " + ",".join(gate_failures[:70]))

if no_change_failures:
    fail("workflow realtime no-change failure: " + ",".join(no_change_failures[:70]))

if artifact_missing:
    fail("workflow realtime artifact eksik: " + ",".join(artifact_missing[:70]))

if metric_missing:
    fail("workflow realtime metric evidence eksik: " + ",".join(metric_missing[:70]))

baseline_status = block_results["17.1"]["status"]
state_machine_status = block_results["17.2"]["status"]
action_approval_status = block_results["17.3"]["status"]
realtime_channel_status = block_results["17.4"]["status"]
ui_api_plan_status = block_results["17.5"]["status"]

artifact_coverage_status = "PASS" if not artifact_missing else "FAIL"
no_runtime_change_status = "PASS" if not no_change_failures else "FAIL"
no_config_change_status = "PASS" if not no_change_failures else "FAIL"
secret_safe_status = "PASS" if not no_change_failures else "FAIL"

for label, status in [
    ("WORKFLOW_TEST_BASELINE", baseline_status),
    ("WORKFLOW_TEST_STATE_MACHINE", state_machine_status),
    ("WORKFLOW_TEST_ACTION_APPROVAL", action_approval_status),
    ("WORKFLOW_TEST_REALTIME_CHANNEL", realtime_channel_status),
    ("WORKFLOW_TEST_UI_API_PLAN", ui_api_plan_status),
    ("WORKFLOW_TEST_ARTIFACT_COVERAGE", artifact_coverage_status),
    ("WORKFLOW_TEST_NO_RUNTIME_CHANGE", no_runtime_change_status),
    ("WORKFLOW_TEST_NO_CONFIG_CHANGE", no_config_change_status),
    ("WORKFLOW_TEST_SECRET_SAFE", secret_safe_status),
]:
    detail(f"{label}={status}")
    if status != "PASS":
        fail(f"{label} PASS degil")

detail(f"WORKFLOW_TEST_METRIC_EVIDENCE_TOTAL={metric_total}")
detail(f"WORKFLOW_TEST_GATE_FAILURE_COUNT={len(gate_failures)}")
detail(f"WORKFLOW_TEST_NO_CHANGE_FAILURE_COUNT={len(no_change_failures)}")
detail(f"WORKFLOW_TEST_ARTIFACT_MISSING_COUNT={len(artifact_missing)}")
detail(f"WORKFLOW_TEST_METRIC_MISSING_COUNT={len(metric_missing)}")

matrix_lines = [
    "gate\tstatus\tnote",
    f"baseline\t{baseline_status}\t17.1 workflow realtime baseline",
    f"state_machine\t{state_machine_status}\t17.2 workflow state machine",
    f"action_approval\t{action_approval_status}\t17.3 workflow action approval",
    f"realtime_channel\t{realtime_channel_status}\t17.4 realtime channel contract",
    f"ui_api_plan\t{ui_api_plan_status}\t17.5 UI/API implementation plan",
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
    "ui_code_changed\tNO\ttest only",
    "frontend_file_created\tNO\ttest only",
    "api_route_created\tNO\ttest only",
    "api_implementation_changed\tNO\ttest only",
    "dto_code_created\tNO\ttest only",
    "handler_code_created\tNO\ttest only",
    "middleware_changed\tNO\ttest only",
    "websocket_server_started\tNO\ttest only",
    "sse_server_started\tNO\ttest only",
    "realtime_runtime_changed\tNO\ttest only",
    "workflow_runtime_changed\tNO\ttest only",
    "approval_runtime_changed\tNO\ttest only",
    "event_published\tNO\ttest only",
    "event_consumed\tNO\ttest only",
    "notification_sent\tNO\ttest only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "raw_payload_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
    "token_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = [
    "block\tstatus\tdomain_key\treport_file\tartifact_expected\tartifact_existing\tmetric_hit_count\tmetric_expected\tmetric_sum\tgate_failures"
]

for block in ["17.1", "17.2", "17.3", "17.4", "17.5"]:
    result = block_results[block]
    inventory_lines.append(
        f"{block}\t{result['status']}\t{domain_keys[block]}\t{str(reports[block].relative_to(root))}\t{result['artifact_expected']}\t{result['artifact_existing']}\t{result['metric_hit_count']}\t{result['metric_expected']}\t{result['metric_sum']}\t{result['gate_failures']}"
    )

inventory_file.write_text("\n".join(inventory_lines) + "\n")

detail(f"WORKFLOW_TEST_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"WORKFLOW_TEST_INVENTORY_LINE_COUNT={len(inventory_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"WORKFLOW_REALTIME_TESTS={final_status}")
detail(f"FAZ4B_17_6_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 17.6 - Workflow / Realtime Tests Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"WORKFLOW_REALTIME_TESTS={final_status}",
    f"FAZ4B_17_6_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/17_6_workflow_realtime_tests_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/17_6_workflow_realtime_tests_inventory.tsv",
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
    "UI_CODE_CHANGED=NO",
    "FRONTEND_FILE_CREATED=NO",
    "API_ROUTE_CREATED=NO",
    "API_IMPLEMENTATION_CHANGED=NO",
    "DTO_CODE_CREATED=NO",
    "HANDLER_CODE_CREATED=NO",
    "MIDDLEWARE_CHANGED=NO",
    "WEBSOCKET_SERVER_STARTED=NO",
    "SSE_SERVER_STARTED=NO",
    "REALTIME_RUNTIME_CHANGED=NO",
    "REALTIME_SERVER_STARTED=NO",
    "WORKFLOW_RUNTIME_CHANGED=NO",
    "WORKFLOW_ENGINE_CODE_CHANGED=NO",
    "APPROVAL_RUNTIME_CHANGED=NO",
    "ACTION_RUNTIME_CREATED=NO",
    "STATE_MACHINE_RUNTIME_CREATED=NO",
    "EVENT_PUBLISHED=NO",
    "EVENT_CONSUMED=NO",
    "NOTIFICATION_SENT=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "RAW_PAYLOAD_PRINTED=NO",
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
print(f"WORKFLOW_TEST_BASELINE={baseline_status}")
print(f"WORKFLOW_TEST_STATE_MACHINE={state_machine_status}")
print(f"WORKFLOW_TEST_ACTION_APPROVAL={action_approval_status}")
print(f"WORKFLOW_TEST_REALTIME_CHANNEL={realtime_channel_status}")
print(f"WORKFLOW_TEST_UI_API_PLAN={ui_api_plan_status}")
print(f"WORKFLOW_TEST_ARTIFACT_COVERAGE={artifact_coverage_status}")
print(f"WORKFLOW_TEST_NO_RUNTIME_CHANGE={no_runtime_change_status}")
print(f"WORKFLOW_TEST_NO_CONFIG_CHANGE={no_config_change_status}")
print(f"WORKFLOW_TEST_SECRET_SAFE={secret_safe_status}")
print(f"WORKFLOW_TEST_METRIC_EVIDENCE_TOTAL={metric_total}")
print(f"WORKFLOW_TEST_GATE_FAILURE_COUNT={len(gate_failures)}")
print(f"WORKFLOW_TEST_NO_CHANGE_FAILURE_COUNT={len(no_change_failures)}")
print(f"WORKFLOW_TEST_ARTIFACT_MISSING_COUNT={len(artifact_missing)}")
print(f"WORKFLOW_TEST_METRIC_MISSING_COUNT={len(metric_missing)}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("UI_CODE_CHANGED=NO")
print("FRONTEND_FILE_CREATED=NO")
print("API_ROUTE_CREATED=NO")
print("API_IMPLEMENTATION_CHANGED=NO")
print("DTO_CODE_CREATED=NO")
print("HANDLER_CODE_CREATED=NO")
print("MIDDLEWARE_CHANGED=NO")
print("WEBSOCKET_SERVER_STARTED=NO")
print("SSE_SERVER_STARTED=NO")
print("REALTIME_RUNTIME_CHANGED=NO")
print("REALTIME_SERVER_STARTED=NO")
print("WORKFLOW_RUNTIME_CHANGED=NO")
print("WORKFLOW_ENGINE_CODE_CHANGED=NO")
print("APPROVAL_RUNTIME_CHANGED=NO")
print("ACTION_RUNTIME_CREATED=NO")
print("STATE_MACHINE_RUNTIME_CREATED=NO")
print("EVENT_PUBLISHED=NO")
print("EVENT_CONSUMED=NO")
print("NOTIFICATION_SENT=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("RAW_PAYLOAD_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print("TOKEN_PRINTED=NO")
print(f"WORKFLOW_REALTIME_TESTS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_17_6_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
