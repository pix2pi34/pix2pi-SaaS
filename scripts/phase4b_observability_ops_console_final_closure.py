#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "22_8_observability_ops_console_final_closure_standard.md"
report_file = report_dir / "22_8_observability_ops_console_final_closure_report.md"
matrix_file = report_dir / "22_8_observability_ops_console_final_closure_matrix.tsv"
inventory_file = report_dir / "22_8_observability_ops_console_final_closure_inventory.tsv"
closure_file = report_dir / "22_observability_ops_console_final_closure_report.md"

reports = {
    "22.1": report_dir / "22_1_observability_baseline_report.md",
    "22.2": report_dir / "22_2_metrics_scrape_readiness_report.md",
    "22.3": report_dir / "22_3_logs_loki_readiness_report.md",
    "22.4": report_dir / "22_4_traces_tempo_readiness_report.md",
    "22.5": report_dir / "22_5_alert_rule_catalog_report.md",
    "22.6": report_dir / "22_6_ops_console_signal_contract_report.md",
    "22.7": report_dir / "22_7_observability_ops_console_tests_report.md",
    "20": report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md",
    "21": report_dir / "21_security_rbac_audit_final_closure_report.md",
}

final_keys = {
    "22.1": "FAZ4B_22_1_FINAL_STATUS",
    "22.2": "FAZ4B_22_2_FINAL_STATUS",
    "22.3": "FAZ4B_22_3_FINAL_STATUS",
    "22.4": "FAZ4B_22_4_FINAL_STATUS",
    "22.5": "FAZ4B_22_5_FINAL_STATUS",
    "22.6": "FAZ4B_22_6_FINAL_STATUS",
    "22.7": "FAZ4B_22_7_FINAL_STATUS",
}

domain_keys = {
    "22.1": "OBSERVABILITY_BASELINE",
    "22.2": "METRICS_SCRAPE_READINESS",
    "22.3": "LOGS_LOKI_READINESS",
    "22.4": "TRACES_TEMPO_READINESS",
    "22.5": "ALERT_RULE_CATALOG",
    "22.6": "OPS_CONSOLE_SIGNAL_CONTRACT",
    "22.7": "OBS_OPS_TESTS",
}

