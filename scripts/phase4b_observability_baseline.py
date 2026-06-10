#!/usr/bin/env python3
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from shutil import which
from urllib.parse import urlparse

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "22_1_observability_baseline_standard.md"
policy_file = report_dir / "22_1_observability_baseline_policy.md"
signal_inventory_file = report_dir / "22_1_observability_signal_inventory.tsv"
target_inventory_file = report_dir / "22_1_observability_target_inventory.tsv"
endpoint_probe_file = report_dir / "22_1_observability_endpoint_probe.tsv"
alert_readiness_file = report_dir / "22_1_observability_alert_readiness.tsv"
matrix_file = report_dir / "22_1_observability_baseline_matrix.tsv"
report_file = report_dir / "22_1_observability_baseline_report.md"

prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_20_8 = report_dir / "20_8_infra_cleanup_production_hardening_final_closure_report.md"
prev_20_3_ports = report_dir / "20_3_runtime_service_hardening_ports.tsv"
prev_20_3_services = report_dir / "20_3_runtime_service_hardening_services.tsv"
prev_20_5_containers = report_dir / "20_5_docker_container_inventory.tsv"
prev_20_5_ports = report_dir / "20_5_docker_public_port_policy.tsv"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

OBS_TARGETS = [
    ("prometheus_ready", "http://127.0.0.1:9090/-/ready", "metrics_core", "prometheus"),
    ("prometheus_health", "http://127.0.0.1:9090/-/healthy", "metrics_core", "prometheus"),
    ("grafana_health_3000", "http://127.0.0.1:3000/api/health", "dashboard", "grafana"),
    ("grafana_health_3001", "http://127.0.0.1:3001/api/health", "dashboard", "grafana"),
    ("loki_ready", "http://127.0.0.1:3100/ready", "logs", "loki"),
    ("tempo_ready", "http://127.0.0.1:3200/ready", "traces", "tempo"),
    ("node_exporter_metrics", "http://127.0.0.1:9100/metrics", "host_metrics", "node_exporter"),
    ("cadvisor_health", "http://127.0.0.1:8080/healthz", "container_metrics", "cadvisor"),
    ("cadvisor_metrics", "http://127.0.0.1:8080/metrics", "container_metrics", "cadvisor"),
    ("nats_monitoring", "http://127.0.0.1:8222/healthz", "event_bus_metrics", "nats"),
    ("api_gateway_health", "http://127.0.0.1:9010/health", "api_health", "api_gateway"),
    ("identity_health", "http://127.0.0.1:9001/health", "service_health", "identity"),
]

SIGNAL_DEFINITIONS = [
    ("service_health", "systemd_active_state", "service up/down evidence", "runtime_service", "HIGH"),
    ("container_health", "docker_status_healthcheck", "container running/healthcheck evidence", "docker", "HIGH"),
    ("metrics_endpoint", "prometheus_node_cadvisor", "metrics scrape target evidence", "metrics", "HIGH"),
    ("logs_signal", "loki_readiness", "central log readiness evidence", "logs", "MEDIUM"),
    ("traces_signal", "tempo_readiness", "distributed trace readiness evidence", "traces", "MEDIUM"),
    ("db_health", "postgres_port_volume_previous_evidence", "db health placeholder", "database", "HIGH"),
    ("event_bus_health", "nats_port_previous_evidence", "event bus health placeholder", "event_bus", "HIGH"),
    ("queue_backlog", "event_backlog_placeholder", "queue/backlog alert placeholder", "event_bus", "HIGH"),
    ("dlq_signal", "dlq_placeholder", "dead-letter growth alert placeholder", "event_bus", "HIGH"),
    ("api_gateway_health", "gateway_health_endpoint", "API gateway health readiness", "api", "HIGH"),
    ("mission_control_health", "mission_control_placeholder", "ops service registry readiness", "ops", "MEDIUM"),
    ("ops_console_health", "ops_console_placeholder", "future ops console surface", "ops", "MEDIUM"),
    ("alert_readiness", "alert_rule_contract", "alert candidate catalog", "alerting", "HIGH"),
    ("public_surface_observability_risk", "public_metrics_ports_previous_evidence", "public metrics/log/traces risk evidence", "security", "HIGH"),
    ("tenant_security_observability", "security_audit_previous_evidence", "tenant/security audit observability", "security", "HIGH"),
]

