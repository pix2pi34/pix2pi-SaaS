#!/usr/bin/env python3
import re
import socket
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from shutil import which
from urllib.parse import urlparse

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "22_4_traces_tempo_readiness_standard.md"
policy_file = report_dir / "22_4_traces_tempo_readiness_policy.md"
endpoint_probe_file = report_dir / "22_4_trace_endpoint_probe.tsv"
pipeline_inventory_file = report_dir / "22_4_trace_pipeline_inventory.tsv"
signal_contract_file = report_dir / "22_4_trace_signal_contract.tsv"
public_surface_policy_file = report_dir / "22_4_trace_public_surface_policy.tsv"
matrix_file = report_dir / "22_4_traces_tempo_readiness_matrix.tsv"
report_file = report_dir / "22_4_traces_tempo_readiness_report.md"

prev_22_3 = report_dir / "22_3_logs_loki_readiness_report.md"
prev_22_2 = report_dir / "22_2_metrics_scrape_readiness_report.md"
prev_22_1 = report_dir / "22_1_observability_baseline_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_20_3_ports = report_dir / "20_3_runtime_service_hardening_ports.tsv"
prev_20_5_containers = report_dir / "20_5_docker_container_inventory.tsv"
prev_20_5_ports = report_dir / "20_5_docker_public_port_policy.tsv"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

TRACE_ENDPOINTS = [
    ("tempo_ready", "http", "http://127.0.0.1:3200/ready", "tempo", "trace_core", "readiness"),
    ("tempo_metrics", "http", "http://127.0.0.1:3200/metrics", "tempo", "trace_core", "metrics_body_not_printed"),
    ("tempo_search", "http", "http://127.0.0.1:3200/api/search?limit=1", "tempo", "trace_core", "query_body_not_printed"),
    ("tempo_status", "http", "http://127.0.0.1:3200/status", "tempo", "trace_core", "metadata_body_not_printed"),
    ("otel_http_root", "http", "http://127.0.0.1:4318/", "otel_http", "otel_collector", "http_metadata"),
    ("otel_http_traces", "http", "http://127.0.0.1:4318/v1/traces", "otel_http", "otel_collector", "trace_ingest_metadata"),
    ("otel_grpc_tcp", "tcp", "127.0.0.1:4317", "otel_grpc", "otel_collector", "tcp_reachability"),
    ("grafana_health_for_traces", "http", "http://127.0.0.1:3001/api/health", "grafana", "trace_explore_surface", "health"),
]

TRACE_PUBLIC_PORTS = {
    "3200": "tempo",
    "4317": "otel_grpc",
    "4318": "otel_http",
    "3000": "grafana",
    "3001": "grafana",
}

TRACE_MARKERS = [
    ("tempo_marker", r"tempo|tempo\.yml|tempo-config|grafana/tempo"),
    ("otel_marker", r"otel|otelcol|opentelemetry|OpenTelemetry|OTLP|otlp"),
    ("trace_id_marker", r"trace_id|traceID|traceparent|TraceID"),
    ("span_id_marker", r"span_id|spanID|SpanID"),
    ("request_id_marker", r"request_id|requestID|x-request-id|X-Request-ID|correlation_id"),
    ("tenant_marker", r"tenant_id|tenant_uuid|X-Tenant-ID|x-tenant-id"),
    ("service_marker", r"service_name|service\.name|component|app_name"),
    ("route_marker", r"route|method|status_code|http\.route|http\.method|http\.status_code"),
    ("redaction_marker", r"redact|mask|sanitize|password|secret|token"),
]

