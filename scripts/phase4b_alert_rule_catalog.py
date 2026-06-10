#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "22_5_alert_rule_catalog_standard.md"
policy_file = report_dir / "22_5_alert_rule_catalog_policy.md"
alert_catalog_file = report_dir / "22_5_alert_rule_catalog.tsv"
severity_matrix_file = report_dir / "22_5_alert_severity_matrix.tsv"
signal_mapping_file = report_dir / "22_5_alert_signal_mapping.tsv"
escalation_matrix_file = report_dir / "22_5_alert_escalation_matrix.tsv"
matrix_file = report_dir / "22_5_alert_rule_catalog_matrix.tsv"
report_file = report_dir / "22_5_alert_rule_catalog_report.md"

prev_22_4 = report_dir / "22_4_traces_tempo_readiness_report.md"
prev_22_4_signal_contract = report_dir / "22_4_trace_signal_contract.tsv"
prev_22_4_public = report_dir / "22_4_trace_public_surface_policy.tsv"
prev_22_3 = report_dir / "22_3_logs_loki_readiness_report.md"
prev_22_3_public = report_dir / "22_3_logs_public_surface_policy.tsv"
prev_22_2 = report_dir / "22_2_metrics_scrape_readiness_report.md"
prev_22_2_public = report_dir / "22_2_metrics_public_surface_policy.tsv"
prev_22_1 = report_dir / "22_1_observability_baseline_report.md"
prev_22_1_alerts = report_dir / "22_1_observability_alert_readiness.tsv"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

ALERTS = [
    ("service_down", "runtime", "service_health", "CRITICAL", "service active_state != active", "status != active", "1m", "platform_ops", "ops_console,sms_or_phone", "L1_immediate", "runbooks/service_down.md"),
    ("container_down", "runtime", "container_health", "CRITICAL", "container not running", "running=false", "1m", "platform_ops", "ops_console,sms_or_phone", "L1_immediate", "runbooks/container_down.md"),
    ("prometheus_target_down", "metrics", "prometheus_targets", "HIGH", "scrape target down", "up == 0", "2m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/prometheus_target_down.md"),
    ("loki_not_ready", "logs", "loki_ready", "HIGH", "Loki readiness failed", "ready != 200", "2m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/loki_not_ready.md"),
    ("tempo_not_ready", "traces", "tempo_ready", "HIGH", "Tempo readiness failed", "ready != 200", "2m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/tempo_not_ready.md"),
    ("otel_unreachable", "traces", "otel_reachability", "HIGH", "OTEL collector unreachable", "tcp/http unreachable", "2m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/otel_unreachable.md"),
    ("public_surface_risk", "security", "public_surface_policy", "CRITICAL", "internal service exposed publicly", "public_internal_port_count > 0", "0m", "security_ops", "ops_console,sms_or_phone", "L1_immediate", "runbooks/public_surface_risk.md"),
    ("db_connection_error", "database", "db_health", "CRITICAL", "DB connection failures", "db_error_count > 0", "1m", "database_ops", "ops_console,sms_or_phone", "L1_immediate", "runbooks/db_connection_error.md"),
    ("event_bus_backlog_high", "event_bus", "queue_backlog", "HIGH", "event bus backlog high", "backlog > threshold", "5m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/event_bus_backlog_high.md"),
    ("dlq_growth", "event_bus", "dlq_signal", "HIGH", "DLQ growth detected", "dlq_count increase", "5m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/dlq_growth.md"),
    ("api_error_rate_high", "api", "api_gateway_health", "HIGH", "API 5xx/error rate high", "error_rate > threshold", "5m", "api_ops", "ops_console,chat,email", "L2_fast", "runbooks/api_error_rate_high.md"),
    ("latency_high", "api", "latency_signal", "MEDIUM", "p95/p99 latency high", "latency > threshold", "10m", "api_ops", "ops_console,chat", "L3_watch", "runbooks/latency_high.md"),
    ("disk_usage_high", "infra", "host_metrics", "HIGH", "disk usage high", "disk_usage > threshold", "10m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/disk_usage_high.md"),
    ("memory_high", "infra", "host_metrics", "MEDIUM", "memory usage high", "memory_usage > threshold", "10m", "platform_ops", "ops_console,chat", "L3_watch", "runbooks/memory_high.md"),
    ("cpu_high", "infra", "host_metrics", "MEDIUM", "cpu saturation high", "cpu_usage > threshold", "10m", "platform_ops", "ops_console,chat", "L3_watch", "runbooks/cpu_high.md"),
    ("backup_stale", "backup", "backup_archive", "HIGH", "backup/restore drill stale", "last_success_age > threshold", "30m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/backup_stale.md"),
    ("secret_leak_attempt", "security", "tenant_security_observability", "CRITICAL", "secret/token leak signal", "secret_pattern_detected", "0m", "security_ops", "ops_console,sms_or_phone", "L1_immediate", "runbooks/secret_leak_attempt.md"),
    ("audit_gap", "security", "audit_signal", "HIGH", "audit gap detected", "audit_missing_count > 0", "5m", "security_ops", "ops_console,chat,email", "L2_fast", "runbooks/audit_gap.md"),
    ("tenant_isolation_violation", "security", "tenant_security_observability", "CRITICAL", "tenant boundary violation signal", "tenant_mismatch > 0", "0m", "security_ops", "ops_console,sms_or_phone", "L1_immediate", "runbooks/tenant_isolation_violation.md"),
    ("rate_limit_anomaly", "api", "gateway_rate_limit", "MEDIUM", "rate limit anomaly", "rate_limit_hit spike", "10m", "api_ops", "ops_console,chat", "L3_watch", "runbooks/rate_limit_anomaly.md"),
    ("redis_unreachable", "cache", "redis_health", "HIGH", "Redis unreachable", "redis_health != ok", "2m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/redis_unreachable.md"),
    ("postgres_replica_lag", "database", "db_replica_health", "HIGH", "read replica lag high", "replica_lag > threshold", "5m", "database_ops", "ops_console,chat,email", "L2_fast", "runbooks/postgres_replica_lag.md"),
    ("nats_unreachable", "event_bus", "event_bus_health", "HIGH", "NATS unavailable", "nats_health != ok", "2m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/nats_unreachable.md"),
    ("health_endpoint_down", "service", "service_health", "HIGH", "service health endpoint down", "health_status != 200", "2m", "platform_ops", "ops_console,chat,email", "L2_fast", "runbooks/health_endpoint_down.md"),
]