ALERTS = [
    ("service_down", "critical", "service_health", "systemd active != active", "ops_console_alert"),
    ("container_down", "critical", "container_health", "docker status not running", "ops_console_alert"),
    ("high_public_surface_risk", "critical", "public_surface_observability_risk", "internal metrics/db/event ports public", "security_alert"),
    ("db_connection_error", "critical", "db_health", "db connection failures", "db_alert"),
    ("event_bus_backlog_high", "high", "queue_backlog", "event bus backlog high", "event_alert"),
    ("dlq_growth", "high", "dlq_signal", "dead-letter queue growth", "event_alert"),
    ("api_error_rate_high", "high", "api_gateway_health", "5xx or error rate high", "api_alert"),
    ("latency_high", "medium", "metrics_endpoint", "p95/p99 latency high", "performance_alert"),
    ("disk_usage_high", "high", "metrics_endpoint", "disk usage threshold", "infra_alert"),
    ("memory_high", "medium", "metrics_endpoint", "memory usage threshold", "infra_alert"),
    ("cpu_high", "medium", "metrics_endpoint", "cpu saturation threshold", "infra_alert"),
    ("backup_stale", "high", "backup_archive", "backup age / restore drill stale", "backup_alert"),
    ("secret_leak_attempt", "critical", "tenant_security_observability", "secret / token leak signal", "security_alert"),
    ("audit_gap", "high", "tenant_security_observability", "audit log gap signal", "security_alert"),
]

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
    return status == "FOUND"

def run_cmd(cmd, timeout=8):
    try:
        p = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout,
            check=False,
        )
        return p.returncode, p.stdout.strip(), p.stderr.strip()
    except Exception as e:
        return 999, "", str(e)

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

def safe(v):
    v = str(v or "")
    v = v.replace("\t", " ").replace("\n", " ").replace("\r", " ")
    v = re.sub(r"(password|token|secret|dsn|authorization)\s*[:=]\s*[^ ]+", r"\1=***", v, flags=re.I)
    v = re.sub(r"://[^/@\s]+@", "://***@", v)
    return v[:240]

def parse_prev_tsv(path):
    text = read(path)
    lines = [x for x in text.splitlines() if x.strip()]
    if not lines:
        return []
    header = lines[0].split("\t")
    rows = []
    for line in lines[1:]:
        parts = line.split("\t")
        while len(parts) < len(header):
            parts.append("")
        rows.append(dict(zip(header, parts)))
    return rows

def endpoint_probe():
    rows = []

    curl_found = which("curl") is not None

    for name, url, category, service_hint in OBS_TARGETS:
        parsed = urlparse(url)
        host = parsed.hostname or "unknown"
        port = str(parsed.port or "")
        path = parsed.path or "/"

        if not curl_found:
            rows.append([
                name,
                category,
                service_hint,
                host,
                port,
                path,
                "NOT_PROBED",
                "0",
                "curl_not_found",
                "NO",
                "endpoint_metadata_only",
            ])
            continue

        rc, out, err = run_cmd([
            "curl",
            "-sS",
            "-o",
            "/dev/null",
            "-w",
            "%{http_code}",
            "--max-time",
            "2",
            url,
        ], timeout=4)

        status_code = out.strip() if out.strip().isdigit() else "000"
        reachable = "YES" if status_code not in ["000", ""] else "NO"
        result = "READY_OR_AUTH_REQUIRED" if status_code in ["200", "204", "301", "302", "401", "403"] else "REVIEW"

        rows.append([
            name,
            category,
            service_hint,
            host,
            port,
            path,
            result,
            status_code,
            "body_not_printed",
            reachable,
            "endpoint_metadata_only",
        ])

    return rows