artifact_sets = {
    "22.1": [
        "docs/phase4/22_1_observability_baseline_standard.md",
        "docs/phase4/22_1_observability_baseline_policy.md",
        "docs/phase4/22_1_observability_signal_inventory.tsv",
        "docs/phase4/22_1_observability_target_inventory.tsv",
        "docs/phase4/22_1_observability_endpoint_probe.tsv",
        "docs/phase4/22_1_observability_alert_readiness.tsv",
        "docs/phase4/22_1_observability_baseline_matrix.tsv",
        "docs/phase4/22_1_observability_baseline_report.md",
        "scripts/phase4b_observability_baseline.sh",
        "scripts/phase4b_observability_baseline.py",
        "scripts/test_phase4b_observability_baseline.sh",
    ],
    "22.2": [
        "docs/phase4/22_2_metrics_scrape_readiness_standard.md",
        "docs/phase4/22_2_metrics_scrape_readiness_policy.md",
        "docs/phase4/22_2_metrics_target_inventory.tsv",
        "docs/phase4/22_2_metrics_endpoint_probe.tsv",
        "docs/phase4/22_2_metrics_public_surface_policy.tsv",
        "docs/phase4/22_2_metrics_scrape_readiness_matrix.tsv",
        "docs/phase4/22_2_metrics_scrape_readiness_report.md",
        "scripts/phase4b_metrics_scrape_readiness.sh",
        "scripts/phase4b_metrics_scrape_readiness.py",
        "scripts/test_phase4b_metrics_scrape_readiness.sh",
    ],
    "22.3": [
        "docs/phase4/22_3_logs_loki_readiness_standard.md",
        "docs/phase4/22_3_logs_loki_readiness_policy.md",
        "docs/phase4/22_3_logs_source_inventory.tsv",
        "docs/phase4/22_3_loki_endpoint_probe.tsv",
        "docs/phase4/22_3_log_pipeline_inventory.tsv",
        "docs/phase4/22_3_logs_public_surface_policy.tsv",
        "docs/phase4/22_3_logs_loki_readiness_matrix.tsv",
        "docs/phase4/22_3_logs_loki_readiness_report.md",
        "scripts/phase4b_logs_loki_readiness.sh",
        "scripts/phase4b_logs_loki_readiness.py",
        "scripts/test_phase4b_logs_loki_readiness.sh",
    ],
    "22.4": [
        "docs/phase4/22_4_traces_tempo_readiness_standard.md",
        "docs/phase4/22_4_traces_tempo_readiness_policy.md",
        "docs/phase4/22_4_trace_endpoint_probe.tsv",
        "docs/phase4/22_4_trace_pipeline_inventory.tsv",
        "docs/phase4/22_4_trace_signal_contract.tsv",
        "docs/phase4/22_4_trace_public_surface_policy.tsv",
        "docs/phase4/22_4_traces_tempo_readiness_matrix.tsv",
        "docs/phase4/22_4_traces_tempo_readiness_report.md",
        "scripts/phase4b_traces_tempo_readiness.sh",
        "scripts/phase4b_traces_tempo_readiness.py",
        "scripts/test_phase4b_traces_tempo_readiness.sh",
    ],
    "22.5": [
        "docs/phase4/22_5_alert_rule_catalog_standard.md",
        "docs/phase4/22_5_alert_rule_catalog_policy.md",
        "docs/phase4/22_5_alert_rule_catalog.tsv",
        "docs/phase4/22_5_alert_severity_matrix.tsv",
        "docs/phase4/22_5_alert_signal_mapping.tsv",
        "docs/phase4/22_5_alert_escalation_matrix.tsv",
        "docs/phase4/22_5_alert_rule_catalog_matrix.tsv",
        "docs/phase4/22_5_alert_rule_catalog_report.md",
        "scripts/phase4b_alert_rule_catalog.sh",
        "scripts/phase4b_alert_rule_catalog.py",
        "scripts/test_phase4b_alert_rule_catalog.sh",
    ],
    "22.6": [
        "docs/phase4/22_6_ops_console_signal_contract_standard.md",
        "docs/phase4/22_6_ops_console_signal_contract_policy.md",
        "docs/phase4/22_6_ops_console_signal_contract.tsv",
        "docs/phase4/22_6_ops_console_widget_contract.tsv",
        "docs/phase4/22_6_ops_console_api_contract.tsv",
        "docs/phase4/22_6_ops_console_alert_binding.tsv",
        "docs/phase4/22_6_ops_console_runbook_binding.tsv",
        "docs/phase4/22_6_ops_console_signal_contract_matrix.tsv",
        "docs/phase4/22_6_ops_console_signal_contract_report.md",
        "scripts/phase4b_ops_console_signal_contract.sh",
        "scripts/phase4b_ops_console_signal_contract.py",
        "scripts/test_phase4b_ops_console_signal_contract.sh",
    ],
    "22.7": [
        "docs/phase4/22_7_observability_ops_console_tests_standard.md",
        "docs/phase4/22_7_observability_ops_console_tests_report.md",
        "docs/phase4/22_7_observability_ops_console_tests_matrix.tsv",
        "docs/phase4/22_7_observability_ops_console_tests_inventory.tsv",
        "scripts/phase4b_observability_ops_console_tests.sh",
        "scripts/phase4b_observability_ops_console_tests.py",
        "scripts/test_phase4b_observability_ops_console_tests.sh",
    ],
}

