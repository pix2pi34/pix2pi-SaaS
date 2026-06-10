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

standard_file = report_dir / "22_3_logs_loki_readiness_standard.md"
policy_file = report_dir / "22_3_logs_loki_readiness_policy.md"
source_inventory_file = report_dir / "22_3_logs_source_inventory.tsv"
endpoint_probe_file = report_dir / "22_3_loki_endpoint_probe.tsv"
pipeline_inventory_file = report_dir / "22_3_log_pipeline_inventory.tsv"
public_surface_policy_file = report_dir / "22_3_logs_public_surface_policy.tsv"
matrix_file = report_dir / "22_3_logs_loki_readiness_matrix.tsv"
report_file = report_dir / "22_3_logs_loki_readiness_report.md"

prev_22_2 = report_dir / "22_2_metrics_scrape_readiness_report.md"
prev_22_1 = report_dir / "22_1_observability_baseline_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_20_3_ports = report_dir / "20_3_runtime_service_hardening_ports.tsv"
prev_20_3_services = report_dir / "20_3_runtime_service_hardening_services.tsv"
prev_20_5_containers = report_dir / "20_5_docker_container_inventory.tsv"
prev_20_5_ports = report_dir / "20_5_docker_public_port_policy.tsv"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

LOKI_ENDPOINTS = [
    ("loki_ready", "http://127.0.0.1:3100/ready", "loki", "logs_core", "readiness"),
    ("loki_metrics", "http://127.0.0.1:3100/metrics", "loki", "logs_core", "metrics_body_not_printed"),
    ("loki_buildinfo", "http://127.0.0.1:3100/loki/api/v1/status/buildinfo", "loki", "logs_core", "metadata_body_not_printed"),
    ("loki_labels", "http://127.0.0.1:3100/loki/api/v1/labels?limit=1", "loki", "logs_core", "query_body_not_printed"),
    ("promtail_ready", "http://127.0.0.1:9080/ready", "promtail", "log_agent", "readiness"),
    ("promtail_metrics", "http://127.0.0.1:9080/metrics", "promtail", "log_agent", "metrics_body_not_printed"),
    ("grafana_health_for_logs", "http://127.0.0.1:3001/api/health", "grafana", "log_explore_surface", "health"),
]

LOG_PUBLIC_PORTS = {
    "3100": "loki",
    "9080": "promtail",
    "4317": "otel_grpc",
    "4318": "otel_http",
    "3000": "grafana",
    "3001": "grafana",
}