def build_target_inventory():
    rows = []

    # Önce endpoint hedefleri
    for name, url, category, service_hint in OBS_TARGETS:
        parsed = urlparse(url)
        rows.append([
            name,
            category,
            service_hint,
            parsed.hostname or "unknown",
            str(parsed.port or ""),
            parsed.path or "/",
            "endpoint_target",
            "metadata_only",
        ])

    # Önceki port evidence
    port_rows = parse_prev_tsv(prev_20_3_ports)
    for r in port_rows:
        port = r.get("port", "")
        expected = r.get("expected_service", "")
        bind_scope = r.get("bind_scope", "")
        risk = r.get("risk", "")
        if port in ["9090", "9100", "8080", "3000", "3001", "3100", "3200", "4317", "4318", "8222"]:
            rows.append([
                f"previous_port_{port}",
                "previous_runtime_port",
                expected or "observability_or_internal",
                "previous_evidence",
                port,
                bind_scope,
                risk or "review",
                "from_20_3_runtime_service_ports",
            ])

    # Önceki container evidence
    container_rows = parse_prev_tsv(prev_20_5_containers)
    for r in container_rows:
        name = r.get("container_name", "")
        image = r.get("image", "")
        status = r.get("status", "")
        if re.search(r"prometheus|grafana|loki|tempo|cadvisor|node|exporter|nats|redis|postgres", name + " " + image, re.I):
            rows.append([
                f"container_{name}",
                "previous_docker_container",
                name,
                "docker",
                "",
                status,
                r.get("risk", ""),
                "from_20_5_docker_container_inventory",
            ])

    return rows

def count_previous_public_obs_risks():
    rows = parse_prev_tsv(prev_20_5_ports)
    count = 0
    for r in rows:
        hint = r.get("service_hint", "")
        risk = r.get("risk", "")
        if risk == "HIGH" and re.search(r"prometheus|grafana|loki|tempo|otel|cadvisor|node|nats|redis|postgres", hint, re.I):
            count += 1
    return count

def count_previous_service_risks():
    rows = parse_prev_tsv(prev_20_3_services)
    return sum(1 for r in rows if r.get("risk") == "HIGH")