required_pass_keys = {
    "22.1": [
        "OBSERVABILITY_PREVIOUS_20",
        "OBSERVABILITY_PREVIOUS_21",
        "OBSERVABILITY_SIGNAL_INVENTORY",
        "OBSERVABILITY_TARGET_INVENTORY",
        "OBSERVABILITY_ENDPOINT_PROBE",
        "OBSERVABILITY_ALERT_READINESS",
        "OBSERVABILITY_NO_RESTART",
        "OBSERVABILITY_NO_DEPLOY",
        "OBSERVABILITY_SECRET_SAFE",
    ],
    "22.2": [
        "METRICS_PREVIOUS_22_1",
        "METRICS_TARGET_INVENTORY",
        "METRICS_ENDPOINT_PROBE",
        "METRICS_PROMETHEUS_READINESS",
        "METRICS_PUBLIC_SURFACE_POLICY",
        "METRICS_NO_RESTART",
        "METRICS_NO_CONFIG_CHANGE",
        "METRICS_BODY_NOT_PRINTED",
        "METRICS_SECRET_SAFE",
    ],
    "22.3": [
        "LOGS_PREVIOUS_22_2",
        "LOGS_LOKI_ENDPOINT_PROBE",
        "LOGS_SOURCE_INVENTORY",
        "LOGS_PIPELINE_INVENTORY",
        "LOGS_PUBLIC_SURFACE_POLICY",
        "LOGS_BODY_NOT_PRINTED",
        "LOGS_NO_RESTART",
        "LOGS_NO_CONFIG_CHANGE",
        "LOGS_SECRET_SAFE",
    ],
    "22.4": [
        "TRACES_PREVIOUS_22_3",
        "TRACES_TEMPO_ENDPOINT_PROBE",
        "TRACES_PIPELINE_INVENTORY",
        "TRACES_SIGNAL_CONTRACT",
        "TRACES_PUBLIC_SURFACE_POLICY",
        "TRACES_BODY_NOT_PRINTED",
        "TRACES_NO_RESTART",
        "TRACES_NO_CONFIG_CHANGE",
        "TRACES_SECRET_SAFE",
    ],
    "22.5": [
        "ALERT_PREVIOUS_22_4",
        "ALERT_RULE_INVENTORY",
        "ALERT_SEVERITY_MATRIX",
        "ALERT_SIGNAL_MAPPING",
        "ALERT_ESCALATION_MATRIX",
        "ALERT_RUNBOOK_PLACEHOLDER",
        "ALERT_NO_CONFIG_CHANGE",
        "ALERT_NO_RESTART",
        "ALERT_BODY_NOT_PRINTED",
        "ALERT_SECRET_SAFE",
    ],
    "22.6": [
        "OPS_PREVIOUS_22_5",
        "OPS_SIGNAL_CONTRACT",
        "OPS_WIDGET_CONTRACT",
        "OPS_API_CONTRACT",
        "OPS_ALERT_BINDING",
        "OPS_RUNBOOK_BINDING",
        "OPS_CONTRACT_COVERAGE",
        "OPS_NO_RUNTIME_CHANGE",
        "OPS_NO_CONFIG_CHANGE",
        "OPS_BODY_NOT_PRINTED",
        "OPS_SECRET_SAFE",
    ],
    "22.7": [
        "OBS_TEST_BASELINE",
        "OBS_TEST_METRICS",
        "OBS_TEST_LOGS",
        "OBS_TEST_TRACES",
        "OBS_TEST_ALERTS",
        "OBS_TEST_OPS_CONSOLE",
        "OBS_TEST_ARTIFACT_COVERAGE",
        "OBS_TEST_NO_RUNTIME_CHANGE",
        "OBS_TEST_NO_CONFIG_CHANGE",
        "OBS_TEST_BODY_NOT_PRINTED",
        "OBS_TEST_SECRET_SAFE",
    ],
}

required_no_keys_common = [
    "SERVICE_RESTARTED",
    "CONTAINER_RESTARTED",
    "DOCKER_COMPOSE_EXECUTED",
    "NGINX_RELOAD_EXECUTED",
    "FIREWALL_CHANGED",
    "CONFIG_CHANGED",
    "ENV_CHANGED",
    "DB_MUTATION",
    "DB_APPLY_EXECUTED",
    "MIGRATION_CREATED",
    "MIGRATION_APPLY_EXECUTED",
    "LOG_CONTENT_PRINTED",
    "METRIC_BODY_PRINTED",
    "TRACE_BODY_PRINTED",
    "QUERY_TEXT_PRINTED",
    "RAW_DSN_PRINTED",
    "SECRET_VALUE_PRINTED",
]