SEVERITY = [
    ("CRITICAL", "system_down_or_security_or_data_loss", "immediate", "L1_immediate", "ops_console + phone/sms + chat", "0-5m", "incident_record_required"),
    ("HIGH", "soon_user_impact_or_data_pipeline_risk", "fast", "L2_fast", "ops_console + chat + email", "5-15m", "incident_or_task_required"),
    ("MEDIUM", "performance_or_capacity_watch", "watch", "L3_watch", "ops_console + chat", "15-60m", "task_or_review_required"),
    ("LOW", "hygiene_or_information", "normal", "L4_review", "ops_console only", "daily/weekly", "review_required"),
]

ESCALATION = [
    ("L1_immediate", "critical", "0m", "5m", "owner + founder/operator", "phone/sms/chat", "incident_open_required"),
    ("L2_fast", "high", "5m", "15m", "owner + platform_ops", "chat/email", "incident_or_task_required"),
    ("L3_watch", "medium", "15m", "60m", "owner team", "ops_console/chat", "task_or_review_required"),
    ("L4_review", "low", "daily", "weekly", "owner team", "ops_console", "backlog_review"),
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
    return v[:260]

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

def build_signal_mapping():
    rows = []

    prev_alerts = parse_tsv(prev_22_1_alerts)
    previous_alert_names = set([r.get("alert_name", "") for r in prev_alerts])

    trace_contract_rows = parse_tsv(prev_22_4_signal_contract)
    trace_contract_count = len(trace_contract_rows)

    public_metrics_rows = parse_tsv(prev_22_2_public)
    public_logs_rows = parse_tsv(prev_22_3_public)
    public_traces_rows = parse_tsv(prev_22_4_public)

    public_surface_risk_count = sum(1 for r in public_metrics_rows + public_logs_rows + public_traces_rows if r.get("risk", "") == "HIGH")

    for alert in ALERTS:
        alert_name, category, signal_source, severity, condition_hint, threshold_hint, duration_hint, owner, channel, escalation, runbook = alert

        previous_22_1_present = "YES" if alert_name in previous_alert_names else "NO"
        evidence_source = "catalog_defined"

        if alert_name in ["public_surface_risk"]:
            evidence_source = f"public_surface_risk_count={public_surface_risk_count}"

        if alert_name in ["tempo_not_ready", "otel_unreachable"]:
            evidence_source = f"trace_contract_count={trace_contract_count}"

        rows.append([
            alert_name,
            signal_source,
            category,
            severity,
            evidence_source,
            previous_22_1_present,
            "READY_FOR_RULE_DESIGN",
            "metadata_only",
        ])

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
detail("PROMETHEUS_CONFIG_CHANGED=NO")
detail("PROMETHEUS_RELOAD_EXECUTED=NO")
detail("PROMETHEUS_RESTARTED=NO")
detail("ALERTMANAGER_CONFIG_CHANGED=NO")
detail("ALERTMANAGER_RELOAD_EXECUTED=NO")
detail("ALERTMANAGER_RESTARTED=NO")
detail("GRAFANA_DASHBOARD_CHANGED=NO")
detail("GRAFANA_ALERT_CHANGED=NO")
detail("ALERT_RULE_CHANGED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("METRIC_BODY_PRINTED=NO")
detail("LOG_CONTENT_PRINTED=NO")
detail("TRACE_BODY_PRINTED=NO")
detail("PROMETHEUS_QUERY_BODY_PRINTED=NO")
detail("LOKI_QUERY_BODY_PRINTED=NO")
detail("TEMPO_QUERY_BODY_PRINTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=ALERT_RULE_CATALOG_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_22_4_status = get_value(prev_22_4, "FAZ4B_22_4_FINAL_STATUS")
prev_22_4_gate = get_value(prev_22_4, "TRACES_TEMPO_READINESS")
prev_22_4_no_restart = get_value(prev_22_4, "SERVICE_RESTARTED")
prev_22_4_secret = get_value(prev_22_4, "SECRET_VALUE_PRINTED")
prev_22_3_status = get_value(prev_22_3, "FAZ4B_22_3_FINAL_STATUS")
prev_22_2_status = get_value(prev_22_2, "FAZ4B_22_2_FINAL_STATUS")
prev_22_1_status = get_value(prev_22_1, "FAZ4B_22_1_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_22_4_FINAL_STATUS={prev_22_4_status}")
detail(f"PREVIOUS_22_4_TRACES_TEMPO_READINESS={prev_22_4_gate}")
detail(f"PREVIOUS_22_4_SERVICE_RESTARTED={prev_22_4_no_restart}")
detail(f"PREVIOUS_22_4_SECRET_VALUE_PRINTED={prev_22_4_secret}")
detail(f"PREVIOUS_22_3_FINAL_STATUS={prev_22_3_status}")
detail(f"PREVIOUS_22_2_FINAL_STATUS={prev_22_2_status}")
detail(f"PREVIOUS_22_1_FINAL_STATUS={prev_22_1_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_22_4_status != "PASS":
    fail("22.4 final status PASS degil")
if prev_22_4_gate != "PASS":
    fail("22.4 traces tempo readiness PASS degil")
if prev_22_4_no_restart != "NO":
    fail("22.4 service restarted NO degil")
if prev_22_4_secret != "NO":
    fail("22.4 secret printed NO degil")
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

catalog_lines = [
    "alert_name\tcategory\tsignal_source\tseverity\tcondition_hint\tthreshold_hint\tduration_hint\towner\tchannel\tescalation_level\trunbook_placeholder\timplementation_status\tnote"
]
for alert in ALERTS:
    catalog_lines.append("\t".join([safe(x) for x in list(alert) + ["READY_FOR_RULE_DESIGN", "rule_not_created_evidence_only"]]))
alert_catalog_file.write_text("\n".join(catalog_lines) + "\n")

severity_lines = [
    "severity\tmeaning\turgency\tescalation_level\tdefault_channel\tresponse_target\trecord_policy"
]
for row in SEVERITY:
    severity_lines.append("\t".join([safe(x) for x in row]))
severity_matrix_file.write_text("\n".join(severity_lines) + "\n")

mapping_rows = build_signal_mapping()
mapping_lines = [
    "alert_name\tsignal_source\tcategory\tseverity\tevidence_source\tprevious_22_1_present\treadiness_status\tnote"
]
for row in mapping_rows:
    mapping_lines.append("\t".join([safe(x) for x in row]))
signal_mapping_file.write_text("\n".join(mapping_lines) + "\n")

escalation_lines = [
    "escalation_level\tseverity_scope\tfirst_notify_after\tescalate_after\ttarget_owner\tchannels\trecord_policy"
]
for row in ESCALATION:
    escalation_lines.append("\t".join([safe(x) for x in row]))
escalation_matrix_file.write_text("\n".join(escalation_lines) + "\n")

alert_count = len(ALERTS)
critical_alert_count = sum(1 for a in ALERTS if a[3] == "CRITICAL")
high_alert_count = sum(1 for a in ALERTS if a[3] == "HIGH")
medium_alert_count = sum(1 for a in ALERTS if a[3] == "MEDIUM")
low_alert_count = sum(1 for a in ALERTS if a[3] == "LOW")
security_alert_count = sum(1 for a in ALERTS if a[1] == "security")
runtime_alert_count = sum(1 for a in ALERTS if a[1] in ["runtime", "service"])
db_alert_count = sum(1 for a in ALERTS if a[1] == "database")
event_alert_count = sum(1 for a in ALERTS if a[1] == "event_bus")
obs_alert_count = sum(1 for a in ALERTS if a[1] in ["metrics", "logs", "traces"])
runbook_count = sum(1 for a in ALERTS if a[10].startswith("runbooks/"))

severity_count = len(SEVERITY)
escalation_count = len(ESCALATION)
mapping_count = len(mapping_rows)
mapped_ready_count = sum(1 for r in mapping_rows if r[6] == "READY_FOR_RULE_DESIGN")

detail(f"ALERT_RULE_COUNT={alert_count}")
detail(f"ALERT_CRITICAL_COUNT={critical_alert_count}")
detail(f"ALERT_HIGH_COUNT={high_alert_count}")
detail(f"ALERT_MEDIUM_COUNT={medium_alert_count}")
detail(f"ALERT_LOW_COUNT={low_alert_count}")
detail(f"ALERT_SECURITY_COUNT={security_alert_count}")
detail(f"ALERT_RUNTIME_COUNT={runtime_alert_count}")
detail(f"ALERT_DB_COUNT={db_alert_count}")
detail(f"ALERT_EVENT_BUS_COUNT={event_alert_count}")
detail(f"ALERT_OBSERVABILITY_COUNT={obs_alert_count}")
detail(f"ALERT_RUNBOOK_PLACEHOLDER_COUNT={runbook_count}")
detail(f"ALERT_SEVERITY_MATRIX_COUNT={severity_count}")
detail(f"ALERT_ESCALATION_MATRIX_COUNT={escalation_count}")
detail(f"ALERT_SIGNAL_MAPPING_COUNT={mapping_count}")
detail(f"ALERT_SIGNAL_MAPPING_READY_COUNT={mapped_ready_count}")

previous_22_4_status = "PASS" if (
    prev_22_4_status == "PASS"
    and prev_22_4_gate == "PASS"
    and prev_22_4_no_restart == "NO"
    and prev_22_4_secret == "NO"
) else "FAIL"

rule_inventory_status = "PASS" if alert_catalog_file.exists() and alert_count >= 15 else "FAIL"
severity_matrix_status = "PASS" if severity_matrix_file.exists() and severity_count >= 4 else "FAIL"
signal_mapping_status = "PASS" if signal_mapping_file.exists() and mapping_count == alert_count else "FAIL"
escalation_matrix_status = "PASS" if escalation_matrix_file.exists() and escalation_count >= 4 else "FAIL"
runbook_placeholder_status = "PASS" if runbook_count == alert_count else "FAIL"
no_config_change_status = "PASS"
no_restart_status = "PASS"
body_not_printed_status = "PASS"
secret_safe_status = "PASS"

detail(f"ALERT_PREVIOUS_22_4={previous_22_4_status}")
detail(f"ALERT_RULE_INVENTORY={rule_inventory_status}")
detail(f"ALERT_SEVERITY_MATRIX={severity_matrix_status}")
detail(f"ALERT_SIGNAL_MAPPING={signal_mapping_status}")
detail(f"ALERT_ESCALATION_MATRIX={escalation_matrix_status}")
detail(f"ALERT_RUNBOOK_PLACEHOLDER={runbook_placeholder_status}")
detail(f"ALERT_NO_CONFIG_CHANGE={no_config_change_status}")
detail(f"ALERT_NO_RESTART={no_restart_status}")
detail(f"ALERT_BODY_NOT_PRINTED={body_not_printed_status}")
detail(f"ALERT_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_22_4", previous_22_4_status),
    ("rule_inventory", rule_inventory_status),
    ("severity_matrix", severity_matrix_status),
    ("signal_mapping", signal_mapping_status),
    ("escalation_matrix", escalation_matrix_status),
    ("runbook_placeholder", runbook_placeholder_status),
    ("no_config_change", no_config_change_status),
    ("no_restart", no_restart_status),
    ("body_not_printed", body_not_printed_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_22_4\t{previous_22_4_status}\ttraces/tempo readiness prerequisite",
    f"alert_rule_inventory\t{rule_inventory_status}\talerts={alert_count} critical={critical_alert_count} high={high_alert_count} medium={medium_alert_count}",
    f"severity_matrix\t{severity_matrix_status}\tseverity_rows={severity_count}",
    f"signal_mapping\t{signal_mapping_status}\tmapped={mapping_count} ready={mapped_ready_count}",
    f"escalation_matrix\t{escalation_matrix_status}\tescalation_rows={escalation_count}",
    f"runbook_placeholder\t{runbook_placeholder_status}\trunbook_placeholders={runbook_count}",
    f"security_alerts\tPASS\tcount={security_alert_count}",
    f"runtime_alerts\tPASS\tcount={runtime_alert_count}",
    f"db_alerts\tPASS\tcount={db_alert_count}",
    f"event_bus_alerts\tPASS\tcount={event_alert_count}",
    f"observability_alerts\tPASS\tcount={obs_alert_count}",
    f"body_not_printed\t{body_not_printed_status}\tmetric/log/trace/query body not printed",
    f"no_config_change\t{no_config_change_status}\talert/prometheus/grafana config not changed",
    f"no_restart\t{no_restart_status}\tservice/container not restarted",
    f"secret_safe\t{secret_safe_status}\tsecret values not printed",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "port_changed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "prometheus_config_changed\tNO\tevidence only",
    "prometheus_reload_executed\tNO\tevidence only",
    "prometheus_restarted\tNO\tevidence only",
    "alertmanager_config_changed\tNO\tevidence only",
    "alertmanager_reload_executed\tNO\tevidence only",
    "alertmanager_restarted\tNO\tevidence only",
    "grafana_dashboard_changed\tNO\tevidence only",
    "grafana_alert_changed\tNO\tevidence only",
    "alert_rule_changed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "metric_body_printed\tNO\tsecret-safe report",
    "log_content_printed\tNO\tsecret-safe report",
    "trace_body_printed\tNO\tsecret-safe report",
    "prometheus_query_body_printed\tNO\tsecret-safe report",
    "loki_query_body_printed\tNO\tsecret-safe report",
    "tempo_query_body_printed\tNO\tsecret-safe report",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"ALERT_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("ALERT_RULE_CATALOG_FILE=docs/phase4/22_5_alert_rule_catalog.tsv")
detail("ALERT_SEVERITY_MATRIX_FILE=docs/phase4/22_5_alert_severity_matrix.tsv")
detail("ALERT_SIGNAL_MAPPING_FILE=docs/phase4/22_5_alert_signal_mapping.tsv")
detail("ALERT_ESCALATION_MATRIX_FILE=docs/phase4/22_5_alert_escalation_matrix.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"ALERT_RULE_CATALOG={final_status}")
detail(f"FAZ4B_22_5_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 22.5 - Alert Rule Catalog / Severity Matrix Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"ALERT_RULE_CATALOG={final_status}",
    f"FAZ4B_22_5_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/22_5_alert_rule_catalog_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "ALERT_RULE_CATALOG_FILE=docs/phase4/22_5_alert_rule_catalog.tsv",
    "ALERT_SEVERITY_MATRIX_FILE=docs/phase4/22_5_alert_severity_matrix.tsv",
    "ALERT_SIGNAL_MAPPING_FILE=docs/phase4/22_5_alert_signal_mapping.tsv",
    "ALERT_ESCALATION_MATRIX_FILE=docs/phase4/22_5_alert_escalation_matrix.tsv",
    "NOTE=Alert rules are cataloged only. No Prometheus/Alertmanager/Grafana config is changed.",
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
    "PROMETHEUS_CONFIG_CHANGED=NO",
    "PROMETHEUS_RELOAD_EXECUTED=NO",
    "PROMETHEUS_RESTARTED=NO",
    "ALERTMANAGER_CONFIG_CHANGED=NO",
    "ALERTMANAGER_RELOAD_EXECUTED=NO",
    "ALERTMANAGER_RESTARTED=NO",
    "GRAFANA_DASHBOARD_CHANGED=NO",
    "GRAFANA_ALERT_CHANGED=NO",
    "ALERT_RULE_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "METRIC_BODY_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "TRACE_BODY_PRINTED=NO",
    "PROMETHEUS_QUERY_BODY_PRINTED=NO",
    "LOKI_QUERY_BODY_PRINTED=NO",
    "TEMPO_QUERY_BODY_PRINTED=NO",
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
    "PROMETHEUS_QUERY_BODY_PRINTED=NO",
    "LOKI_QUERY_BODY_PRINTED=NO",
    "TEMPO_QUERY_BODY_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"ALERT_RULE_CATALOG_FILE={alert_catalog_file}")
print(f"ALERT_SEVERITY_MATRIX_FILE={severity_matrix_file}")
print(f"ALERT_SIGNAL_MAPPING_FILE={signal_mapping_file}")
print(f"ALERT_ESCALATION_MATRIX_FILE={escalation_matrix_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"ALERT_RULE_COUNT={alert_count}")
print(f"ALERT_CRITICAL_COUNT={critical_alert_count}")
print(f"ALERT_HIGH_COUNT={high_alert_count}")
print(f"ALERT_MEDIUM_COUNT={medium_alert_count}")
print(f"ALERT_LOW_COUNT={low_alert_count}")
print(f"ALERT_SECURITY_COUNT={security_alert_count}")
print(f"ALERT_RUNTIME_COUNT={runtime_alert_count}")
print(f"ALERT_DB_COUNT={db_alert_count}")
print(f"ALERT_EVENT_BUS_COUNT={event_alert_count}")
print(f"ALERT_OBSERVABILITY_COUNT={obs_alert_count}")
print(f"ALERT_RUNBOOK_PLACEHOLDER_COUNT={runbook_count}")
print(f"ALERT_SEVERITY_MATRIX_COUNT={severity_count}")
print(f"ALERT_ESCALATION_MATRIX_COUNT={escalation_count}")
print(f"ALERT_SIGNAL_MAPPING_COUNT={mapping_count}")
print(f"ALERT_SIGNAL_MAPPING_READY_COUNT={mapped_ready_count}")
print(f"ALERT_PREVIOUS_22_4={previous_22_4_status}")
print(f"ALERT_RULE_INVENTORY={rule_inventory_status}")
print(f"ALERT_SEVERITY_MATRIX={severity_matrix_status}")
print(f"ALERT_SIGNAL_MAPPING={signal_mapping_status}")
print(f"ALERT_ESCALATION_MATRIX={escalation_matrix_status}")
print(f"ALERT_RUNBOOK_PLACEHOLDER={runbook_placeholder_status}")
print(f"ALERT_NO_CONFIG_CHANGE={no_config_change_status}")
print(f"ALERT_NO_RESTART={no_restart_status}")
print(f"ALERT_BODY_NOT_PRINTED={body_not_printed_status}")
print(f"ALERT_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("PROMETHEUS_CONFIG_CHANGED=NO")
print("PROMETHEUS_RELOAD_EXECUTED=NO")
print("PROMETHEUS_RESTARTED=NO")
print("ALERTMANAGER_CONFIG_CHANGED=NO")
print("ALERTMANAGER_RELOAD_EXECUTED=NO")
print("ALERTMANAGER_RESTARTED=NO")
print("GRAFANA_DASHBOARD_CHANGED=NO")
print("GRAFANA_ALERT_CHANGED=NO")
print("ALERT_RULE_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("METRIC_BODY_PRINTED=NO")
print("LOG_CONTENT_PRINTED=NO")
print("TRACE_BODY_PRINTED=NO")
print("PROMETHEUS_QUERY_BODY_PRINTED=NO")
print("LOKI_QUERY_BODY_PRINTED=NO")
print("TEMPO_QUERY_BODY_PRINTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"ALERT_RULE_CATALOG={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_22_5_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