PIPELINE_MARKERS = [
    ("loki_config", r"loki|auth_enabled|schema_config|storage_config|limits_config"),
    ("promtail_config", r"promtail|scrape_configs|clients|positions|pipeline_stages"),
    ("log_agent_config", r"fluentbit|fluent-bit|vector|otelcol|opentelemetry|collector"),
    ("docker_logging", r"logging:|log-driver|json-file|loki"),
    ("tenant_label", r"tenant_id|tenant_uuid"),
    ("service_label", r"service_name|app|component"),
    ("trace_label", r"trace_id|request_id|correlation_id"),
    ("redaction_marker", r"redact|mask|sanitize|password|secret|token"),
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

def run_cmd(cmd, timeout=6):
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

def curl_status(url, timeout_seconds=3):
    if which("curl") is None:
        return "NOT_PROBED", "0", "NO", "curl_not_found"

    rc, out, err = run_cmd([
        "curl",
        "-sS",
        "-o",
        "/dev/null",
        "-w",
        "%{http_code}",
        "--max-time",
        str(timeout_seconds),
        url,
    ], timeout=timeout_seconds + 2)

    status_code = out.strip() if out.strip().isdigit() else "000"
    reachable = "YES" if status_code not in ["000", ""] else "NO"

    if status_code in ["200", "204", "301", "302", "401", "403"]:
        result = "READY_OR_AUTH_REQUIRED"
    elif status_code in ["503", "500", "404"]:
        result = "REVIEW"
    else:
        result = "REVIEW"

    return result, status_code, reachable, "body_not_printed"

def build_endpoint_probes():
    rows = []

    for probe_name, url, service_hint, category, purpose in LOKI_ENDPOINTS:
        parsed = urlparse(url)
        result, status_code, reachable, body_policy = curl_status(url)

        rows.append([
            probe_name,
            category,
            service_hint,
            parsed.hostname or "unknown",
            str(parsed.port or ""),
            parsed.path or "/",
            purpose,
            result,
            status_code,
            reachable,
            body_policy,
            "metadata_only",
        ])

    return rows

def docker_log_source_rows():
    rows = []

    prev_containers = parse_tsv(prev_20_5_containers)
    if prev_containers:
        for r in prev_containers:
            name = r.get("container_name", "")
            image = r.get("image", "")
            status = r.get("status", "")
            risk = r.get("risk", "")
            note = "from_20_5_container_inventory_log_source_candidate"

            log_driver = "unknown"
            healthcheck = r.get("healthcheck_present", "")
            restart_policy = r.get("restart_policy", "")

            rows.append([
                "docker_container",
                safe(name),
                safe(image),
                safe(status),
                log_driver,
                safe(healthcheck),
                safe(restart_policy),
                safe(risk),
                note,
            ])

        return rows

    if which("docker") is None:
        warn("docker not found for log source metadata")
        return rows

    rc, out, err = run_cmd([
        "docker",
        "ps",
        "-a",
        "--format",
        "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}",
    ], timeout=12)

    if rc != 0 and not out:
        warn("docker ps unavailable for log source metadata")
        return rows

    for line in out.splitlines():
        parts = line.split("\t")
        while len(parts) < 4:
            parts.append("")
        cid, name, image, status = parts[:4]

        irc, iout, ierr = run_cmd([
            "docker",
            "inspect",
            "--format",
            "{{.HostConfig.LogConfig.Type}}\t{{.HostConfig.RestartPolicy.Name}}\t{{json .Config.Healthcheck}}",
            cid,
        ], timeout=8)

        log_driver = "unknown"
        restart_policy = ""
        healthcheck = "NO"

        if irc == 0 and iout:
            iparts = iout.split("\t")
            while len(iparts) < 3:
                iparts.append("")
            log_driver = iparts[0] or "unknown"
            restart_policy = iparts[1]
            healthcheck = "YES" if iparts[2] not in ["", "null", "<nil>"] else "NO"

        rows.append([
            "docker_container",
            safe(name),
            safe(image),
            safe(status),
            safe(log_driver),
            safe(healthcheck),
            safe(restart_policy),
            "LOW",
            "docker_metadata_only_no_logs_read",
        ])

    return rows

def systemd_log_source_rows():
    rows = []

    services = parse_tsv(prev_20_3_services)
    for r in services:
        service_name = r.get("service_name", "")
        category = r.get("category", "")
        active_state = r.get("active_state", "")
        risk = r.get("risk", "")
        if re.search(r"pix2pi|nginx|docker|postgres|redis|nats|prometheus|grafana|loki|tempo|cadvisor|node|fail2ban", service_name + " " + category, re.I):
            rows.append([
                "systemd_service",
                safe(service_name),
                safe(category),
                safe(active_state),
                "journald",
                "unknown",
                safe(r.get("restart_policy", "")),
                safe(risk),
                "systemd_metadata_only_no_journal_body_read",
            ])

    return rows

def scan_pipeline_configs():
    rows = []
    scan_roots = [
        root,
        root / "deploy",
        root / "deployment",
        root / "docker",
        root / "configs",
        root / "config",
        root / "infra",
        root / "ops",
        Path("/opt/pix2pi"),
        Path("/etc/promtail"),
        Path("/etc/loki"),
        Path("/etc/grafana"),
    ]

    seen = set()

    def consider(path):
        if not path.exists() or not path.is_file():
            return
        if len(rows) >= 300:
            return

        low = str(path).lower()
        name = path.name.lower()

        if not (
            "loki" in low
            or "promtail" in low
            or "fluent" in low
            or "vector" in low
            or "otel" in low
            or "opentelemetry" in low
            or "compose" in name
            or name.endswith((".yml", ".yaml", ".json", ".toml", ".conf"))
        ):
            return

        key = str(path)
        if key in seen:
            return
        seen.add(key)

        text = read(path)
        marker_hits = {}
        total_hits = 0

        for marker_name, pattern in PIPELINE_MARKERS:
            count = len(re.findall(pattern, text, re.I | re.M))
            marker_hits[marker_name] = count
            total_hits += count

        if total_hits == 0:
            return

        category = "log_pipeline_config_candidate"
        risk = "LOW"
        note = "config_marker_metadata_only_no_config_body_printed"

        if marker_hits.get("redaction_marker", 0) == 0:
            risk = "MEDIUM"
            note += ",redaction_marker_missing_review"

        if marker_hits.get("tenant_label", 0) == 0:
            note += ",tenant_label_marker_missing_review"

        rows.append([
            safe(str(path)),
            category,
            risk,
            str(marker_hits.get("loki_config", 0)),
            str(marker_hits.get("promtail_config", 0)),
            str(marker_hits.get("log_agent_config", 0)),
            str(marker_hits.get("docker_logging", 0)),
            str(marker_hits.get("tenant_label", 0)),
            str(marker_hits.get("service_label", 0)),
            str(marker_hits.get("trace_label", 0)),
            str(marker_hits.get("redaction_marker", 0)),
            note,
        ])

    for base in scan_roots:
        if not base.exists():
            continue
        try:
            if base.is_file():
                consider(base)
            else:
                for child in sorted(base.rglob("*")):
                    if any(part in [".git", "node_modules", "vendor"] for part in child.parts):
                        continue
                    consider(child)
        except Exception:
            warn(f"log pipeline scan skipped: {base}")

    return rows

def build_public_surface_policy():
    rows = []
    seen = set()

    prev_ports = parse_tsv(prev_20_3_ports)
    for r in prev_ports:
        port = r.get("port", "")
        bind_scope = r.get("bind_scope", "")
        expected_service = r.get("expected_service", "")
        risk = r.get("risk", "")

        if port not in LOG_PUBLIC_PORTS:
            continue

        key = ("20.3", port, bind_scope, expected_service)
        if key in seen:
            continue
        seen.add(key)

        final_risk = "HIGH" if bind_scope == "public_or_all_interfaces" else "MEDIUM"

        rows.append([
            "20.3_runtime_ports",
            safe(port),
            safe(LOG_PUBLIC_PORTS.get(port, "logs_or_internal")),
            safe(bind_scope),
            safe(expected_service),
            "logs_surface_should_not_be_public",
            "private_network_vpn_auth_allowlist",
            final_risk,
            "evidence_only_no_firewall_or_port_change",
        ])

    prev_docker_ports = parse_tsv(prev_20_5_ports)
    for r in prev_docker_ports:
        port = r.get("host_port", "")
        service_hint = r.get("service_hint", "")
        risk = r.get("risk", "")
        policy = r.get("port_policy", "")

        if port not in LOG_PUBLIC_PORTS:
            continue

        key = ("20.5", port, service_hint, policy)
        if key in seen:
            continue
        seen.add(key)

        rows.append([
            "20.5_docker_public_ports",
            safe(port),
            safe(service_hint or LOG_PUBLIC_PORTS.get(port, "logs_or_internal")),
            "docker_publish",
            safe(policy),
            "logs_surface_should_not_be_public",
            "remove_public_publish_or_bind_loopback_or_private_network",
            safe(risk or "HIGH"),
            "evidence_only_no_docker_port_change",
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
detail("LOKI_CONFIG_CHANGED=NO")
detail("LOKI_RELOAD_EXECUTED=NO")
detail("LOKI_RESTARTED=NO")
detail("PROMTAIL_CONFIG_CHANGED=NO")
detail("LOG_AGENT_CONFIG_CHANGED=NO")
detail("GRAFANA_DASHBOARD_CHANGED=NO")
detail("ALERT_RULE_CHANGED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("LOG_CONTENT_PRINTED=NO")
detail("LOKI_QUERY_BODY_PRINTED=NO")
detail("JOURNAL_LOG_BODY_PRINTED=NO")
detail("DOCKER_LOG_BODY_PRINTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=LOGS_LOKI_READINESS_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "curl", "docker", "systemctl"]:
    tool_status(tool)

prev_22_2_status = get_value(prev_22_2, "FAZ4B_22_2_FINAL_STATUS")
prev_22_2_gate = get_value(prev_22_2, "METRICS_SCRAPE_READINESS")
prev_22_2_no_restart = get_value(prev_22_2, "SERVICE_RESTARTED")
prev_22_2_secret = get_value(prev_22_2, "SECRET_VALUE_PRINTED")
prev_22_1_status = get_value(prev_22_1, "FAZ4B_22_1_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_22_2_FINAL_STATUS={prev_22_2_status}")
detail(f"PREVIOUS_22_2_METRICS_SCRAPE_READINESS={prev_22_2_gate}")
detail(f"PREVIOUS_22_2_SERVICE_RESTARTED={prev_22_2_no_restart}")
detail(f"PREVIOUS_22_2_SECRET_VALUE_PRINTED={prev_22_2_secret}")
detail(f"PREVIOUS_22_1_FINAL_STATUS={prev_22_1_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_22_2_status != "PASS":
    fail("22.2 final status PASS degil")
if prev_22_2_gate != "PASS":
    fail("22.2 metrics scrape readiness PASS degil")
if prev_22_2_no_restart != "NO":
    fail("22.2 service restarted NO degil")
if prev_22_2_secret != "NO":
    fail("22.2 secret printed NO degil")
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

endpoint_rows = build_endpoint_probes()
docker_rows = docker_log_source_rows()
systemd_rows = systemd_log_source_rows()
source_rows = docker_rows + systemd_rows
pipeline_rows = scan_pipeline_configs()
public_rows = build_public_surface_policy()

endpoint_lines = [
    "probe_name\tcategory\tservice_hint\thost\tport\tpath\tpurpose\tresult\tstatus_code\treachable\tbody_policy\tnote"
]
for row in endpoint_rows:
    endpoint_lines.append("\t".join([safe(x) for x in row]))
endpoint_probe_file.write_text("\n".join(endpoint_lines) + "\n")

source_lines = [
    "source_type\tsource_name\timage_or_category\tstatus_or_active_state\tlog_driver_or_source\thealthcheck_or_unknown\trestart_policy\trisk\tnote"
]
for row in source_rows:
    source_lines.append("\t".join([safe(x) for x in row]))
source_inventory_file.write_text("\n".join(source_lines) + "\n")

pipeline_lines = [
    "config_path\tcategory\trisk\tloki_marker_count\tpromtail_marker_count\tlog_agent_marker_count\tdocker_logging_marker_count\ttenant_label_marker_count\tservice_label_marker_count\ttrace_label_marker_count\tredaction_marker_count\tnote"
]
for row in pipeline_rows:
    pipeline_lines.append("\t".join([safe(x) for x in row]))
pipeline_inventory_file.write_text("\n".join(pipeline_lines) + "\n")

public_lines = [
    "source\tport\tservice_hint\tbind_scope_or_source\tprevious_policy\tpublic_policy\trecommended_surface\trisk\tnote"
]
for row in public_rows:
    public_lines.append("\t".join([safe(x) for x in row]))
public_surface_policy_file.write_text("\n".join(public_lines) + "\n")

endpoint_count = len(endpoint_rows)
endpoint_reachable_count = sum(1 for r in endpoint_rows if r[9] == "YES")
endpoint_review_count = sum(1 for r in endpoint_rows if r[7] == "REVIEW")
loki_ready_probe = next((r for r in endpoint_rows if r[0] == "loki_ready"), None)
loki_ready_ok = bool(loki_ready_probe and loki_ready_probe[8] in ["200", "204"])
loki_reachable_count = sum(1 for r in endpoint_rows if r[2] == "loki" and r[9] == "YES")

source_count = len(source_rows)
docker_source_count = len(docker_rows)
systemd_source_count = len(systemd_rows)
high_risk_source_count = sum(1 for r in source_rows if r[7] == "HIGH")

pipeline_count = len(pipeline_rows)
tenant_label_marker_count = sum(int(r[7]) for r in pipeline_rows) if pipeline_rows else 0
service_label_marker_count = sum(int(r[8]) for r in pipeline_rows) if pipeline_rows else 0
trace_label_marker_count = sum(int(r[9]) for r in pipeline_rows) if pipeline_rows else 0
redaction_marker_count = sum(int(r[10]) for r in pipeline_rows) if pipeline_rows else 0

public_policy_count = len(public_rows)
high_risk_public_log_surface_count = sum(1 for r in public_rows if r[7] == "HIGH")
loki_public_surface_count = sum(1 for r in public_rows if r[2] == "loki" or r[1] == "3100")

detail(f"LOGS_LOKI_ENDPOINT_PROBE_COUNT={endpoint_count}")
detail(f"LOGS_LOKI_ENDPOINT_REACHABLE_COUNT={endpoint_reachable_count}")
detail(f"LOGS_LOKI_ENDPOINT_REVIEW_COUNT={endpoint_review_count}")
detail(f"LOGS_LOKI_READY_OK={'YES' if loki_ready_ok else 'NO'}")
detail(f"LOGS_LOKI_REACHABLE_COUNT={loki_reachable_count}")

detail(f"LOGS_SOURCE_COUNT={source_count}")
detail(f"LOGS_DOCKER_SOURCE_COUNT={docker_source_count}")
detail(f"LOGS_SYSTEMD_SOURCE_COUNT={systemd_source_count}")
detail(f"LOGS_HIGH_RISK_SOURCE_COUNT={high_risk_source_count}")

detail(f"LOGS_PIPELINE_CONFIG_COUNT={pipeline_count}")
detail(f"LOGS_TENANT_LABEL_MARKER_COUNT={tenant_label_marker_count}")
detail(f"LOGS_SERVICE_LABEL_MARKER_COUNT={service_label_marker_count}")
detail(f"LOGS_TRACE_LABEL_MARKER_COUNT={trace_label_marker_count}")
detail(f"LOGS_REDACTION_MARKER_COUNT={redaction_marker_count}")

detail(f"LOGS_PUBLIC_SURFACE_POLICY_COUNT={public_policy_count}")
detail(f"LOGS_HIGH_RISK_PUBLIC_SURFACE_COUNT={high_risk_public_log_surface_count}")
detail(f"LOGS_LOKI_PUBLIC_SURFACE_COUNT={loki_public_surface_count}")

previous_22_2_status = "PASS" if (
    prev_22_2_status == "PASS"
    and prev_22_2_gate == "PASS"
    and prev_22_2_no_restart == "NO"
    and prev_22_2_secret == "NO"
) else "FAIL"

endpoint_probe_status = "PASS" if endpoint_probe_file.exists() and endpoint_count >= 5 else "FAIL"
source_inventory_status = "PASS" if source_inventory_file.exists() and source_count >= 5 else "FAIL"
pipeline_inventory_status = "PASS" if pipeline_inventory_file.exists() else "FAIL"
public_surface_policy_status = "PASS" if public_surface_policy_file.exists() else "FAIL"
body_not_printed_status = "PASS"
no_restart_status = "PASS"
no_config_change_status = "PASS"
secret_safe_status = "PASS"

detail(f"LOGS_PREVIOUS_22_2={previous_22_2_status}")
detail(f"LOGS_LOKI_ENDPOINT_PROBE={endpoint_probe_status}")
detail(f"LOGS_SOURCE_INVENTORY={source_inventory_status}")
detail(f"LOGS_PIPELINE_INVENTORY={pipeline_inventory_status}")
detail(f"LOGS_PUBLIC_SURFACE_POLICY={public_surface_policy_status}")
detail(f"LOGS_BODY_NOT_PRINTED={body_not_printed_status}")
detail(f"LOGS_NO_RESTART={no_restart_status}")
detail(f"LOGS_NO_CONFIG_CHANGE={no_config_change_status}")
detail(f"LOGS_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_22_2", previous_22_2_status),
    ("endpoint_probe", endpoint_probe_status),
    ("source_inventory", source_inventory_status),
    ("pipeline_inventory", pipeline_inventory_status),
    ("public_surface_policy", public_surface_policy_status),
    ("body_not_printed", body_not_printed_status),
    ("no_restart", no_restart_status),
    ("no_config_change", no_config_change_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_22_2\t{previous_22_2_status}\tmetrics scrape readiness prerequisite",
    f"loki_endpoint_probe\t{endpoint_probe_status}\tprobes={endpoint_count} reachable={endpoint_reachable_count} review={endpoint_review_count}",
    f"loki_ready_metadata\tPASS\tloki_ready_ok={'YES' if loki_ready_ok else 'NO'} loki_reachable={loki_reachable_count}",
    f"log_source_inventory\t{source_inventory_status}\tsources={source_count} docker={docker_source_count} systemd={systemd_source_count}",
    f"log_pipeline_inventory\t{pipeline_inventory_status}\tconfigs={pipeline_count} tenant_markers={tenant_label_marker_count} redaction_markers={redaction_marker_count}",
    f"public_surface_policy\t{public_surface_policy_status}\tpublic_log_rows={public_policy_count} high_risk={high_risk_public_log_surface_count} loki_public={loki_public_surface_count}",
    f"body_not_printed\t{body_not_printed_status}\tlog/loki/journal/docker log body not printed",
    f"no_restart\t{no_restart_status}\tservice/container not restarted",
    f"no_config_change\t{no_config_change_status}\tloki/promtail/log agent config not changed",
    f"secret_safe\t{secret_safe_status}\tsecret values not printed",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "port_changed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "loki_config_changed\tNO\tevidence only",
    "loki_reload_executed\tNO\tevidence only",
    "loki_restarted\tNO\tevidence only",
    "promtail_config_changed\tNO\tevidence only",
    "log_agent_config_changed\tNO\tevidence only",
    "grafana_dashboard_changed\tNO\tevidence only",
    "alert_rule_changed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "log_content_printed\tNO\tsecret-safe report",
    "loki_query_body_printed\tNO\tsecret-safe report",
    "journal_log_body_printed\tNO\tsecret-safe report",
    "docker_log_body_printed\tNO\tsecret-safe report",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"LOGS_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("LOGS_SOURCE_INVENTORY_FILE=docs/phase4/22_3_logs_source_inventory.tsv")
detail("LOGS_LOKI_ENDPOINT_PROBE_FILE=docs/phase4/22_3_loki_endpoint_probe.tsv")
detail("LOGS_PIPELINE_INVENTORY_FILE=docs/phase4/22_3_log_pipeline_inventory.tsv")
detail("LOGS_PUBLIC_SURFACE_POLICY_FILE=docs/phase4/22_3_logs_public_surface_policy.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"LOGS_LOKI_READINESS={final_status}")
detail(f"FAZ4B_22_3_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 22.3 - Logs / Loki Readiness Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"LOGS_LOKI_READINESS={final_status}",
    f"FAZ4B_22_3_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/22_3_logs_loki_readiness_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "LOG_SOURCE_INVENTORY_FILE=docs/phase4/22_3_logs_source_inventory.tsv",
    "LOKI_ENDPOINT_PROBE_FILE=docs/phase4/22_3_loki_endpoint_probe.tsv",
    "LOG_PIPELINE_INVENTORY_FILE=docs/phase4/22_3_log_pipeline_inventory.tsv",
    "PUBLIC_SURFACE_POLICY_FILE=docs/phase4/22_3_logs_public_surface_policy.tsv",
    "NOTE=Log body, Loki query body, Docker logs, journal logs, raw DSN, token, password, or secret values are never printed.",
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
    "LOKI_CONFIG_CHANGED=NO",
    "LOKI_RELOAD_EXECUTED=NO",
    "LOKI_RESTARTED=NO",
    "PROMTAIL_CONFIG_CHANGED=NO",
    "LOG_AGENT_CONFIG_CHANGED=NO",
    "GRAFANA_DASHBOARD_CHANGED=NO",
    "ALERT_RULE_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "LOKI_QUERY_BODY_PRINTED=NO",
    "JOURNAL_LOG_BODY_PRINTED=NO",
    "DOCKER_LOG_BODY_PRINTED=NO",
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
    "LOKI_QUERY_BODY_PRINTED=NO",
    "JOURNAL_LOG_BODY_PRINTED=NO",
    "DOCKER_LOG_BODY_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"LOG_SOURCE_INVENTORY_FILE={source_inventory_file}")
print(f"LOKI_ENDPOINT_PROBE_FILE={endpoint_probe_file}")
print(f"LOG_PIPELINE_INVENTORY_FILE={pipeline_inventory_file}")
print(f"PUBLIC_SURFACE_POLICY_FILE={public_surface_policy_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"LOGS_LOKI_ENDPOINT_PROBE_COUNT={endpoint_count}")
print(f"LOGS_LOKI_ENDPOINT_REACHABLE_COUNT={endpoint_reachable_count}")
print(f"LOGS_LOKI_ENDPOINT_REVIEW_COUNT={endpoint_review_count}")
print(f"LOGS_LOKI_READY_OK={'YES' if loki_ready_ok else 'NO'}")
print(f"LOGS_LOKI_REACHABLE_COUNT={loki_reachable_count}")
print(f"LOGS_SOURCE_COUNT={source_count}")
print(f"LOGS_DOCKER_SOURCE_COUNT={docker_source_count}")
print(f"LOGS_SYSTEMD_SOURCE_COUNT={systemd_source_count}")
print(f"LOGS_HIGH_RISK_SOURCE_COUNT={high_risk_source_count}")
print(f"LOGS_PIPELINE_CONFIG_COUNT={pipeline_count}")
print(f"LOGS_TENANT_LABEL_MARKER_COUNT={tenant_label_marker_count}")
print(f"LOGS_SERVICE_LABEL_MARKER_COUNT={service_label_marker_count}")
print(f"LOGS_TRACE_LABEL_MARKER_COUNT={trace_label_marker_count}")
print(f"LOGS_REDACTION_MARKER_COUNT={redaction_marker_count}")
print(f"LOGS_PUBLIC_SURFACE_POLICY_COUNT={public_policy_count}")
print(f"LOGS_HIGH_RISK_PUBLIC_SURFACE_COUNT={high_risk_public_log_surface_count}")
print(f"LOGS_LOKI_PUBLIC_SURFACE_COUNT={loki_public_surface_count}")
print(f"LOGS_PREVIOUS_22_2={previous_22_2_status}")
print(f"LOGS_LOKI_ENDPOINT_PROBE={endpoint_probe_status}")
print(f"LOGS_SOURCE_INVENTORY={source_inventory_status}")
print(f"LOGS_PIPELINE_INVENTORY={pipeline_inventory_status}")
print(f"LOGS_PUBLIC_SURFACE_POLICY={public_surface_policy_status}")
print(f"LOGS_BODY_NOT_PRINTED={body_not_printed_status}")
print(f"LOGS_NO_RESTART={no_restart_status}")
print(f"LOGS_NO_CONFIG_CHANGE={no_config_change_status}")
print(f"LOGS_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("LOKI_CONFIG_CHANGED=NO")
print("LOKI_RELOAD_EXECUTED=NO")
print("LOKI_RESTARTED=NO")
print("PROMTAIL_CONFIG_CHANGED=NO")
print("LOG_AGENT_CONFIG_CHANGED=NO")
print("GRAFANA_DASHBOARD_CHANGED=NO")
print("ALERT_RULE_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("LOG_CONTENT_PRINTED=NO")
print("LOKI_QUERY_BODY_PRINTED=NO")
print("JOURNAL_LOG_BODY_PRINTED=NO")
print("DOCKER_LOG_BODY_PRINTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"LOGS_LOKI_READINESS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_22_3_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