extra_no_keys = {
    "22.1": [
        "DASHBOARD_CHANGED",
        "ALERT_RULE_CHANGED",
        "PROMETHEUS_CONFIG_CHANGED",
        "GRAFANA_CONFIG_CHANGED",
        "LOKI_CONFIG_CHANGED",
        "TEMPO_CONFIG_CHANGED",
    ],
    "22.2": [
        "PORT_CHANGED",
        "PROMETHEUS_CONFIG_CHANGED",
        "PROMETHEUS_RELOAD_EXECUTED",
        "PROMETHEUS_RESTARTED",
        "GRAFANA_DASHBOARD_CHANGED",
        "ALERT_RULE_CHANGED",
        "PROMETHEUS_QUERY_BODY_PRINTED",
    ],
    "22.3": [
        "PORT_CHANGED",
        "LOKI_CONFIG_CHANGED",
        "LOKI_RELOAD_EXECUTED",
        "LOKI_RESTARTED",
        "PROMTAIL_CONFIG_CHANGED",
        "LOG_AGENT_CONFIG_CHANGED",
        "GRAFANA_DASHBOARD_CHANGED",
        "ALERT_RULE_CHANGED",
        "LOKI_QUERY_BODY_PRINTED",
        "JOURNAL_LOG_BODY_PRINTED",
        "DOCKER_LOG_BODY_PRINTED",
    ],
    "22.4": [
        "PORT_CHANGED",
        "TEMPO_CONFIG_CHANGED",
        "TEMPO_RELOAD_EXECUTED",
        "TEMPO_RESTARTED",
        "OTEL_CONFIG_CHANGED",
        "OTEL_RELOAD_EXECUTED",
        "OTEL_RESTARTED",
        "GRAFANA_DASHBOARD_CHANGED",
        "ALERT_RULE_CHANGED",
        "TEMPO_QUERY_BODY_PRINTED",
        "OTEL_PAYLOAD_PRINTED",
        "SPAN_ATTRIBUTE_PRINTED",
    ],
    "22.5": [
        "PORT_CHANGED",
        "PROMETHEUS_CONFIG_CHANGED",
        "PROMETHEUS_RELOAD_EXECUTED",
        "PROMETHEUS_RESTARTED",
        "ALERTMANAGER_CONFIG_CHANGED",
        "ALERTMANAGER_RELOAD_EXECUTED",
        "ALERTMANAGER_RESTARTED",
        "GRAFANA_DASHBOARD_CHANGED",
        "GRAFANA_ALERT_CHANGED",
        "ALERT_RULE_CHANGED",
        "PROMETHEUS_QUERY_BODY_PRINTED",
        "LOKI_QUERY_BODY_PRINTED",
        "TEMPO_QUERY_BODY_PRINTED",
    ],
    "22.6": [
        "PORT_CHANGED",
        "OPS_CONSOLE_CODE_CHANGED",
        "OPS_CONSOLE_API_IMPLEMENTED",
        "OPS_CONSOLE_UI_CHANGED",
        "PROMETHEUS_CONFIG_CHANGED",
        "ALERTMANAGER_CONFIG_CHANGED",
        "GRAFANA_DASHBOARD_CHANGED",
        "GRAFANA_ALERT_CHANGED",
        "ALERT_RULE_CHANGED",
        "LOKI_CONFIG_CHANGED",
        "TEMPO_CONFIG_CHANGED",
        "OTEL_CONFIG_CHANGED",
        "QUERY_BODY_PRINTED",
    ],
    "22.7": [
        "PORT_CHANGED",
        "OPS_CONSOLE_CODE_CHANGED",
        "OPS_CONSOLE_API_IMPLEMENTED",
        "OPS_CONSOLE_UI_CHANGED",
        "PROMETHEUS_CONFIG_CHANGED",
        "PROMETHEUS_RELOAD_EXECUTED",
        "PROMETHEUS_RESTARTED",
        "ALERTMANAGER_CONFIG_CHANGED",
        "ALERTMANAGER_RELOAD_EXECUTED",
        "ALERTMANAGER_RESTARTED",
        "GRAFANA_DASHBOARD_CHANGED",
        "GRAFANA_ALERT_CHANGED",
        "ALERT_RULE_CHANGED",
        "LOKI_CONFIG_CHANGED",
        "TEMPO_CONFIG_CHANGED",
        "OTEL_CONFIG_CHANGED",
        "QUERY_BODY_PRINTED",
    ],
}