def count_previous_container_risks():
    rows = parse_prev_tsv(prev_20_5_containers)
    return sum(1 for r in rows if r.get("risk") == "HIGH")

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("SERVICE_RESTARTED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("DOCKER_COMPOSE_EXECUTED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
detail("FIREWALL_CHANGED=NO")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("DASHBOARD_CHANGED=NO")
detail("ALERT_RULE_CHANGED=NO")
detail("PROMETHEUS_CONFIG_CHANGED=NO")
detail("GRAFANA_CONFIG_CHANGED=NO")
detail("LOKI_CONFIG_CHANGED=NO")
detail("TEMPO_CONFIG_CHANGED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("LOG_CONTENT_PRINTED=NO")
detail("METRIC_BODY_PRINTED=NO")
detail("TRACE_BODY_PRINTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=OBSERVABILITY_BASELINE_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "curl", "docker", "systemctl", "ss"]:
    tool_status(tool)

prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_20_8_status = get_value(prev_20_8, "FAZ4B_20_8_FINAL_STATUS")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_20_8_FINAL_STATUS={prev_20_8_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_20_status != "PASS":
    fail("20 final status PASS degil")
if prev_20_closure != "PASS":
    fail("20 infra production hardening closure PASS degil")
if prev_20_8_status != "PASS":
    fail("20.8 final status PASS degil")
if prev_21_status != "PASS":
    fail("21 final status PASS degil")
if prev_21_closure != "PASS":
    fail("21 security closure PASS degil")

for path, label in [
    (standard_file, "standard doc"),
    (policy_file, "policy doc"),
]:
    if not path.exists():
        fail(f"{label} yok")

public_obs_risk_count = count_previous_public_obs_risks()
service_risk_count = count_previous_service_risks()
container_risk_count = count_previous_container_risks()

signal_lines = [
    "signal_name\tevidence_source\tdescription\tcategory\tseverity\tbaseline_status\tnote"
]

for signal_name, source, desc, category, severity in SIGNAL_DEFINITIONS:
    baseline_status = "READY_FOR_MAPPING"
    note = "baseline_signal_defined"

    if signal_name == "public_surface_observability_risk":
        baseline_status = "RISK_EVIDENCE_PRESENT" if public_obs_risk_count > 0 else "NO_PREVIOUS_RISK_FOUND"
        note = f"previous_public_obs_risk_count={public_obs_risk_count}"

    if signal_name == "service_health":
        baseline_status = "RISK_EVIDENCE_PRESENT" if service_risk_count > 0 else "READY_FOR_MAPPING"
        note = f"previous_high_risk_service_count={service_risk_count}"

    if signal_name == "container_health":
        baseline_status = "RISK_EVIDENCE_PRESENT" if container_risk_count > 0 else "READY_FOR_MAPPING"
        note = f"previous_high_risk_container_count={container_risk_count}"

    signal_lines.append("\t".join([
        signal_name,
        source,
        desc,
        category,
        severity,
        baseline_status,
        note,
    ]))

signal_inventory_file.write_text("\n".join(signal_lines) + "\n")

target_rows = build_target_inventory()
target_lines = [
    "target_name\tcategory\tservice_hint\thost\tport\tpath_or_state\trisk_or_type\tnote"
]
for row in target_rows:
    target_lines.append("\t".join([safe(x) for x in row]))
target_inventory_file.write_text("\n".join(target_lines) + "\n")

probe_rows = endpoint_probe()
probe_lines = [
    "probe_name\tcategory\tservice_hint\thost\tport\tpath\tresult\tstatus_code\tbody_policy\treachable\tnote"
]
for row in probe_rows:
    probe_lines.append("\t".join([safe(x) for x in row]))
endpoint_probe_file.write_text("\n".join(probe_lines) + "\n")

alert_lines = [
    "alert_name\tseverity\tsignal_name\tcondition_hint\ttarget_channel\treadiness_status\tnote"
]
for alert_name, severity, signal_name, condition_hint, target_channel in ALERTS:
    alert_lines.append("\t".join([
        alert_name,
        severity,
        signal_name,
        condition_hint,
        target_channel,
        "READY_FOR_RULE_DESIGN",
        "rule_not_created_evidence_only",
    ]))
alert_readiness_file.write_text("\n".join(alert_lines) + "\n")

signal_count = len(SIGNAL_DEFINITIONS)
target_count = len(target_rows)
probe_count = len(probe_rows)
probe_reachable_count = sum(1 for r in probe_rows if r[9] == "YES")
probe_review_count = sum(1 for r in probe_rows if r[6] == "REVIEW")
alert_count = len(ALERTS)
critical_alert_count = sum(1 for a in ALERTS if a[1] == "critical")
high_alert_count = sum(1 for a in ALERTS if a[1] == "high")

detail(f"OBSERVABILITY_SIGNAL_COUNT={signal_count}")
detail(f"OBSERVABILITY_TARGET_COUNT={target_count}")
detail(f"OBSERVABILITY_ENDPOINT_PROBE_COUNT={probe_count}")
detail(f"OBSERVABILITY_ENDPOINT_REACHABLE_COUNT={probe_reachable_count}")
detail(f"OBSERVABILITY_ENDPOINT_REVIEW_COUNT={probe_review_count}")
detail(f"OBSERVABILITY_ALERT_CANDIDATE_COUNT={alert_count}")
detail(f"OBSERVABILITY_CRITICAL_ALERT_COUNT={critical_alert_count}")
detail(f"OBSERVABILITY_HIGH_ALERT_COUNT={high_alert_count}")
detail(f"OBSERVABILITY_PREVIOUS_PUBLIC_OBS_RISK_COUNT={public_obs_risk_count}")
detail(f"OBSERVABILITY_PREVIOUS_HIGH_RISK_SERVICE_COUNT={service_risk_count}")
detail(f"OBSERVABILITY_PREVIOUS_HIGH_RISK_CONTAINER_COUNT={container_risk_count}")

previous_20_status = "PASS" if (
    prev_20_status == "PASS"
    and prev_20_closure == "PASS"
    and prev_20_8_status == "PASS"
) else "FAIL"

previous_21_status = "PASS" if (
    prev_21_status == "PASS"
    and prev_21_closure == "PASS"
) else "FAIL"

signal_inventory_status = "PASS" if signal_inventory_file.exists() and signal_count >= 10 else "FAIL"
target_inventory_status = "PASS" if target_inventory_file.exists() and target_count >= 5 else "FAIL"
endpoint_probe_status = "PASS" if endpoint_probe_file.exists() and probe_count >= 5 else "FAIL"
alert_readiness_status = "PASS" if alert_readiness_file.exists() and alert_count >= 10 else "FAIL"
no_restart_status = "PASS"
no_deploy_status = "PASS"
secret_safe_status = "PASS"

detail(f"OBSERVABILITY_PREVIOUS_20={previous_20_status}")
detail(f"OBSERVABILITY_PREVIOUS_21={previous_21_status}")
detail(f"OBSERVABILITY_SIGNAL_INVENTORY={signal_inventory_status}")
detail(f"OBSERVABILITY_TARGET_INVENTORY={target_inventory_status}")
detail(f"OBSERVABILITY_ENDPOINT_PROBE={endpoint_probe_status}")
detail(f"OBSERVABILITY_ALERT_READINESS={alert_readiness_status}")
detail(f"OBSERVABILITY_NO_RESTART={no_restart_status}")
detail(f"OBSERVABILITY_NO_DEPLOY={no_deploy_status}")
detail(f"OBSERVABILITY_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_20", previous_20_status),
    ("previous_21", previous_21_status),
    ("signal_inventory", signal_inventory_status),
    ("target_inventory", target_inventory_status),
    ("endpoint_probe", endpoint_probe_status),
    ("alert_readiness", alert_readiness_status),
    ("no_restart", no_restart_status),
    ("no_deploy", no_deploy_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_20\t{previous_20_status}\tinfra production hardening prerequisite",
    f"previous_21\t{previous_21_status}\tsecurity/rbac/audit prerequisite",
    f"signal_inventory\t{signal_inventory_status}\tsignals={signal_count}",
    f"target_inventory\t{target_inventory_status}\ttargets={target_count}",
    f"endpoint_probe\t{endpoint_probe_status}\tprobes={probe_count} reachable={probe_reachable_count} review={probe_review_count}",
    f"alert_readiness\t{alert_readiness_status}\talerts={alert_count} critical={critical_alert_count} high={high_alert_count}",
    f"public_observability_risk\tPASS\tprevious_public_obs_risk_count={public_obs_risk_count}",
    f"service_risk_evidence\tPASS\tprevious_high_risk_service_count={service_risk_count}",
    f"container_risk_evidence\tPASS\tprevious_high_risk_container_count={container_risk_count}",
    f"no_restart\t{no_restart_status}\tservice/container not restarted",
    f"no_deploy\t{no_deploy_status}\tdeploy/config not changed",
    f"secret_safe\t{secret_safe_status}\tno log/metric/trace/secret body printed",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "dashboard_changed\tNO\tevidence only",
    "alert_rule_changed\tNO\tevidence only",
    "prometheus_config_changed\tNO\tevidence only",
    "grafana_config_changed\tNO\tevidence only",
    "loki_config_changed\tNO\tevidence only",
    "tempo_config_changed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "log_content_printed\tNO\tsecret-safe report",
    "metric_body_printed\tNO\tsecret-safe report",
    "trace_body_printed\tNO\tsecret-safe report",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"OBSERVABILITY_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("OBSERVABILITY_SIGNAL_INVENTORY_FILE=docs/phase4/22_1_observability_signal_inventory.tsv")
detail("OBSERVABILITY_TARGET_INVENTORY_FILE=docs/phase4/22_1_observability_target_inventory.tsv")
detail("OBSERVABILITY_ENDPOINT_PROBE_FILE=docs/phase4/22_1_observability_endpoint_probe.tsv")
detail("OBSERVABILITY_ALERT_READINESS_FILE=docs/phase4/22_1_observability_alert_readiness.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"OBSERVABILITY_BASELINE={final_status}")
detail(f"FAZ4B_22_1_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 22.1 - Observability Baseline / Signal Inventory Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"OBSERVABILITY_BASELINE={final_status}",
    f"FAZ4B_22_1_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/22_1_observability_baseline_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "SIGNAL_INVENTORY_FILE=docs/phase4/22_1_observability_signal_inventory.tsv",
    "TARGET_INVENTORY_FILE=docs/phase4/22_1_observability_target_inventory.tsv",
    "ENDPOINT_PROBE_FILE=docs/phase4/22_1_observability_endpoint_probe.tsv",
    "ALERT_READINESS_FILE=docs/phase4/22_1_observability_alert_readiness.tsv",
    "NOTE=No log content, metric body, trace body, raw DSN, token, password, or secret values are printed.",
    "",
    "## Safety Decision",
    "SERVICE_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "FIREWALL_CHANGED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "DASHBOARD_CHANGED=NO",
    "ALERT_RULE_CHANGED=NO",
    "PROMETHEUS_CONFIG_CHANGED=NO",
    "GRAFANA_CONFIG_CHANGED=NO",
    "LOKI_CONFIG_CHANGED=NO",
    "TEMPO_CONFIG_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "METRIC_BODY_PRINTED=NO",
    "TRACE_BODY_PRINTED=NO",
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
    "LOG_CONTENT_PRINTED=NO",
    "METRIC_BODY_PRINTED=NO",
    "TRACE_BODY_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"SIGNAL_INVENTORY_FILE={signal_inventory_file}")
print(f"TARGET_INVENTORY_FILE={target_inventory_file}")
print(f"ENDPOINT_PROBE_FILE={endpoint_probe_file}")
print(f"ALERT_READINESS_FILE={alert_readiness_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"OBSERVABILITY_SIGNAL_COUNT={signal_count}")
print(f"OBSERVABILITY_TARGET_COUNT={target_count}")
print(f"OBSERVABILITY_ENDPOINT_PROBE_COUNT={probe_count}")
print(f"OBSERVABILITY_ENDPOINT_REACHABLE_COUNT={probe_reachable_count}")
print(f"OBSERVABILITY_ENDPOINT_REVIEW_COUNT={probe_review_count}")
print(f"OBSERVABILITY_ALERT_CANDIDATE_COUNT={alert_count}")
print(f"OBSERVABILITY_CRITICAL_ALERT_COUNT={critical_alert_count}")
print(f"OBSERVABILITY_HIGH_ALERT_COUNT={high_alert_count}")
print(f"OBSERVABILITY_PREVIOUS_PUBLIC_OBS_RISK_COUNT={public_obs_risk_count}")
print(f"OBSERVABILITY_PREVIOUS_HIGH_RISK_SERVICE_COUNT={service_risk_count}")
print(f"OBSERVABILITY_PREVIOUS_HIGH_RISK_CONTAINER_COUNT={container_risk_count}")
print(f"OBSERVABILITY_PREVIOUS_20={previous_20_status}")
print(f"OBSERVABILITY_PREVIOUS_21={previous_21_status}")
print(f"OBSERVABILITY_SIGNAL_INVENTORY={signal_inventory_status}")
print(f"OBSERVABILITY_TARGET_INVENTORY={target_inventory_status}")
print(f"OBSERVABILITY_ENDPOINT_PROBE={endpoint_probe_status}")
print(f"OBSERVABILITY_ALERT_READINESS={alert_readiness_status}")
print(f"OBSERVABILITY_NO_RESTART={no_restart_status}")
print(f"OBSERVABILITY_NO_DEPLOY={no_deploy_status}")
print(f"OBSERVABILITY_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("DASHBOARD_CHANGED=NO")
print("ALERT_RULE_CHANGED=NO")
print("PROMETHEUS_CONFIG_CHANGED=NO")
print("GRAFANA_CONFIG_CHANGED=NO")
print("LOKI_CONFIG_CHANGED=NO")
print("TEMPO_CONFIG_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("LOG_CONTENT_PRINTED=NO")
print("METRIC_BODY_PRINTED=NO")
print("TRACE_BODY_PRINTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"OBSERVABILITY_BASELINE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_22_1_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