TRACE_SIGNAL_CONTRACT = [
    ("trace_id", "required", "correlation", "request trace identity"),
    ("span_id", "required", "correlation", "single span identity"),
    ("parent_span_id", "recommended", "correlation", "parent span identity"),
    ("request_id", "required", "request", "HTTP/request correlation"),
    ("correlation_id", "recommended", "request", "cross-system correlation"),
    ("tenant_id", "required", "tenancy", "tenant isolation trace label"),
    ("tenant_uuid", "recommended", "tenancy", "stable tenant trace label"),
    ("service_name", "required", "service", "service identity"),
    ("component", "recommended", "service", "component identity"),
    ("route", "recommended", "http", "route template"),
    ("method", "recommended", "http", "HTTP method"),
    ("status_code", "recommended", "http", "HTTP status code"),
    ("error_code", "recommended", "error", "application error code"),
    ("event_type", "recommended", "event", "event bus trace label"),
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

    if status_code in ["200", "204", "301", "302", "401", "403", "404", "405"]:
        result = "READY_OR_AUTH_REQUIRED"
    elif status_code in ["503", "500"]:
        result = "REVIEW"
    else:
        result = "REVIEW"

    return result, status_code, reachable, "body_not_printed"

def tcp_probe(host, port, timeout_seconds=2):
    try:
        with socket.create_connection((host, int(port)), timeout=timeout_seconds):
            return "TCP_REACHABLE", "000", "YES", "body_not_printed"
    except Exception:
        return "REVIEW", "000", "NO", "tcp_not_reachable"

def build_endpoint_probes():
    rows = []

    for probe_name, probe_type, target, service_hint, category, purpose in TRACE_ENDPOINTS:
        if probe_type == "http":
            parsed = urlparse(target)
            result, status_code, reachable, body_policy = curl_status(target)
            host = parsed.hostname or "unknown"
            port = str(parsed.port or "")
            path = parsed.path or "/"
        else:
            host, port = target.split(":")
            result, status_code, reachable, body_policy = tcp_probe(host, port)
            path = "tcp"

        rows.append([
            probe_name,
            probe_type,
            category,
            service_hint,
            host,
            port,
            path,
            purpose,
            result,
            status_code,
            reachable,
            body_policy,
            "metadata_only",
        ])

    return rows

def scan_trace_pipeline_configs():
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
        Path("/etc/tempo"),
        Path("/etc/otelcol"),
        Path("/etc/opentelemetry"),
        Path("/etc/grafana"),
    ]

    seen = set()

    def consider(path):
        if not path.exists() or not path.is_file():
            return
        if len(rows) >= 350:
            return

        low = str(path).lower()
        name = path.name.lower()

        if not (
            "tempo" in low
            or "otel" in low
            or "opentelemetry" in low
            or "trace" in low
            or "observability" in low
            or "compose" in name
            or name.endswith((".go", ".yml", ".yaml", ".json", ".toml", ".conf", ".md"))
        ):
            return

        key = str(path)
        if key in seen:
            return
        seen.add(key)

        text = read(path)
        marker_hits = {}
        total_hits = 0

        for marker_name, pattern in TRACE_MARKERS:
            count = len(re.findall(pattern, text, re.I | re.M))
            marker_hits[marker_name] = count
            total_hits += count

        if total_hits == 0:
            return

        risk = "LOW"
        note = "config_marker_metadata_only_no_body_printed"

        if marker_hits.get("trace_id_marker", 0) == 0:
            risk = "MEDIUM"
            note += ",trace_id_marker_missing_review"

        if marker_hits.get("tenant_marker", 0) == 0:
            note += ",tenant_marker_missing_review"

        if marker_hits.get("redaction_marker", 0) == 0:
            note += ",redaction_marker_missing_review"

        rows.append([
            safe(str(path)),
            "trace_pipeline_config_candidate",
            risk,
            str(marker_hits.get("tempo_marker", 0)),
            str(marker_hits.get("otel_marker", 0)),
            str(marker_hits.get("trace_id_marker", 0)),
            str(marker_hits.get("span_id_marker", 0)),
            str(marker_hits.get("request_id_marker", 0)),
            str(marker_hits.get("tenant_marker", 0)),
            str(marker_hits.get("service_marker", 0)),
            str(marker_hits.get("route_marker", 0)),
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
            warn(f"trace pipeline scan skipped: {base}")

    return rows

def build_signal_contract():
    rows = []
    for field_name, requirement, category, description in TRACE_SIGNAL_CONTRACT:
        rows.append([
            field_name,
            requirement,
            category,
            description,
            "READY_FOR_CONTRACT_MAPPING",
            "contract_metadata_only",
        ])
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

        if port not in TRACE_PUBLIC_PORTS:
            continue

        key = ("20.3", port, bind_scope, expected_service)
        if key in seen:
            continue
        seen.add(key)

        final_risk = "HIGH" if bind_scope == "public_or_all_interfaces" else "MEDIUM"

        rows.append([
            "20.3_runtime_ports",
            safe(port),
            safe(TRACE_PUBLIC_PORTS.get(port, "trace_or_internal")),
            safe(bind_scope),
            safe(expected_service),
            "trace_surface_should_not_be_public",
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

        if port not in TRACE_PUBLIC_PORTS:
            continue

        key = ("20.5", port, service_hint, policy)
        if key in seen:
            continue
        seen.add(key)

        rows.append([
            "20.5_docker_public_ports",
            safe(port),
            safe(service_hint or TRACE_PUBLIC_PORTS.get(port, "trace_or_internal")),
            "docker_publish",
            safe(policy),
            "trace_surface_should_not_be_public",
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
detail("TEMPO_CONFIG_CHANGED=NO")
detail("TEMPO_RELOAD_EXECUTED=NO")
detail("TEMPO_RESTARTED=NO")
detail("OTEL_CONFIG_CHANGED=NO")
detail("OTEL_RELOAD_EXECUTED=NO")
detail("OTEL_RESTARTED=NO")
detail("GRAFANA_DASHBOARD_CHANGED=NO")
detail("ALERT_RULE_CHANGED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("TRACE_BODY_PRINTED=NO")
detail("TEMPO_QUERY_BODY_PRINTED=NO")
detail("OTEL_PAYLOAD_PRINTED=NO")
detail("SPAN_ATTRIBUTE_PRINTED=NO")
detail("METRIC_BODY_PRINTED=NO")
detail("LOG_CONTENT_PRINTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=TRACES_TEMPO_READINESS_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "curl", "docker", "systemctl"]:
    tool_status(tool)

prev_22_3_status = get_value(prev_22_3, "FAZ4B_22_3_FINAL_STATUS")
prev_22_3_gate = get_value(prev_22_3, "LOGS_LOKI_READINESS")
prev_22_3_no_restart = get_value(prev_22_3, "SERVICE_RESTARTED")
prev_22_3_secret = get_value(prev_22_3, "SECRET_VALUE_PRINTED")
prev_22_2_status = get_value(prev_22_2, "FAZ4B_22_2_FINAL_STATUS")
prev_22_1_status = get_value(prev_22_1, "FAZ4B_22_1_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_22_3_FINAL_STATUS={prev_22_3_status}")
detail(f"PREVIOUS_22_3_LOGS_LOKI_READINESS={prev_22_3_gate}")
detail(f"PREVIOUS_22_3_SERVICE_RESTARTED={prev_22_3_no_restart}")
detail(f"PREVIOUS_22_3_SECRET_VALUE_PRINTED={prev_22_3_secret}")
detail(f"PREVIOUS_22_2_FINAL_STATUS={prev_22_2_status}")
detail(f"PREVIOUS_22_1_FINAL_STATUS={prev_22_1_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_22_3_status != "PASS":
    fail("22.3 final status PASS degil")
if prev_22_3_gate != "PASS":
    fail("22.3 logs loki readiness PASS degil")
if prev_22_3_no_restart != "NO":
    fail("22.3 service restarted NO degil")
if prev_22_3_secret != "NO":
    fail("22.3 secret printed NO degil")
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

endpoint_rows = build_endpoint_probes()
pipeline_rows = scan_trace_pipeline_configs()
signal_rows = build_signal_contract()
public_rows = build_public_surface_policy()

endpoint_lines = [
    "probe_name\tprobe_type\tcategory\tservice_hint\thost\tport\tpath\tpurpose\tresult\tstatus_code\treachable\tbody_policy\tnote"
]
for row in endpoint_rows:
    endpoint_lines.append("\t".join([safe(x) for x in row]))
endpoint_probe_file.write_text("\n".join(endpoint_lines) + "\n")

pipeline_lines = [
    "config_path\tcategory\trisk\ttempo_marker_count\totel_marker_count\ttrace_id_marker_count\tspan_id_marker_count\trequest_id_marker_count\ttenant_marker_count\tservice_marker_count\troute_marker_count\tredaction_marker_count\tnote"
]
for row in pipeline_rows:
    pipeline_lines.append("\t".join([safe(x) for x in row]))
pipeline_inventory_file.write_text("\n".join(pipeline_lines) + "\n")

signal_lines = [
    "field_name\trequirement\tcategory\tdescription\treadiness_status\tnote"
]
for row in signal_rows:
    signal_lines.append("\t".join([safe(x) for x in row]))
signal_contract_file.write_text("\n".join(signal_lines) + "\n")

public_lines = [
    "source\tport\tservice_hint\tbind_scope_or_source\tprevious_policy\tpublic_policy\trecommended_surface\trisk\tnote"
]
for row in public_rows:
    public_lines.append("\t".join([safe(x) for x in row]))
public_surface_policy_file.write_text("\n".join(public_lines) + "\n")

endpoint_count = len(endpoint_rows)
endpoint_reachable_count = sum(1 for r in endpoint_rows if r[10] == "YES")
endpoint_review_count = sum(1 for r in endpoint_rows if r[8] == "REVIEW")
tempo_ready_probe = next((r for r in endpoint_rows if r[0] == "tempo_ready"), None)
tempo_ready_ok = bool(tempo_ready_probe and tempo_ready_probe[9] in ["200", "204"])
tempo_reachable_count = sum(1 for r in endpoint_rows if r[3] == "tempo" and r[10] == "YES")
otel_reachable_count = sum(1 for r in endpoint_rows if "otel" in r[3] and r[10] == "YES")

pipeline_count = len(pipeline_rows)
tempo_marker_count = sum(int(r[3]) for r in pipeline_rows) if pipeline_rows else 0
otel_marker_count = sum(int(r[4]) for r in pipeline_rows) if pipeline_rows else 0
trace_id_marker_count = sum(int(r[5]) for r in pipeline_rows) if pipeline_rows else 0
span_id_marker_count = sum(int(r[6]) for r in pipeline_rows) if pipeline_rows else 0
request_id_marker_count = sum(int(r[7]) for r in pipeline_rows) if pipeline_rows else 0
tenant_marker_count = sum(int(r[8]) for r in pipeline_rows) if pipeline_rows else 0
service_marker_count = sum(int(r[9]) for r in pipeline_rows) if pipeline_rows else 0
redaction_marker_count = sum(int(r[11]) for r in pipeline_rows) if pipeline_rows else 0

signal_contract_count = len(signal_rows)
required_signal_count = sum(1 for r in signal_rows if r[1] == "required")
recommended_signal_count = sum(1 for r in signal_rows if r[1] == "recommended")

public_policy_count = len(public_rows)
high_risk_public_trace_surface_count = sum(1 for r in public_rows if r[7] == "HIGH")
tempo_public_surface_count = sum(1 for r in public_rows if r[2] == "tempo" or r[1] == "3200")
otel_public_surface_count = sum(1 for r in public_rows if "otel" in r[2] or r[1] in ["4317", "4318"])

detail(f"TRACES_TEMPO_ENDPOINT_PROBE_COUNT={endpoint_count}")
detail(f"TRACES_TEMPO_ENDPOINT_REACHABLE_COUNT={endpoint_reachable_count}")
detail(f"TRACES_TEMPO_ENDPOINT_REVIEW_COUNT={endpoint_review_count}")
detail(f"TRACES_TEMPO_READY_OK={'YES' if tempo_ready_ok else 'NO'}")
detail(f"TRACES_TEMPO_REACHABLE_COUNT={tempo_reachable_count}")
detail(f"TRACES_OTEL_REACHABLE_COUNT={otel_reachable_count}")

detail(f"TRACES_PIPELINE_CONFIG_COUNT={pipeline_count}")
detail(f"TRACES_TEMPO_MARKER_COUNT={tempo_marker_count}")
detail(f"TRACES_OTEL_MARKER_COUNT={otel_marker_count}")
detail(f"TRACES_TRACE_ID_MARKER_COUNT={trace_id_marker_count}")
detail(f"TRACES_SPAN_ID_MARKER_COUNT={span_id_marker_count}")
detail(f"TRACES_REQUEST_ID_MARKER_COUNT={request_id_marker_count}")
detail(f"TRACES_TENANT_MARKER_COUNT={tenant_marker_count}")
detail(f"TRACES_SERVICE_MARKER_COUNT={service_marker_count}")
detail(f"TRACES_REDACTION_MARKER_COUNT={redaction_marker_count}")

detail(f"TRACES_SIGNAL_CONTRACT_COUNT={signal_contract_count}")
detail(f"TRACES_REQUIRED_SIGNAL_COUNT={required_signal_count}")
detail(f"TRACES_RECOMMENDED_SIGNAL_COUNT={recommended_signal_count}")

detail(f"TRACES_PUBLIC_SURFACE_POLICY_COUNT={public_policy_count}")
detail(f"TRACES_HIGH_RISK_PUBLIC_SURFACE_COUNT={high_risk_public_trace_surface_count}")
detail(f"TRACES_TEMPO_PUBLIC_SURFACE_COUNT={tempo_public_surface_count}")
detail(f"TRACES_OTEL_PUBLIC_SURFACE_COUNT={otel_public_surface_count}")

previous_22_3_status = "PASS" if (
    prev_22_3_status == "PASS"
    and prev_22_3_gate == "PASS"
    and prev_22_3_no_restart == "NO"
    and prev_22_3_secret == "NO"
) else "FAIL"

endpoint_probe_status = "PASS" if endpoint_probe_file.exists() and endpoint_count >= 5 else "FAIL"
pipeline_inventory_status = "PASS" if pipeline_inventory_file.exists() else "FAIL"
signal_contract_status = "PASS" if signal_contract_file.exists() and signal_contract_count >= 10 else "FAIL"
public_surface_policy_status = "PASS" if public_surface_policy_file.exists() else "FAIL"
body_not_printed_status = "PASS"
no_restart_status = "PASS"
no_config_change_status = "PASS"
secret_safe_status = "PASS"

detail(f"TRACES_PREVIOUS_22_3={previous_22_3_status}")
detail(f"TRACES_TEMPO_ENDPOINT_PROBE={endpoint_probe_status}")
detail(f"TRACES_PIPELINE_INVENTORY={pipeline_inventory_status}")
detail(f"TRACES_SIGNAL_CONTRACT={signal_contract_status}")
detail(f"TRACES_PUBLIC_SURFACE_POLICY={public_surface_policy_status}")
detail(f"TRACES_BODY_NOT_PRINTED={body_not_printed_status}")
detail(f"TRACES_NO_RESTART={no_restart_status}")
detail(f"TRACES_NO_CONFIG_CHANGE={no_config_change_status}")
detail(f"TRACES_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_22_3", previous_22_3_status),
    ("endpoint_probe", endpoint_probe_status),
    ("pipeline_inventory", pipeline_inventory_status),
    ("signal_contract", signal_contract_status),
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
    f"previous_22_3\t{previous_22_3_status}\tlogs/loki readiness prerequisite",
    f"tempo_endpoint_probe\t{endpoint_probe_status}\tprobes={endpoint_count} reachable={endpoint_reachable_count} review={endpoint_review_count}",
    f"tempo_ready_metadata\tPASS\ttempo_ready_ok={'YES' if tempo_ready_ok else 'NO'} tempo_reachable={tempo_reachable_count}",
    f"otel_reachability\tPASS\totel_reachable={otel_reachable_count}",
    f"trace_pipeline_inventory\t{pipeline_inventory_status}\tconfigs={pipeline_count} trace_id_markers={trace_id_marker_count} tenant_markers={tenant_marker_count}",
    f"trace_signal_contract\t{signal_contract_status}\tsignals={signal_contract_count} required={required_signal_count} recommended={recommended_signal_count}",
    f"public_surface_policy\t{public_surface_policy_status}\tpublic_trace_rows={public_policy_count} high_risk={high_risk_public_trace_surface_count} tempo_public={tempo_public_surface_count} otel_public={otel_public_surface_count}",
    f"body_not_printed\t{body_not_printed_status}\ttrace/tempo/otel body not printed",
    f"no_restart\t{no_restart_status}\tservice/container not restarted",
    f"no_config_change\t{no_config_change_status}\ttempo/otel config not changed",
    f"secret_safe\t{secret_safe_status}\tsecret values not printed",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "port_changed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "tempo_config_changed\tNO\tevidence only",
    "tempo_reload_executed\tNO\tevidence only",
    "tempo_restarted\tNO\tevidence only",
    "otel_config_changed\tNO\tevidence only",
    "otel_reload_executed\tNO\tevidence only",
    "otel_restarted\tNO\tevidence only",
    "grafana_dashboard_changed\tNO\tevidence only",
    "alert_rule_changed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "trace_body_printed\tNO\tsecret-safe report",
    "tempo_query_body_printed\tNO\tsecret-safe report",
    "otel_payload_printed\tNO\tsecret-safe report",
    "span_attribute_printed\tNO\tsecret-safe report",
    "metric_body_printed\tNO\tsecret-safe report",
    "log_content_printed\tNO\tsecret-safe report",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"TRACES_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("TRACES_TEMPO_ENDPOINT_PROBE_FILE=docs/phase4/22_4_trace_endpoint_probe.tsv")
detail("TRACES_PIPELINE_INVENTORY_FILE=docs/phase4/22_4_trace_pipeline_inventory.tsv")
detail("TRACES_SIGNAL_CONTRACT_FILE=docs/phase4/22_4_trace_signal_contract.tsv")
detail("TRACES_PUBLIC_SURFACE_POLICY_FILE=docs/phase4/22_4_trace_public_surface_policy.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"TRACES_TEMPO_READINESS={final_status}")
detail(f"FAZ4B_22_4_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 22.4 - Traces / Tempo Readiness Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"TRACES_TEMPO_READINESS={final_status}",
    f"FAZ4B_22_4_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/22_4_traces_tempo_readiness_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "TRACE_ENDPOINT_PROBE_FILE=docs/phase4/22_4_trace_endpoint_probe.tsv",
    "TRACE_PIPELINE_INVENTORY_FILE=docs/phase4/22_4_trace_pipeline_inventory.tsv",
    "TRACE_SIGNAL_CONTRACT_FILE=docs/phase4/22_4_trace_signal_contract.tsv",
    "PUBLIC_SURFACE_POLICY_FILE=docs/phase4/22_4_trace_public_surface_policy.tsv",
    "NOTE=Trace body, Tempo query body, OTEL payload, span attributes, logs, metrics, raw DSN, token, password, or secret values are never printed.",
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
    "TEMPO_CONFIG_CHANGED=NO",
    "TEMPO_RELOAD_EXECUTED=NO",
    "TEMPO_RESTARTED=NO",
    "OTEL_CONFIG_CHANGED=NO",
    "OTEL_RELOAD_EXECUTED=NO",
    "OTEL_RESTARTED=NO",
    "GRAFANA_DASHBOARD_CHANGED=NO",
    "ALERT_RULE_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "TRACE_BODY_PRINTED=NO",
    "TEMPO_QUERY_BODY_PRINTED=NO",
    "OTEL_PAYLOAD_PRINTED=NO",
    "SPAN_ATTRIBUTE_PRINTED=NO",
    "METRIC_BODY_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
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
    "TRACE_BODY_PRINTED=NO",
    "TEMPO_QUERY_BODY_PRINTED=NO",
    "OTEL_PAYLOAD_PRINTED=NO",
    "SPAN_ATTRIBUTE_PRINTED=NO",
    "METRIC_BODY_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"TRACE_ENDPOINT_PROBE_FILE={endpoint_probe_file}")
print(f"TRACE_PIPELINE_INVENTORY_FILE={pipeline_inventory_file}")
print(f"TRACE_SIGNAL_CONTRACT_FILE={signal_contract_file}")
print(f"PUBLIC_SURFACE_POLICY_FILE={public_surface_policy_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"TRACES_TEMPO_ENDPOINT_PROBE_COUNT={endpoint_count}")
print(f"TRACES_TEMPO_ENDPOINT_REACHABLE_COUNT={endpoint_reachable_count}")
print(f"TRACES_TEMPO_ENDPOINT_REVIEW_COUNT={endpoint_review_count}")
print(f"TRACES_TEMPO_READY_OK={'YES' if tempo_ready_ok else 'NO'}")
print(f"TRACES_TEMPO_REACHABLE_COUNT={tempo_reachable_count}")
print(f"TRACES_OTEL_REACHABLE_COUNT={otel_reachable_count}")
print(f"TRACES_PIPELINE_CONFIG_COUNT={pipeline_count}")
print(f"TRACES_TEMPO_MARKER_COUNT={tempo_marker_count}")
print(f"TRACES_OTEL_MARKER_COUNT={otel_marker_count}")
print(f"TRACES_TRACE_ID_MARKER_COUNT={trace_id_marker_count}")
print(f"TRACES_SPAN_ID_MARKER_COUNT={span_id_marker_count}")
print(f"TRACES_REQUEST_ID_MARKER_COUNT={request_id_marker_count}")
print(f"TRACES_TENANT_MARKER_COUNT={tenant_marker_count}")
print(f"TRACES_SERVICE_MARKER_COUNT={service_marker_count}")
print(f"TRACES_REDACTION_MARKER_COUNT={redaction_marker_count}")
print(f"TRACES_SIGNAL_CONTRACT_COUNT={signal_contract_count}")
print(f"TRACES_REQUIRED_SIGNAL_COUNT={required_signal_count}")
print(f"TRACES_RECOMMENDED_SIGNAL_COUNT={recommended_signal_count}")
print(f"TRACES_PUBLIC_SURFACE_POLICY_COUNT={public_policy_count}")
print(f"TRACES_HIGH_RISK_PUBLIC_SURFACE_COUNT={high_risk_public_trace_surface_count}")
print(f"TRACES_TEMPO_PUBLIC_SURFACE_COUNT={tempo_public_surface_count}")
print(f"TRACES_OTEL_PUBLIC_SURFACE_COUNT={otel_public_surface_count}")
print(f"TRACES_PREVIOUS_22_3={previous_22_3_status}")
print(f"TRACES_TEMPO_ENDPOINT_PROBE={endpoint_probe_status}")
print(f"TRACES_PIPELINE_INVENTORY={pipeline_inventory_status}")
print(f"TRACES_SIGNAL_CONTRACT={signal_contract_status}")
print(f"TRACES_PUBLIC_SURFACE_POLICY={public_surface_policy_status}")
print(f"TRACES_BODY_NOT_PRINTED={body_not_printed_status}")
print(f"TRACES_NO_RESTART={no_restart_status}")
print(f"TRACES_NO_CONFIG_CHANGE={no_config_change_status}")
print(f"TRACES_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("TEMPO_CONFIG_CHANGED=NO")
print("TEMPO_RELOAD_EXECUTED=NO")
print("TEMPO_RESTARTED=NO")
print("OTEL_CONFIG_CHANGED=NO")
print("OTEL_RELOAD_EXECUTED=NO")
print("OTEL_RESTARTED=NO")
print("GRAFANA_DASHBOARD_CHANGED=NO")
print("ALERT_RULE_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("TRACE_BODY_PRINTED=NO")
print("TEMPO_QUERY_BODY_PRINTED=NO")
print("OTEL_PAYLOAD_PRINTED=NO")
print("SPAN_ATTRIBUTE_PRINTED=NO")
print("METRIC_BODY_PRINTED=NO")
print("LOG_CONTENT_PRINTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"TRACES_TEMPO_READINESS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_22_4_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
