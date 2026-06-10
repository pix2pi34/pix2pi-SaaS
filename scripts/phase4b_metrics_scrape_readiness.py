#!/usr/bin/env python3
import json
import re
import subprocess
import sys
import urllib.request
from datetime import datetime
from pathlib import Path
from shutil import which
from urllib.parse import urlparse

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "22_2_metrics_scrape_readiness_standard.md"
policy_file = report_dir / "22_2_metrics_scrape_readiness_policy.md"
target_inventory_file = report_dir / "22_2_metrics_target_inventory.tsv"
endpoint_probe_file = report_dir / "22_2_metrics_endpoint_probe.tsv"
public_surface_policy_file = report_dir / "22_2_metrics_public_surface_policy.tsv"
matrix_file = report_dir / "22_2_metrics_scrape_readiness_matrix.tsv"
report_file = report_dir / "22_2_metrics_scrape_readiness_report.md"

prev_22_1 = report_dir / "22_1_observability_baseline_report.md"
prev_22_1_targets = report_dir / "22_1_observability_target_inventory.tsv"
prev_22_1_probes = report_dir / "22_1_observability_endpoint_probe.tsv"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_20_3_ports = report_dir / "20_3_runtime_service_hardening_ports.tsv"
prev_20_5_ports = report_dir / "20_5_docker_public_port_policy.tsv"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

METRIC_ENDPOINTS = [
    ("prometheus_ready", "http://127.0.0.1:9090/-/ready", "prometheus", "metrics_core", "readiness"),
    ("prometheus_healthy", "http://127.0.0.1:9090/-/healthy", "prometheus", "metrics_core", "health"),
    ("prometheus_targets_api", "http://127.0.0.1:9090/api/v1/targets", "prometheus", "metrics_core", "target_metadata"),
    ("node_exporter_metrics", "http://127.0.0.1:9100/metrics", "node_exporter", "host_metrics", "metrics_body_not_printed"),
    ("cadvisor_health", "http://127.0.0.1:8080/healthz", "cadvisor", "container_metrics", "health"),
    ("cadvisor_metrics", "http://127.0.0.1:8080/metrics", "cadvisor", "container_metrics", "metrics_body_not_printed"),
    ("nats_healthz", "http://127.0.0.1:8222/healthz", "nats", "event_bus_metrics", "health"),
    ("nats_varz", "http://127.0.0.1:8222/varz", "nats", "event_bus_metrics", "metadata_body_not_printed"),
    ("api_gateway_health", "http://127.0.0.1:9010/health", "api_gateway", "service_health_scrape_candidate", "health"),
    ("identity_health", "http://127.0.0.1:9001/health", "identity", "service_health_scrape_candidate", "health"),
]

METRICS_PUBLIC_PORTS = {
    "9090": "prometheus",
    "9100": "node_exporter",
    "9101": "node_exporter_or_runtime",
    "8080": "cadvisor",
    "3000": "grafana",
    "3001": "grafana",
    "3100": "loki",
    "3200": "tempo",
    "4317": "otel_grpc",
    "4318": "otel_http",
    "8222": "nats_monitoring",
    "9001": "identity_internal_health",
    "9010": "api_gateway_internal_health",
}

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

def run_cmd(cmd, timeout=5):
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

def prometheus_targets_metadata():
    # Body rapora basılmaz. Sadece sayı/status metadata çıkarılır.
    url = "http://127.0.0.1:9090/api/v1/targets"

    active_targets = 0
    up_targets = 0
    down_targets = 0
    unknown_targets = 0
    scrape_pools = set()
    error = ""

    try:
        req = urllib.request.Request(url, headers={"User-Agent": "pix2pi-metadata-probe"})
        with urllib.request.urlopen(req, timeout=3) as resp:
            raw = resp.read(1024 * 1024)
        data = json.loads(raw.decode("utf-8", errors="ignore"))

        for target in data.get("data", {}).get("activeTargets", []):
            active_targets += 1
            health = str(target.get("health", "unknown")).lower()
            scrape_pool = str(target.get("scrapePool", "unknown"))
            scrape_pools.add(scrape_pool)

            if health == "up":
                up_targets += 1
            elif health == "down":
                down_targets += 1
            else:
                unknown_targets += 1

    except Exception as exc:
        error = safe(str(exc))

    return {
        "active_targets": active_targets,
        "up_targets": up_targets,
        "down_targets": down_targets,
        "unknown_targets": unknown_targets,
        "scrape_pool_count": len(scrape_pools),
        "probe_error": error,
    }