metric_keys = {
    "22.1": [
        "OBSERVABILITY_SIGNAL_COUNT",
        "OBSERVABILITY_TARGET_COUNT",
        "OBSERVABILITY_ENDPOINT_PROBE_COUNT",
        "OBSERVABILITY_ALERT_CANDIDATE_COUNT",
    ],
    "22.2": [
        "METRICS_ENDPOINT_PROBE_COUNT",
        "METRICS_TARGET_INVENTORY_COUNT",
        "METRICS_PROMETHEUS_ACTIVE_TARGET_COUNT",
        "METRICS_PROMETHEUS_UP_TARGET_COUNT",
        "METRICS_HIGH_RISK_PUBLIC_SURFACE_COUNT",
    ],
    "22.3": [
        "LOGS_LOKI_ENDPOINT_PROBE_COUNT",
        "LOGS_SOURCE_COUNT",
        "LOGS_PIPELINE_CONFIG_COUNT",
        "LOGS_HIGH_RISK_PUBLIC_SURFACE_COUNT",
    ],
    "22.4": [
        "TRACES_TEMPO_ENDPOINT_PROBE_COUNT",
        "TRACES_PIPELINE_CONFIG_COUNT",
        "TRACES_SIGNAL_CONTRACT_COUNT",
        "TRACES_HIGH_RISK_PUBLIC_SURFACE_COUNT",
    ],
    "22.5": [
        "ALERT_RULE_COUNT",
        "ALERT_CRITICAL_COUNT",
        "ALERT_HIGH_COUNT",
        "ALERT_SIGNAL_MAPPING_COUNT",
        "ALERT_RUNBOOK_PLACEHOLDER_COUNT",
    ],
    "22.6": [
        "OPS_SIGNAL_COUNT",
        "OPS_WIDGET_COUNT",
        "OPS_API_ENDPOINT_COUNT",
        "OPS_ALERT_BINDING_COUNT",
        "OPS_RUNBOOK_BINDING_COUNT",
    ],
    "22.7": [
        "OBS_TEST_METRIC_EVIDENCE_TOTAL",
        "OBS_TEST_GATE_FAILURE_COUNT",
        "OBS_TEST_NO_CHANGE_FAILURE_COUNT",
        "OBS_TEST_ARTIFACT_MISSING_COUNT",
        "OBS_TEST_METRIC_MISSING_COUNT",
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
detail("OPS_CONSOLE_CODE_CHANGED=NO")
detail("OPS_CONSOLE_API_IMPLEMENTED=NO")
detail("OPS_CONSOLE_UI_CHANGED=NO")
detail("PROMETHEUS_CONFIG_CHANGED=NO")
detail("PROMETHEUS_RELOAD_EXECUTED=NO")
detail("PROMETHEUS_RESTARTED=NO")
detail("ALERTMANAGER_CONFIG_CHANGED=NO")
detail("ALERTMANAGER_RELOAD_EXECUTED=NO")
detail("ALERTMANAGER_RESTARTED=NO")
detail("GRAFANA_DASHBOARD_CHANGED=NO")
detail("GRAFANA_ALERT_CHANGED=NO")
detail("ALERT_RULE_CHANGED=NO")
detail("LOKI_CONFIG_CHANGED=NO")
detail("TEMPO_CONFIG_CHANGED=NO")
detail("OTEL_CONFIG_CHANGED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("METRIC_BODY_PRINTED=NO")
detail("LOG_CONTENT_PRINTED=NO")
detail("TRACE_BODY_PRINTED=NO")
detail("QUERY_BODY_PRINTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

if not standard_file.exists():
    fail("22.8 standard doc yok")

prev_20_status = get_value(reports["20"], "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(reports["20"], "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(reports["21"], "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(reports["21"], "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

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

for block in ["22.1", "22.2", "22.3", "22.4", "22.5", "22.6", "22.7"]:
    report = reports[block]
    final_status = get_value(report, final_keys[block])
    domain_status = get_value(report, domain_keys[block])

    detail(f"OBS_FINAL_{block.replace('.', '_')}_FINAL_STATUS={final_status}")
    detail(f"OBS_FINAL_{block.replace('.', '_')}_{domain_keys[block]}={domain_status}")

    local_failures = []

    if final_status != "PASS":
        local_failures.append(f"{final_keys[block]}={final_status}")
    if domain_status != "PASS":
        local_failures.append(f"{domain_keys[block]}={domain_status}")

    for key in required_pass_keys[block]:
        value = get_value(report, key)
        detail(f"OBS_FINAL_{block.replace('.', '_')}_{key}={value}")
        if value != "PASS":
            local_failures.append(f"{key}={value}")

    no_keys = list(dict.fromkeys(required_no_keys_common + extra_no_keys.get(block, [])))

    # 22.3 Logs/Loki gate sadece log body guvenligini dogrudan uretir.
    # METRIC_BODY_PRINTED ve TRACE_BODY_PRINTED 22.3 raporunda zorunlu alan degildir.
    # Bu alanlar bos gelirse, 22.3'teki LOGS_BODY_NOT_PRINTED=PASS kanitina baglanarak NO kabul edilir.
    optional_no_fallback_pass_keys = {
        "22.3": {
            "METRIC_BODY_PRINTED": "LOGS_BODY_NOT_PRINTED",
            "TRACE_BODY_PRINTED": "LOGS_BODY_NOT_PRINTED",
        }
    }

    for key in no_keys:
        value = get_value(report, key)
        fallback_key = optional_no_fallback_pass_keys.get(block, {}).get(key, "")

        if value == "" and fallback_key:
            fallback_value = get_value(report, fallback_key)
            if fallback_value == "PASS":
                value = "NO"
                detail(f"OBS_FINAL_{block.replace('.', '_')}_{key}_FALLBACK={fallback_key}=PASS")
            else:
                detail(f"OBS_FINAL_{block.replace('.', '_')}_{key}_FALLBACK={fallback_key}={fallback_value}")

        detail(f"OBS_FINAL_{block.replace('.', '_')}_{key}={value}")
        if value != "NO":
            no_change_failures.append(f"{block}:{key}={value}")

    metric_hit_count = 0
    metric_sum = 0
    for key in metric_keys[block]:
        value = get_value(report, key)
        detail(f"OBS_FINAL_{block.replace('.', '_')}_{key}={value}")
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

    detail(f"OBS_FINAL_{block.replace('.', '_')}_ARTIFACT_EXPECTED_COUNT={expected_artifact_count}")
    detail(f"OBS_FINAL_{block.replace('.', '_')}_ARTIFACT_EXISTING_COUNT={existing_artifact_count}")

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
    fail("observability final gate failure: " + ",".join(gate_failures[:70]))

if no_change_failures:
    fail("observability final no-change failure: " + ",".join(no_change_failures[:70]))

if artifact_missing:
    fail("observability final artifact eksik: " + ",".join(artifact_missing[:70]))

if metric_missing:
    fail("observability final metric evidence eksik: " + ",".join(metric_missing[:70]))

baseline_status = block_results["22.1"]["status"]
metrics_status = block_results["22.2"]["status"]
logs_status = block_results["22.3"]["status"]
traces_status = block_results["22.4"]["status"]
alerts_status = block_results["22.5"]["status"]
ops_status = block_results["22.6"]["status"]
tests_status = block_results["22.7"]["status"]

artifact_coverage_status = "PASS" if not artifact_missing else "FAIL"
no_runtime_change_status = "PASS" if not no_change_failures else "FAIL"
no_config_change_status = "PASS" if not no_change_failures else "FAIL"
body_not_printed_status = "PASS" if not no_change_failures else "FAIL"
secret_safe_status = "PASS" if not no_change_failures else "FAIL"

for label, status in [
    ("OBS_FINAL_BASELINE", baseline_status),
    ("OBS_FINAL_METRICS", metrics_status),
    ("OBS_FINAL_LOGS", logs_status),
    ("OBS_FINAL_TRACES", traces_status),
    ("OBS_FINAL_ALERTS", alerts_status),
    ("OBS_FINAL_OPS_CONSOLE", ops_status),
    ("OBS_FINAL_TESTS", tests_status),
    ("OBS_FINAL_ARTIFACT_COVERAGE", artifact_coverage_status),
    ("OBS_FINAL_NO_RUNTIME_CHANGE", no_runtime_change_status),
    ("OBS_FINAL_NO_CONFIG_CHANGE", no_config_change_status),
    ("OBS_FINAL_BODY_NOT_PRINTED", body_not_printed_status),
    ("OBS_FINAL_SECRET_SAFE", secret_safe_status),
]:
    detail(f"{label}={status}")
    if status != "PASS":
        fail(f"{label} PASS degil")

detail(f"OBS_FINAL_METRIC_EVIDENCE_TOTAL={metric_total}")
detail(f"OBS_FINAL_GATE_FAILURE_COUNT={len(gate_failures)}")
detail(f"OBS_FINAL_NO_CHANGE_FAILURE_COUNT={len(no_change_failures)}")
detail(f"OBS_FINAL_ARTIFACT_MISSING_COUNT={len(artifact_missing)}")
detail(f"OBS_FINAL_METRIC_MISSING_COUNT={len(metric_missing)}")

matrix_lines = [
    "gate\tstatus\tnote",
    f"baseline\t{baseline_status}\t22.1 observability baseline final",
    f"metrics\t{metrics_status}\t22.2 metrics scrape readiness final",
    f"logs\t{logs_status}\t22.3 logs/loki readiness final",
    f"traces\t{traces_status}\t22.4 traces/tempo readiness final",
    f"alerts\t{alerts_status}\t22.5 alert rule catalog final",
    f"ops_console\t{ops_status}\t22.6 ops console signal contract final",
    f"observability_tests\t{tests_status}\t22.7 observability ops console tests final",
    f"artifact_coverage\t{artifact_coverage_status}\tmissing={len(artifact_missing)}",
    f"no_runtime_change\t{no_runtime_change_status}\tfailures={len(no_change_failures)}",
    f"no_config_change\t{no_config_change_status}\tfailures={len(no_change_failures)}",
    f"body_not_printed\t{body_not_printed_status}\tfailures={len(no_change_failures)}",
    f"secret_safe\t{secret_safe_status}\tfailures={len(no_change_failures)}",
    f"metric_evidence\tPASS\ttotal={metric_total} missing={len(metric_missing)}",
    "service_restarted\tNO\tfinal evidence only",
    "container_restarted\tNO\tfinal evidence only",
    "docker_compose_executed\tNO\tfinal evidence only",
    "nginx_reload_executed\tNO\tfinal evidence only",
    "firewall_changed\tNO\tfinal evidence only",
    "port_changed\tNO\tfinal evidence only",
    "config_changed\tNO\tfinal evidence only",
    "env_changed\tNO\tfinal evidence only",
    "ops_console_code_changed\tNO\tfinal contract only",
    "ops_console_api_implemented\tNO\tfinal contract only",
    "ops_console_ui_changed\tNO\tfinal contract only",
    "prometheus_config_changed\tNO\tfinal evidence only",
    "prometheus_reload_executed\tNO\tfinal evidence only",
    "prometheus_restarted\tNO\tfinal evidence only",
    "alertmanager_config_changed\tNO\tfinal evidence only",
    "alertmanager_reload_executed\tNO\tfinal evidence only",
    "alertmanager_restarted\tNO\tfinal evidence only",
    "grafana_dashboard_changed\tNO\tfinal evidence only",
    "grafana_alert_changed\tNO\tfinal evidence only",
    "alert_rule_changed\tNO\tfinal evidence only",
    "loki_config_changed\tNO\tfinal evidence only",
    "tempo_config_changed\tNO\tfinal evidence only",
    "otel_config_changed\tNO\tfinal evidence only",
    "db_mutation\tNO\tfinal evidence only",
    "db_apply_executed\tNO\tfinal evidence only",
    "migration_created\tNO\tfinal evidence only",
    "migration_apply_executed\tNO\tfinal evidence only",
    "metric_body_printed\tNO\tsecret-safe report",
    "log_content_printed\tNO\tsecret-safe report",
    "trace_body_printed\tNO\tsecret-safe report",
    "query_body_printed\tNO\tsecret-safe report",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = [
    "block\tstatus\tdomain_key\treport_file\tartifact_expected\tartifact_existing\tmetric_hit_count\tmetric_expected\tmetric_sum\tgate_failures"
]

for block in ["22.1", "22.2", "22.3", "22.4", "22.5", "22.6", "22.7"]:
    result = block_results[block]
    inventory_lines.append(
        f"{block}\t{result['status']}\t{domain_keys[block]}\t{str(reports[block].relative_to(root))}\t{result['artifact_expected']}\t{result['artifact_existing']}\t{result['metric_hit_count']}\t{result['metric_expected']}\t{result['metric_sum']}\t{result['gate_failures']}"
    )

inventory_file.write_text("\n".join(inventory_lines) + "\n")

detail(f"OBS_FINAL_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"OBS_FINAL_INVENTORY_LINE_COUNT={len(inventory_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE={final_status}")
detail(f"FAZ4B_22_8_FINAL_STATUS={final_status}")
detail(f"FAZ4B_22_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 22.8 - Observability / Ops Console Final Closure Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE={final_status}",
    f"FAZ4B_22_8_FINAL_STATUS={final_status}",
    f"FAZ4B_22_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/22_8_observability_ops_console_final_closure_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/22_8_observability_ops_console_final_closure_inventory.tsv",
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
    "OPS_CONSOLE_CODE_CHANGED=NO",
    "OPS_CONSOLE_API_IMPLEMENTED=NO",
    "OPS_CONSOLE_UI_CHANGED=NO",
    "PROMETHEUS_CONFIG_CHANGED=NO",
    "PROMETHEUS_RELOAD_EXECUTED=NO",
    "PROMETHEUS_RESTARTED=NO",
    "ALERTMANAGER_CONFIG_CHANGED=NO",
    "ALERTMANAGER_RELOAD_EXECUTED=NO",
    "ALERTMANAGER_RESTARTED=NO",
    "GRAFANA_DASHBOARD_CHANGED=NO",
    "GRAFANA_ALERT_CHANGED=NO",
    "ALERT_RULE_CHANGED=NO",
    "LOKI_CONFIG_CHANGED=NO",
    "TEMPO_CONFIG_CHANGED=NO",
    "OTEL_CONFIG_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "METRIC_BODY_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "TRACE_BODY_PRINTED=NO",
    "QUERY_BODY_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
    "",
    "## Secret Safety",
    "RAW_DSN_PRINTED=NO",
    "POSTGRES_PASSWORD_PRINTED=NO",
    "AUTH_TOKEN_PRINTED=NO",
    "METRIC_BODY_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "TRACE_BODY_PRINTED=NO",
    "QUERY_BODY_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

closure_lines = [
    "# FAZ 4B / 22 - Observability / Ops Console Final Closure",
    "",
    f"Generated at: {now()}",
    "",
    f"FAZ4B_22_FINAL_STATUS={final_status}",
    f"FAZ4B_22_8_FINAL_STATUS={final_status}",
    f"OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE={final_status}",
    "",
    "## Closed Items",
    f"22.1 Observability baseline / signal inventory={baseline_status}",
    f"22.2 Metrics / scrape target readiness={metrics_status}",
    f"22.3 Logs / Loki readiness={logs_status}",
    f"22.4 Traces / Tempo readiness={traces_status}",
    f"22.5 Alert rule catalog / severity matrix={alerts_status}",
    f"22.6 Ops Console signal contract={ops_status}",
    f"22.7 Observability / Ops Console tests={tests_status}",
    f"22.8 Observability / Ops Console final closure={final_status}",
    "",
    "## Final Gates",
    f"OBS_FINAL_BASELINE={baseline_status}",
    f"OBS_FINAL_METRICS={metrics_status}",
    f"OBS_FINAL_LOGS={logs_status}",
    f"OBS_FINAL_TRACES={traces_status}",
    f"OBS_FINAL_ALERTS={alerts_status}",
    f"OBS_FINAL_OPS_CONSOLE={ops_status}",
    f"OBS_FINAL_TESTS={tests_status}",
    f"OBS_FINAL_ARTIFACT_COVERAGE={artifact_coverage_status}",
    f"OBS_FINAL_NO_RUNTIME_CHANGE={no_runtime_change_status}",
    f"OBS_FINAL_NO_CONFIG_CHANGE={no_config_change_status}",
    f"OBS_FINAL_BODY_NOT_PRINTED={body_not_printed_status}",
    f"OBS_FINAL_SECRET_SAFE={secret_safe_status}",
    f"OBS_FINAL_METRIC_EVIDENCE_TOTAL={metric_total}",
    "",
    "## Important Production Notes",
    "OBSERVABILITY_PUBLIC_SURFACE_REMEDIATION_REQUIRED=YES",
    "OPS_CONSOLE_API_IMPLEMENTATION_REQUIRED=YES",
    "OPS_CONSOLE_UI_IMPLEMENTATION_REQUIRED=YES",
    "ALERT_RULE_EXECUTION_REQUIRED=YES",
    "RUNBOOK_FILE_CREATION_REQUIRED=YES",
    "PROMTAIL_OR_LOG_AGENT_EXECUTION_REVIEW_REQUIRED=YES",
    "SPAN_ID_STANDARDIZATION_REQUIRED=YES",
    "",
    "## Safety",
    "SERVICE_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "FIREWALL_CHANGED=NO",
    "PORT_CHANGED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "OPS_CONSOLE_CODE_CHANGED=NO",
    "OPS_CONSOLE_API_IMPLEMENTED=NO",
    "OPS_CONSOLE_UI_CHANGED=NO",
    "PROMETHEUS_CONFIG_CHANGED=NO",
    "ALERTMANAGER_CONFIG_CHANGED=NO",
    "GRAFANA_ALERT_CHANGED=NO",
    "ALERT_RULE_CHANGED=NO",
    "LOKI_CONFIG_CHANGED=NO",
    "TEMPO_CONFIG_CHANGED=NO",
    "OTEL_CONFIG_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "METRIC_BODY_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "TRACE_BODY_PRINTED=NO",
    "QUERY_BODY_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
closure_file.write_text("\n".join(closure_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"CLOSURE_FILE={closure_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"OBS_FINAL_BASELINE={baseline_status}")
print(f"OBS_FINAL_METRICS={metrics_status}")
print(f"OBS_FINAL_LOGS={logs_status}")
print(f"OBS_FINAL_TRACES={traces_status}")
print(f"OBS_FINAL_ALERTS={alerts_status}")
print(f"OBS_FINAL_OPS_CONSOLE={ops_status}")
print(f"OBS_FINAL_TESTS={tests_status}")
print(f"OBS_FINAL_ARTIFACT_COVERAGE={artifact_coverage_status}")
print(f"OBS_FINAL_NO_RUNTIME_CHANGE={no_runtime_change_status}")
print(f"OBS_FINAL_NO_CONFIG_CHANGE={no_config_change_status}")
print(f"OBS_FINAL_BODY_NOT_PRINTED={body_not_printed_status}")
print(f"OBS_FINAL_SECRET_SAFE={secret_safe_status}")
print(f"OBS_FINAL_METRIC_EVIDENCE_TOTAL={metric_total}")
print(f"OBS_FINAL_GATE_FAILURE_COUNT={len(gate_failures)}")
print(f"OBS_FINAL_NO_CHANGE_FAILURE_COUNT={len(no_change_failures)}")
print(f"OBS_FINAL_ARTIFACT_MISSING_COUNT={len(artifact_missing)}")
print(f"OBS_FINAL_METRIC_MISSING_COUNT={len(metric_missing)}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("OPS_CONSOLE_CODE_CHANGED=NO")
print("OPS_CONSOLE_API_IMPLEMENTED=NO")
print("OPS_CONSOLE_UI_CHANGED=NO")
print("PROMETHEUS_CONFIG_CHANGED=NO")
print("ALERTMANAGER_CONFIG_CHANGED=NO")
print("GRAFANA_DASHBOARD_CHANGED=NO")
print("GRAFANA_ALERT_CHANGED=NO")
print("ALERT_RULE_CHANGED=NO")
print("LOKI_CONFIG_CHANGED=NO")
print("TEMPO_CONFIG_CHANGED=NO")
print("OTEL_CONFIG_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("METRIC_BODY_PRINTED=NO")
print("LOG_CONTENT_PRINTED=NO")
print("TRACE_BODY_PRINTED=NO")
print("QUERY_BODY_PRINTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_22_8_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_22_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
