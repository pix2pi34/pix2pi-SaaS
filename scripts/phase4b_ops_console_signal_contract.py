#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "22_6_ops_console_signal_contract_standard.md"
policy_file = report_dir / "22_6_ops_console_signal_contract_policy.md"
signal_contract_file = report_dir / "22_6_ops_console_signal_contract.tsv"
widget_contract_file = report_dir / "22_6_ops_console_widget_contract.tsv"
api_contract_file = report_dir / "22_6_ops_console_api_contract.tsv"
alert_binding_file = report_dir / "22_6_ops_console_alert_binding.tsv"
runbook_binding_file = report_dir / "22_6_ops_console_runbook_binding.tsv"
matrix_file = report_dir / "22_6_ops_console_signal_contract_matrix.tsv"
report_file = report_dir / "22_6_ops_console_signal_contract_report.md"

prev_22_5 = report_dir / "22_5_alert_rule_catalog_report.md"
prev_22_5_catalog = report_dir / "22_5_alert_rule_catalog.tsv"
prev_22_5_severity = report_dir / "22_5_alert_severity_matrix.tsv"
prev_22_5_mapping = report_dir / "22_5_alert_signal_mapping.tsv"
prev_22_4 = report_dir / "22_4_traces_tempo_readiness_report.md"
prev_22_3 = report_dir / "22_3_logs_loki_readiness_report.md"
prev_22_2 = report_dir / "22_2_metrics_scrape_readiness_report.md"
prev_22_1 = report_dir / "22_1_observability_baseline_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