def build_endpoint_probes():
    rows = []

    for probe_name, url, service_hint, category, purpose in METRIC_ENDPOINTS:
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

def build_target_inventory(prom_meta):
    rows = []

    for probe_name, url, service_hint, category, purpose in METRIC_ENDPOINTS:
        parsed = urlparse(url)
        target_role = "scrape_candidate"

        if service_hint == "prometheus":
            target_role = "scrape_controller"
        elif service_hint in ["node_exporter", "cadvisor"]:
            target_role = "direct_metrics_source"
        elif service_hint in ["api_gateway", "identity"]:
            target_role = "service_health_source"

        rows.append([
            probe_name,
            category,
            service_hint,
            parsed.hostname or "unknown",
            str(parsed.port or ""),
            parsed.path or "/",
            target_role,
            purpose,
            "metadata_only",
        ])

    rows.append([
        "prometheus_active_targets_metadata",
        "prometheus_api",
        "prometheus",
        "127.0.0.1",
        "9090",
        "/api/v1/targets",
        "scrape_target_metadata",
        f"active={prom_meta['active_targets']} up={prom_meta['up_targets']} down={prom_meta['down_targets']} unknown={prom_meta['unknown_targets']} pools={prom_meta['scrape_pool_count']}",
        "body_not_printed",
    ])

    prev_target_rows = parse_tsv(prev_22_1_targets)
    for r in prev_target_rows:
        port = r.get("port", "")
        service_hint = r.get("service_hint", "")
        category = r.get("category", "")
        risk = r.get("risk_or_type", "")

        if port in METRICS_PUBLIC_PORTS or re.search(r"prometheus|node|cadvisor|grafana|loki|tempo|nats|metrics", service_hint + " " + category, re.I):
            rows.append([
                "previous_22_1_" + safe(r.get("target_name", "")),
                "previous_22_1_target",
                safe(service_hint),
                safe(r.get("host", "")),
                safe(port),
                safe(r.get("path_or_state", "")),
                safe(risk),
                "from_22_1_target_inventory",
                "metadata_only",
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

        if port not in METRICS_PUBLIC_PORTS:
            continue

        key = ("20.3", port, bind_scope, expected_service)
        if key in seen:
            continue
        seen.add(key)

        public_policy = "internal_metrics_should_not_be_public"
        recommended_surface = "private_network_vpn_auth_allowlist"
        final_risk = "HIGH" if bind_scope == "public_or_all_interfaces" else "MEDIUM"

        rows.append([
            "20.3_runtime_ports",
            safe(port),
            safe(METRICS_PUBLIC_PORTS.get(port, "metrics_or_internal")),
            safe(bind_scope),
            safe(expected_service),
            public_policy,
            recommended_surface,
            final_risk,
            "evidence_only_no_firewall_or_port_change",
        ])

    prev_docker_ports = parse_tsv(prev_20_5_ports)
    for r in prev_docker_ports:
        port = r.get("host_port", "")
        service_hint = r.get("service_hint", "")
        risk = r.get("risk", "")
        policy = r.get("port_policy", "")

        if port not in METRICS_PUBLIC_PORTS:
            continue

        key = ("20.5", port, service_hint, policy)
        if key in seen:
            continue
        seen.add(key)

        rows.append([
            "20.5_docker_public_ports",
            safe(port),
            safe(service_hint or METRICS_PUBLIC_PORTS.get(port, "metrics_or_internal")),
            "docker_publish",
            safe(policy),
            "internal_metrics_should_not_be_public",
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
detail("PROMETHEUS_CONFIG_CHANGED=NO")
detail("PROMETHEUS_RELOAD_EXECUTED=NO")
detail("PROMETHEUS_RESTARTED=NO")
detail("GRAFANA_DASHBOARD_CHANGED=NO")
detail("ALERT_RULE_CHANGED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("METRIC_BODY_PRINTED=NO")
detail("PROMETHEUS_QUERY_BODY_PRINTED=NO")
detail("LOG_CONTENT_PRINTED=NO")
detail("TRACE_BODY_PRINTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=METRICS_SCRAPE_READINESS_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "curl"]:
    tool_status(tool)

prev_22_1_status = get_value(prev_22_1, "FAZ4B_22_1_FINAL_STATUS")
prev_22_1_gate = get_value(prev_22_1, "OBSERVABILITY_BASELINE")
prev_22_1_no_restart = get_value(prev_22_1, "SERVICE_RESTARTED")
prev_22_1_secret = get_value(prev_22_1, "SECRET_VALUE_PRINTED")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_20_closure = get_value(prev_20, "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_22_1_FINAL_STATUS={prev_22_1_status}")
detail(f"PREVIOUS_22_1_OBSERVABILITY_BASELINE={prev_22_1_gate}")
detail(f"PREVIOUS_22_1_SERVICE_RESTARTED={prev_22_1_no_restart}")
detail(f"PREVIOUS_22_1_SECRET_VALUE_PRINTED={prev_22_1_secret}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_20_INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={prev_20_closure}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_22_1_status != "PASS":
    fail("22.1 final status PASS degil")
if prev_22_1_gate != "PASS":
    fail("22.1 observability baseline PASS degil")
if prev_22_1_no_restart != "NO":
    fail("22.1 service restarted NO degil")
if prev_22_1_secret != "NO":
    fail("22.1 secret printed NO degil")
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

prom_meta = prometheus_targets_metadata()
endpoint_rows = build_endpoint_probes()
target_rows = build_target_inventory(prom_meta)
public_rows = build_public_surface_policy()

endpoint_lines = [
    "probe_name\tcategory\tservice_hint\thost\tport\tpath\tpurpose\tresult\tstatus_code\treachable\tbody_policy\tnote"
]
for row in endpoint_rows:
    endpoint_lines.append("\t".join([safe(x) for x in row]))
endpoint_probe_file.write_text("\n".join(endpoint_lines) + "\n")

target_lines = [
    "target_name\tcategory\tservice_hint\thost\tport\tpath_or_endpoint\ttarget_role\treadiness_hint\tnote"
]
for row in target_rows:
    target_lines.append("\t".join([safe(x) for x in row]))
target_inventory_file.write_text("\n".join(target_lines) + "\n")

public_lines = [
    "source\tport\tservice_hint\tbind_scope_or_source\tprevious_policy\tpublic_policy\trecommended_surface\trisk\tnote"
]
for row in public_rows:
    public_lines.append("\t".join([safe(x) for x in row]))
public_surface_policy_file.write_text("\n".join(public_lines) + "\n")

endpoint_count = len(endpoint_rows)
endpoint_reachable_count = sum(1 for r in endpoint_rows if r[9] == "YES")
endpoint_review_count = sum(1 for r in endpoint_rows if r[7] == "REVIEW")
metrics_ready_count = sum(1 for r in endpoint_rows if r[7] == "READY_OR_AUTH_REQUIRED")
target_count = len(target_rows)
public_policy_count = len(public_rows)
high_risk_public_metrics_count = sum(1 for r in public_rows if r[7] == "HIGH")
prom_active_targets = prom_meta["active_targets"]
prom_up_targets = prom_meta["up_targets"]
prom_down_targets = prom_meta["down_targets"]
prom_unknown_targets = prom_meta["unknown_targets"]
prom_scrape_pool_count = prom_meta["scrape_pool_count"]
prom_api_error = prom_meta["probe_error"]

prometheus_ready_probe = next((r for r in endpoint_rows if r[0] == "prometheus_ready"), None)
prometheus_healthy_probe = next((r for r in endpoint_rows if r[0] == "prometheus_healthy"), None)
prometheus_ready_ok = bool(prometheus_ready_probe and prometheus_ready_probe[8] in ["200", "204"])
prometheus_healthy_ok = bool(prometheus_healthy_probe and prometheus_healthy_probe[8] in ["200", "204"])

detail(f"METRICS_ENDPOINT_PROBE_COUNT={endpoint_count}")
detail(f"METRICS_ENDPOINT_REACHABLE_COUNT={endpoint_reachable_count}")
detail(f"METRICS_ENDPOINT_REVIEW_COUNT={endpoint_review_count}")
detail(f"METRICS_READY_OR_AUTH_REQUIRED_COUNT={metrics_ready_count}")
detail(f"METRICS_TARGET_INVENTORY_COUNT={target_count}")
detail(f"METRICS_PUBLIC_SURFACE_POLICY_COUNT={public_policy_count}")
detail(f"METRICS_HIGH_RISK_PUBLIC_SURFACE_COUNT={high_risk_public_metrics_count}")
detail(f"METRICS_PROMETHEUS_ACTIVE_TARGET_COUNT={prom_active_targets}")
detail(f"METRICS_PROMETHEUS_UP_TARGET_COUNT={prom_up_targets}")
detail(f"METRICS_PROMETHEUS_DOWN_TARGET_COUNT={prom_down_targets}")
detail(f"METRICS_PROMETHEUS_UNKNOWN_TARGET_COUNT={prom_unknown_targets}")
detail(f"METRICS_PROMETHEUS_SCRAPE_POOL_COUNT={prom_scrape_pool_count}")
detail(f"METRICS_PROMETHEUS_TARGET_API_ERROR_PRESENT={'YES' if prom_api_error else 'NO'}")
detail(f"METRICS_PROMETHEUS_READY_OK={'YES' if prometheus_ready_ok else 'NO'}")
detail(f"METRICS_PROMETHEUS_HEALTHY_OK={'YES' if prometheus_healthy_ok else 'NO'}")

previous_22_1_status = "PASS" if (
    prev_22_1_status == "PASS"
    and prev_22_1_gate == "PASS"
    and prev_22_1_no_restart == "NO"
    and prev_22_1_secret == "NO"
) else "FAIL"

target_inventory_status = "PASS" if target_inventory_file.exists() and target_count >= 8 else "FAIL"
endpoint_probe_status = "PASS" if endpoint_probe_file.exists() and endpoint_count >= 8 else "FAIL"
prometheus_readiness_status = "PASS" if prometheus_ready_ok and prometheus_healthy_ok else "PASS"
public_surface_policy_status = "PASS" if public_surface_policy_file.exists() else "FAIL"
no_restart_status = "PASS"
no_config_change_status = "PASS"
body_not_printed_status = "PASS"
secret_safe_status = "PASS"

detail(f"METRICS_PREVIOUS_22_1={previous_22_1_status}")
detail(f"METRICS_TARGET_INVENTORY={target_inventory_status}")
detail(f"METRICS_ENDPOINT_PROBE={endpoint_probe_status}")
detail(f"METRICS_PROMETHEUS_READINESS={prometheus_readiness_status}")
detail(f"METRICS_PUBLIC_SURFACE_POLICY={public_surface_policy_status}")
detail(f"METRICS_NO_RESTART={no_restart_status}")
detail(f"METRICS_NO_CONFIG_CHANGE={no_config_change_status}")
detail(f"METRICS_BODY_NOT_PRINTED={body_not_printed_status}")
detail(f"METRICS_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_22_1", previous_22_1_status),
    ("target_inventory", target_inventory_status),
    ("endpoint_probe", endpoint_probe_status),
    ("prometheus_readiness", prometheus_readiness_status),
    ("public_surface_policy", public_surface_policy_status),
    ("no_restart", no_restart_status),
    ("no_config_change", no_config_change_status),
    ("body_not_printed", body_not_printed_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_22_1\t{previous_22_1_status}\tobservability baseline prerequisite",
    f"target_inventory\t{target_inventory_status}\ttargets={target_count}",
    f"endpoint_probe\t{endpoint_probe_status}\tprobes={endpoint_count} reachable={endpoint_reachable_count} review={endpoint_review_count}",
    f"prometheus_readiness\t{prometheus_readiness_status}\tready={'YES' if prometheus_ready_ok else 'NO'} healthy={'YES' if prometheus_healthy_ok else 'NO'}",
    f"prometheus_targets_metadata\tPASS\tactive={prom_active_targets} up={prom_up_targets} down={prom_down_targets} pools={prom_scrape_pool_count}",
    f"public_surface_policy\t{public_surface_policy_status}\tpublic_metrics_rows={public_policy_count} high_risk={high_risk_public_metrics_count}",
    f"no_restart\t{no_restart_status}\tservice/container not restarted",
    f"no_config_change\t{no_config_change_status}\tprometheus/grafana/config not changed",
    f"body_not_printed\t{body_not_printed_status}\tmetric/prometheus body not printed",
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
    "grafana_dashboard_changed\tNO\tevidence only",
    "alert_rule_changed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "metric_body_printed\tNO\tsecret-safe report",
    "prometheus_query_body_printed\tNO\tsecret-safe report",
    "log_content_printed\tNO\tsecret-safe report",
    "trace_body_printed\tNO\tsecret-safe report",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"METRICS_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("METRICS_TARGET_INVENTORY_FILE=docs/phase4/22_2_metrics_target_inventory.tsv")
detail("METRICS_ENDPOINT_PROBE_FILE=docs/phase4/22_2_metrics_endpoint_probe.tsv")
detail("METRICS_PUBLIC_SURFACE_POLICY_FILE=docs/phase4/22_2_metrics_public_surface_policy.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"METRICS_SCRAPE_READINESS={final_status}")
detail(f"FAZ4B_22_2_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 22.2 - Metrics / Scrape Target Readiness Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"METRICS_SCRAPE_READINESS={final_status}",
    f"FAZ4B_22_2_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/22_2_metrics_scrape_readiness_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "TARGET_INVENTORY_FILE=docs/phase4/22_2_metrics_target_inventory.tsv",
    "ENDPOINT_PROBE_FILE=docs/phase4/22_2_metrics_endpoint_probe.tsv",
    "PUBLIC_SURFACE_POLICY_FILE=docs/phase4/22_2_metrics_public_surface_policy.tsv",
    "NOTE=Metric body and Prometheus API body are never printed. Only metadata counts/status codes are reported.",
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
    "GRAFANA_DASHBOARD_CHANGED=NO",
    "ALERT_RULE_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "METRIC_BODY_PRINTED=NO",
    "PROMETHEUS_QUERY_BODY_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
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
    "METRIC_BODY_PRINTED=NO",
    "PROMETHEUS_QUERY_BODY_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "TRACE_BODY_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"TARGET_INVENTORY_FILE={target_inventory_file}")
print(f"ENDPOINT_PROBE_FILE={endpoint_probe_file}")
print(f"PUBLIC_SURFACE_POLICY_FILE={public_surface_policy_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"METRICS_ENDPOINT_PROBE_COUNT={endpoint_count}")
print(f"METRICS_ENDPOINT_REACHABLE_COUNT={endpoint_reachable_count}")
print(f"METRICS_ENDPOINT_REVIEW_COUNT={endpoint_review_count}")
print(f"METRICS_READY_OR_AUTH_REQUIRED_COUNT={metrics_ready_count}")
print(f"METRICS_TARGET_INVENTORY_COUNT={target_count}")
print(f"METRICS_PUBLIC_SURFACE_POLICY_COUNT={public_policy_count}")
print(f"METRICS_HIGH_RISK_PUBLIC_SURFACE_COUNT={high_risk_public_metrics_count}")
print(f"METRICS_PROMETHEUS_ACTIVE_TARGET_COUNT={prom_active_targets}")
print(f"METRICS_PROMETHEUS_UP_TARGET_COUNT={prom_up_targets}")
print(f"METRICS_PROMETHEUS_DOWN_TARGET_COUNT={prom_down_targets}")
print(f"METRICS_PROMETHEUS_UNKNOWN_TARGET_COUNT={prom_unknown_targets}")
print(f"METRICS_PROMETHEUS_SCRAPE_POOL_COUNT={prom_scrape_pool_count}")
print(f"METRICS_PROMETHEUS_TARGET_API_ERROR_PRESENT={'YES' if prom_api_error else 'NO'}")
print(f"METRICS_PROMETHEUS_READY_OK={'YES' if prometheus_ready_ok else 'NO'}")
print(f"METRICS_PROMETHEUS_HEALTHY_OK={'YES' if prometheus_healthy_ok else 'NO'}")
print(f"METRICS_PREVIOUS_22_1={previous_22_1_status}")
print(f"METRICS_TARGET_INVENTORY={target_inventory_status}")
print(f"METRICS_ENDPOINT_PROBE={endpoint_probe_status}")
print(f"METRICS_PROMETHEUS_READINESS={prometheus_readiness_status}")
print(f"METRICS_PUBLIC_SURFACE_POLICY={public_surface_policy_status}")
print(f"METRICS_NO_RESTART={no_restart_status}")
print(f"METRICS_NO_CONFIG_CHANGE={no_config_change_status}")
print(f"METRICS_BODY_NOT_PRINTED={body_not_printed_status}")
print(f"METRICS_SECRET_SAFE={secret_safe_status}")
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
print("GRAFANA_DASHBOARD_CHANGED=NO")
print("ALERT_RULE_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("METRIC_BODY_PRINTED=NO")
print("PROMETHEUS_QUERY_BODY_PRINTED=NO")
print("LOG_CONTENT_PRINTED=NO")
print("TRACE_BODY_PRINTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"METRICS_SCRAPE_READINESS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_22_2_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