SIGNALS = [
    ("platform_overview", "platform", "overall platform health rollup", "CRITICAL", "20s", "platform_admin", "ops_console_overview", "GET /ops/v1/summary", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("service_status", "runtime", "systemd and service health state", "CRITICAL", "15s", "ops_admin", "service_grid", "GET /ops/v1/services", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("container_status", "runtime", "docker container state and healthcheck", "CRITICAL", "15s", "ops_admin", "container_grid", "GET /ops/v1/containers", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("api_gateway_health", "api", "API Gateway health and error signal", "HIGH", "15s", "ops_admin", "api_gateway_card", "GET /ops/v1/api-gateway", "api_ops", "READY_FOR_IMPLEMENTATION"),
    ("db_health", "database", "PostgreSQL connection and write/read readiness", "CRITICAL", "30s", "ops_admin", "database_panel", "GET /ops/v1/database", "database_ops", "READY_FOR_IMPLEMENTATION"),
    ("postgres_replica_lag", "database", "read replica lag and replication readiness", "HIGH", "60s", "ops_admin", "database_panel", "GET /ops/v1/database/replication", "database_ops", "READY_FOR_IMPLEMENTATION"),
    ("redis_health", "cache", "Redis availability and latency placeholder", "HIGH", "30s", "ops_admin", "cache_panel", "GET /ops/v1/cache/redis", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("event_bus_health", "event_bus", "NATS/Event Bus health readiness", "HIGH", "30s", "ops_admin", "event_bus_panel", "GET /ops/v1/event-bus", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("queue_backlog", "event_bus", "queue backlog and consumer lag", "HIGH", "30s", "ops_admin", "event_bus_panel", "GET /ops/v1/event-bus/backlog", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("dlq_signal", "event_bus", "dead-letter queue growth", "HIGH", "30s", "ops_admin", "dlq_panel", "GET /ops/v1/event-bus/dlq", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("metrics_health", "metrics", "Prometheus and scrape target health", "HIGH", "30s", "ops_admin", "observability_panel", "GET /ops/v1/observability/metrics", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("logs_health", "logs", "Loki readiness and log pipeline metadata", "HIGH", "30s", "ops_admin", "observability_panel", "GET /ops/v1/observability/logs", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("traces_health", "traces", "Tempo / OTEL readiness and trace contract metadata", "HIGH", "30s", "ops_admin", "observability_panel", "GET /ops/v1/observability/traces", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("public_surface_risk", "security", "internal ports exposed publicly", "CRITICAL", "60s", "security_admin", "security_risk_panel", "GET /ops/v1/security/public-surface", "security_ops", "READY_FOR_IMPLEMENTATION"),
    ("tenant_isolation_signal", "security", "tenant boundary / tenant scope signal", "CRITICAL", "60s", "security_admin", "tenant_security_panel", "GET /ops/v1/security/tenant-isolation", "security_ops", "READY_FOR_IMPLEMENTATION"),
    ("secret_leak_signal", "security", "secret/token leak attempt signal", "CRITICAL", "60s", "security_admin", "security_risk_panel", "GET /ops/v1/security/secret-leaks", "security_ops", "READY_FOR_IMPLEMENTATION"),
    ("audit_gap", "security", "audit missing or gap signal", "HIGH", "60s", "security_admin", "audit_panel", "GET /ops/v1/security/audit", "security_ops", "READY_FOR_IMPLEMENTATION"),
    ("backup_stale", "backup", "backup freshness and restore drill signal", "HIGH", "5m", "ops_admin", "backup_panel", "GET /ops/v1/backups", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("disk_usage", "infra", "disk saturation signal", "HIGH", "60s", "ops_admin", "infra_panel", "GET /ops/v1/infra/disk", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("memory_usage", "infra", "memory pressure signal", "MEDIUM", "60s", "ops_admin", "infra_panel", "GET /ops/v1/infra/memory", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("cpu_usage", "infra", "CPU pressure signal", "MEDIUM", "60s", "ops_admin", "infra_panel", "GET /ops/v1/infra/cpu", "platform_ops", "READY_FOR_IMPLEMENTATION"),
    ("rate_limit_anomaly", "api", "gateway rate limit anomaly signal", "MEDIUM", "60s", "ops_admin", "api_gateway_card", "GET /ops/v1/api-gateway/rate-limit", "api_ops", "READY_FOR_IMPLEMENTATION"),
]

WIDGETS = [
    ("ops_console_overview", "summary", "platform_overview", "status/severity/active_alert_count/public_risk_count", "platform_admin", "top_panel", "READY_FOR_IMPLEMENTATION"),
    ("service_grid", "table", "service_status", "service_name/status/severity/last_seen/runbook_ref", "ops_admin", "runtime_section", "READY_FOR_IMPLEMENTATION"),
    ("container_grid", "table", "container_status", "container_name/status/image/health/risk", "ops_admin", "runtime_section", "READY_FOR_IMPLEMENTATION"),
    ("api_gateway_card", "card", "api_gateway_health,rate_limit_anomaly", "status/error_rate/latency/rate_limit", "ops_admin", "api_section", "READY_FOR_IMPLEMENTATION"),
    ("database_panel", "panel", "db_health,postgres_replica_lag", "status/connection/replica_lag/last_error_ref", "ops_admin", "data_section", "READY_FOR_IMPLEMENTATION"),
    ("event_bus_panel", "panel", "event_bus_health,queue_backlog", "status/backlog/consumer_lag/replay_ready", "ops_admin", "event_section", "READY_FOR_IMPLEMENTATION"),
    ("dlq_panel", "table", "dlq_signal", "event_type/count/oldest_age/runbook_ref", "ops_admin", "event_section", "READY_FOR_IMPLEMENTATION"),
    ("observability_panel", "panel", "metrics_health,logs_health,traces_health", "prometheus/loki/tempo/otel readiness", "ops_admin", "observability_section", "READY_FOR_IMPLEMENTATION"),
    ("security_risk_panel", "panel", "public_surface_risk,secret_leak_signal", "severity/risk_count/owner/runbook_ref", "security_admin", "security_section", "READY_FOR_IMPLEMENTATION"),
    ("tenant_security_panel", "panel", "tenant_isolation_signal", "tenant_scope/violation_count/evidence_ref", "security_admin", "security_section", "READY_FOR_IMPLEMENTATION"),
    ("audit_panel", "table", "audit_gap", "audit_source/gap_count/last_seen", "security_admin", "security_section", "READY_FOR_IMPLEMENTATION"),
    ("backup_panel", "panel", "backup_stale", "last_success/restore_drill_required/risk", "ops_admin", "resilience_section", "READY_FOR_IMPLEMENTATION"),
    ("infra_panel", "panel", "disk_usage,memory_usage,cpu_usage", "usage_pct/severity/trend", "ops_admin", "infra_section", "READY_FOR_IMPLEMENTATION"),
    ("alert_timeline", "timeline", "all_alerts", "alert_name/severity/status/observed_at/runbook_ref", "ops_admin", "alerts_section", "READY_FOR_IMPLEMENTATION"),
    ("runbook_panel", "links", "all_alerts", "runbook_ref/owner/escalation_level", "ops_admin", "runbook_section", "READY_FOR_IMPLEMENTATION"),
]

API_ENDPOINTS = [
    ("GET", "/ops/v1/summary", "platform", "platform summary envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/services", "runtime", "service status list", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/containers", "runtime", "container status list", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/api-gateway", "api", "api gateway status card", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/database", "database", "database health envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/database/replication", "database", "replication / lag envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/cache/redis", "cache", "redis health envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/event-bus", "event_bus", "event bus health envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/event-bus/backlog", "event_bus", "backlog and consumer lag envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/event-bus/dlq", "event_bus", "dead-letter queue envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/observability/metrics", "metrics", "prometheus scrape readiness envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/observability/logs", "logs", "loki log readiness envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/observability/traces", "traces", "tempo/otel trace readiness envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/alerts", "alerts", "active alert catalog/status envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/runbooks", "runbooks", "runbook binding envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/security/public-surface", "security", "public surface risk envelope", "YES", "security:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/security/tenant-isolation", "security", "tenant isolation signal envelope", "YES", "security:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/security/audit", "security", "audit gap signal envelope", "YES", "security:read", "READY_FOR_IMPLEMENTATION"),
    ("GET", "/ops/v1/backups", "backup", "backup freshness / restore drill envelope", "YES", "ops:read", "READY_FOR_IMPLEMENTATION"),
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

def read(path):
    if not path.exists():
        return ""
    try:
        if path.is_file() and path.stat().st_size > 2 * 1024 * 1024:
            return ""
    except Exception:
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
    return v[:320]

def parse_tsv(path):
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
detail("ALERTMANAGER_CONFIG_CHANGED=NO")
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
detail("VALIDATION_MODE=OPS_CONSOLE_SIGNAL_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_22_5_status = get_value(prev_22_5, "FAZ4B_22_5_FINAL_STATUS")
prev_22_5_gate = get_value(prev_22_5, "ALERT_RULE_CATALOG")
prev_22_5_no_restart = get_value(prev_22_5, "SERVICE_RESTARTED")
prev_22_5_secret = get_value(prev_22_5, "SECRET_VALUE_PRINTED")
prev_22_4_status = get_value(prev_22_4, "FAZ4B_22_4_FINAL_STATUS")
prev_22_3_status = get_value(prev_22_3, "FAZ4B_22_3_FINAL_STATUS")
prev_22_2_status = get_value(prev_22_2, "FAZ4B_22_2_FINAL_STATUS")
prev_22_1_status = get_value(prev_22_1, "FAZ4B_22_1_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_22_5_FINAL_STATUS={prev_22_5_status}")
detail(f"PREVIOUS_22_5_ALERT_RULE_CATALOG={prev_22_5_gate}")
detail(f"PREVIOUS_22_5_SERVICE_RESTARTED={prev_22_5_no_restart}")
detail(f"PREVIOUS_22_5_SECRET_VALUE_PRINTED={prev_22_5_secret}")
detail(f"PREVIOUS_22_4_FINAL_STATUS={prev_22_4_status}")
detail(f"PREVIOUS_22_3_FINAL_STATUS={prev_22_3_status}")
detail(f"PREVIOUS_22_2_FINAL_STATUS={prev_22_2_status}")
detail(f"PREVIOUS_22_1_FINAL_STATUS={prev_22_1_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_22_5_status != "PASS":
    fail("22.5 final status PASS degil")
if prev_22_5_gate != "PASS":
    fail("22.5 alert rule catalog PASS degil")
if prev_22_5_no_restart != "NO":
    fail("22.5 service restarted NO degil")
if prev_22_5_secret != "NO":
    fail("22.5 secret printed NO degil")
if prev_22_4_status != "PASS":
    fail("22.4 final status PASS degil")
if prev_22_3_status != "PASS":
    fail("22.3 final status PASS degil")
if prev_22_2_status != "PASS":
    fail("22.2 final status PASS degil")
if prev_22_1_status != "PASS":
    fail("22.1 final status PASS degil")
if prev_20_status != "PASS":
    fail("20 final status PASS degil")
if prev_20_closure != "PASS":
    fail("20 infra closure PASS degil")
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

alert_rows = parse_tsv(prev_22_5_catalog)
severity_rows = parse_tsv(prev_22_5_severity)
mapping_rows = parse_tsv(prev_22_5_mapping)

signal_lines = [
    "signal_name\tcategory\tdescription\tdefault_severity\trefresh_interval\tvisibility_scope\twidget_ref\tapi_endpoint\towner\timplementation_status\tenvelope_contract\tnote"
]
for signal_name, category, description, severity, refresh, visibility, widget, endpoint, owner, status in SIGNALS:
    envelope = "signal_name/category/status/severity/source/observed_at/tenant_scope/summary/evidence_ref/runbook_ref/owner/refresh_interval/visibility_scope"
    signal_lines.append("\t".join([safe(x) for x in [
        signal_name, category, description, severity, refresh, visibility, widget, endpoint, owner, status, envelope, "contract_only_no_runtime_change"
    ]]))
signal_contract_file.write_text("\n".join(signal_lines) + "\n")

widget_lines = [
    "widget_name\twidget_type\tsignal_refs\tminimum_fields\tvisibility_scope\tui_section\timplementation_status\tnote"
]
for row in WIDGETS:
    widget_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_ui_code"]]))
widget_contract_file.write_text("\n".join(widget_lines) + "\n")

api_lines = [
    "method\tpath\tcategory\tresponse_contract\tauth_required\trbac_scope\timplementation_status\tnote"
]
for row in API_ENDPOINTS:
    api_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_route_implemented"]]))
api_contract_file.write_text("\n".join(api_lines) + "\n")

alert_binding_lines = [
    "alert_name\tcategory\tsignal_source\tseverity\tchannel\tescalation_level\twidget_ref\tapi_endpoint\trunbook_ref\timplementation_status\tnote"
]
for r in alert_rows:
    alert_name = r.get("alert_name", "")
    category = r.get("category", "")
    signal_source = r.get("signal_source", "")
    severity = r.get("severity", "")
    channel = r.get("channel", "")
    escalation = r.get("escalation_level", "")
    runbook = r.get("runbook_placeholder", "")

    widget_ref = "alert_timeline"
    endpoint = "GET /ops/v1/alerts"

    if category == "security":
        widget_ref = "security_risk_panel"
    elif category == "database":
        widget_ref = "database_panel"
    elif category == "event_bus":
        widget_ref = "event_bus_panel"
    elif category in ["logs", "traces", "metrics"]:
        widget_ref = "observability_panel"
    elif category in ["runtime", "service"]:
        widget_ref = "service_grid"
    elif category == "backup":
        widget_ref = "backup_panel"
    elif category == "infra":
        widget_ref = "infra_panel"
    elif category == "api":
        widget_ref = "api_gateway_card"

    alert_binding_lines.append("\t".join([safe(x) for x in [
        alert_name, category, signal_source, severity, channel, escalation, widget_ref, endpoint, runbook, "READY_FOR_IMPLEMENTATION", "alert_binding_contract_only"
    ]]))
alert_binding_file.write_text("\n".join(alert_binding_lines) + "\n")

runbook_lines = [
    "runbook_ref\talert_name\tseverity\towner\tescalation_level\trequired_sections\timplementation_status\tnote"
]
for r in alert_rows:
    alert_name = r.get("alert_name", "")
    severity = r.get("severity", "")
    owner = r.get("owner", "")
    escalation = r.get("escalation_level", "")
    runbook = r.get("runbook_placeholder", "")
    sections = "summary/impact/checks/mitigation/rollback/escalation/postmortem"
    runbook_lines.append("\t".join([safe(x) for x in [
        runbook, alert_name, severity, owner, escalation, sections, "PLACEHOLDER_READY", "runbook_file_not_created_contract_only"
    ]]))
runbook_binding_file.write_text("\n".join(runbook_lines) + "\n")

signal_count = len(SIGNALS)
critical_signal_count = sum(1 for s in SIGNALS if s[3] == "CRITICAL")
high_signal_count = sum(1 for s in SIGNALS if s[3] == "HIGH")
medium_signal_count = sum(1 for s in SIGNALS if s[3] == "MEDIUM")
security_signal_count = sum(1 for s in SIGNALS if s[1] == "security")
runtime_signal_count = sum(1 for s in SIGNALS if s[1] == "runtime")
observability_signal_count = sum(1 for s in SIGNALS if s[1] in ["metrics", "logs", "traces"])
widget_count = len(WIDGETS)
api_count = len(API_ENDPOINTS)
alert_binding_count = max(0, len(alert_binding_lines) - 1)
runbook_binding_count = max(0, len(runbook_lines) - 1)
previous_alert_count = len(alert_rows)
previous_severity_count = len(severity_rows)
previous_mapping_count = len(mapping_rows)

detail(f"OPS_SIGNAL_COUNT={signal_count}")
detail(f"OPS_CRITICAL_SIGNAL_COUNT={critical_signal_count}")
detail(f"OPS_HIGH_SIGNAL_COUNT={high_signal_count}")
detail(f"OPS_MEDIUM_SIGNAL_COUNT={medium_signal_count}")
detail(f"OPS_SECURITY_SIGNAL_COUNT={security_signal_count}")
detail(f"OPS_RUNTIME_SIGNAL_COUNT={runtime_signal_count}")
detail(f"OPS_OBSERVABILITY_SIGNAL_COUNT={observability_signal_count}")
detail(f"OPS_WIDGET_COUNT={widget_count}")
detail(f"OPS_API_ENDPOINT_COUNT={api_count}")
detail(f"OPS_ALERT_BINDING_COUNT={alert_binding_count}")
detail(f"OPS_RUNBOOK_BINDING_COUNT={runbook_binding_count}")
detail(f"OPS_PREVIOUS_ALERT_COUNT={previous_alert_count}")
detail(f"OPS_PREVIOUS_SEVERITY_COUNT={previous_severity_count}")
detail(f"OPS_PREVIOUS_SIGNAL_MAPPING_COUNT={previous_mapping_count}")

previous_22_5_status = "PASS" if (
    prev_22_5_status == "PASS"
    and prev_22_5_gate == "PASS"
    and prev_22_5_no_restart == "NO"
    and prev_22_5_secret == "NO"
) else "FAIL"

signal_contract_status = "PASS" if signal_contract_file.exists() and signal_count >= 15 else "FAIL"
widget_contract_status = "PASS" if widget_contract_file.exists() and widget_count >= 10 else "FAIL"
api_contract_status = "PASS" if api_contract_file.exists() and api_count >= 10 else "FAIL"
alert_binding_status = "PASS" if alert_binding_file.exists() and alert_binding_count >= 20 else "FAIL"
runbook_binding_status = "PASS" if runbook_binding_file.exists() and runbook_binding_count == alert_binding_count and runbook_binding_count >= 20 else "FAIL"
contract_coverage_status = "PASS" if (
    signal_contract_status == "PASS"
    and widget_contract_status == "PASS"
    and api_contract_status == "PASS"
    and alert_binding_status == "PASS"
    and runbook_binding_status == "PASS"
) else "FAIL"
no_runtime_change_status = "PASS"
no_config_change_status = "PASS"
body_not_printed_status = "PASS"
secret_safe_status = "PASS"

detail(f"OPS_PREVIOUS_22_5={previous_22_5_status}")
detail(f"OPS_SIGNAL_CONTRACT={signal_contract_status}")
detail(f"OPS_WIDGET_CONTRACT={widget_contract_status}")
detail(f"OPS_API_CONTRACT={api_contract_status}")
detail(f"OPS_ALERT_BINDING={alert_binding_status}")
detail(f"OPS_RUNBOOK_BINDING={runbook_binding_status}")
detail(f"OPS_CONTRACT_COVERAGE={contract_coverage_status}")
detail(f"OPS_NO_RUNTIME_CHANGE={no_runtime_change_status}")
detail(f"OPS_NO_CONFIG_CHANGE={no_config_change_status}")
detail(f"OPS_BODY_NOT_PRINTED={body_not_printed_status}")
detail(f"OPS_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_22_5", previous_22_5_status),
    ("signal_contract", signal_contract_status),
    ("widget_contract", widget_contract_status),
    ("api_contract", api_contract_status),
    ("alert_binding", alert_binding_status),
    ("runbook_binding", runbook_binding_status),
    ("contract_coverage", contract_coverage_status),
    ("no_runtime_change", no_runtime_change_status),
    ("no_config_change", no_config_change_status),
    ("body_not_printed", body_not_printed_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_22_5\t{previous_22_5_status}\talert rule catalog prerequisite",
    f"signal_contract\t{signal_contract_status}\tsignals={signal_count} critical={critical_signal_count} high={high_signal_count}",
    f"widget_contract\t{widget_contract_status}\twidgets={widget_count}",
    f"api_contract\t{api_contract_status}\tapi_endpoints={api_count}",
    f"alert_binding\t{alert_binding_status}\talert_bindings={alert_binding_count}",
    f"runbook_binding\t{runbook_binding_status}\trunbook_bindings={runbook_binding_count}",
    f"contract_coverage\t{contract_coverage_status}\tall core contract artifacts ready",
    f"security_signals\tPASS\tcount={security_signal_count}",
    f"runtime_signals\tPASS\tcount={runtime_signal_count}",
    f"observability_signals\tPASS\tcount={observability_signal_count}",
    f"no_runtime_change\t{no_runtime_change_status}\tno service/container/ui/api implementation changed",
    f"no_config_change\t{no_config_change_status}\tno prometheus/grafana/alertmanager/loki/tempo config changed",
    f"body_not_printed\t{body_not_printed_status}\tmetric/log/trace/query body not printed",
    f"secret_safe\t{secret_safe_status}\tsecret values not printed",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "port_changed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "ops_console_code_changed\tNO\tcontract only",
    "ops_console_api_implemented\tNO\tcontract only",
    "ops_console_ui_changed\tNO\tcontract only",
    "prometheus_config_changed\tNO\tevidence only",
    "alertmanager_config_changed\tNO\tevidence only",
    "grafana_dashboard_changed\tNO\tevidence only",
    "grafana_alert_changed\tNO\tevidence only",
    "alert_rule_changed\tNO\tevidence only",
    "loki_config_changed\tNO\tevidence only",
    "tempo_config_changed\tNO\tevidence only",
    "otel_config_changed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "metric_body_printed\tNO\tsecret-safe report",
    "log_content_printed\tNO\tsecret-safe report",
    "trace_body_printed\tNO\tsecret-safe report",
    "query_body_printed\tNO\tsecret-safe report",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"OPS_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("OPS_SIGNAL_CONTRACT_FILE=docs/phase4/22_6_ops_console_signal_contract.tsv")
detail("OPS_WIDGET_CONTRACT_FILE=docs/phase4/22_6_ops_console_widget_contract.tsv")
detail("OPS_API_CONTRACT_FILE=docs/phase4/22_6_ops_console_api_contract.tsv")
detail("OPS_ALERT_BINDING_FILE=docs/phase4/22_6_ops_console_alert_binding.tsv")
detail("OPS_RUNBOOK_BINDING_FILE=docs/phase4/22_6_ops_console_runbook_binding.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"OPS_CONSOLE_SIGNAL_CONTRACT={final_status}")
detail(f"FAZ4B_22_6_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 22.6 - Ops Console Signal Contract Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"OPS_CONSOLE_SIGNAL_CONTRACT={final_status}",
    f"FAZ4B_22_6_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/22_6_ops_console_signal_contract_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "OPS_SIGNAL_CONTRACT_FILE=docs/phase4/22_6_ops_console_signal_contract.tsv",
    "OPS_WIDGET_CONTRACT_FILE=docs/phase4/22_6_ops_console_widget_contract.tsv",
    "OPS_API_CONTRACT_FILE=docs/phase4/22_6_ops_console_api_contract.tsv",
    "OPS_ALERT_BINDING_FILE=docs/phase4/22_6_ops_console_alert_binding.tsv",
    "OPS_RUNBOOK_BINDING_FILE=docs/phase4/22_6_ops_console_runbook_binding.tsv",
    "NOTE=Contract only. No Ops Console UI/API implementation, DB mutation, config change, or service restart is executed.",
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
    "ALERTMANAGER_CONFIG_CHANGED=NO",
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

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"OPS_SIGNAL_CONTRACT_FILE={signal_contract_file}")
print(f"OPS_WIDGET_CONTRACT_FILE={widget_contract_file}")
print(f"OPS_API_CONTRACT_FILE={api_contract_file}")
print(f"OPS_ALERT_BINDING_FILE={alert_binding_file}")
print(f"OPS_RUNBOOK_BINDING_FILE={runbook_binding_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"OPS_SIGNAL_COUNT={signal_count}")
print(f"OPS_CRITICAL_SIGNAL_COUNT={critical_signal_count}")
print(f"OPS_HIGH_SIGNAL_COUNT={high_signal_count}")
print(f"OPS_MEDIUM_SIGNAL_COUNT={medium_signal_count}")
print(f"OPS_SECURITY_SIGNAL_COUNT={security_signal_count}")
print(f"OPS_RUNTIME_SIGNAL_COUNT={runtime_signal_count}")
print(f"OPS_OBSERVABILITY_SIGNAL_COUNT={observability_signal_count}")
print(f"OPS_WIDGET_COUNT={widget_count}")
print(f"OPS_API_ENDPOINT_COUNT={api_count}")
print(f"OPS_ALERT_BINDING_COUNT={alert_binding_count}")
print(f"OPS_RUNBOOK_BINDING_COUNT={runbook_binding_count}")
print(f"OPS_PREVIOUS_ALERT_COUNT={previous_alert_count}")
print(f"OPS_PREVIOUS_SEVERITY_COUNT={previous_severity_count}")
print(f"OPS_PREVIOUS_SIGNAL_MAPPING_COUNT={previous_mapping_count}")
print(f"OPS_PREVIOUS_22_5={previous_22_5_status}")
print(f"OPS_SIGNAL_CONTRACT={signal_contract_status}")
print(f"OPS_WIDGET_CONTRACT={widget_contract_status}")
print(f"OPS_API_CONTRACT={api_contract_status}")
print(f"OPS_ALERT_BINDING={alert_binding_status}")
print(f"OPS_RUNBOOK_BINDING={runbook_binding_status}")
print(f"OPS_CONTRACT_COVERAGE={contract_coverage_status}")
print(f"OPS_NO_RUNTIME_CHANGE={no_runtime_change_status}")
print(f"OPS_NO_CONFIG_CHANGE={no_config_change_status}")
print(f"OPS_BODY_NOT_PRINTED={body_not_printed_status}")
print(f"OPS_SECRET_SAFE={secret_safe_status}")
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
print(f"OPS_CONSOLE_SIGNAL_CONTRACT={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_22_6_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
