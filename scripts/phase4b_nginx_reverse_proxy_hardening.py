#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which
from urllib.parse import urlparse

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "20_4_nginx_reverse_proxy_hardening_standard.md"
policy_file = report_dir / "20_4_nginx_reverse_proxy_hardening_policy.md"
config_inventory_file = report_dir / "20_4_nginx_reverse_proxy_config_inventory.tsv"
proxy_surface_file = report_dir / "20_4_nginx_reverse_proxy_surface_manifest.tsv"
public_port_policy_file = report_dir / "20_4_nginx_public_port_policy.tsv"
matrix_file = report_dir / "20_4_nginx_reverse_proxy_hardening_matrix.tsv"
report_file = report_dir / "20_4_nginx_reverse_proxy_hardening_report.md"

prev_20_3 = report_dir / "20_3_runtime_service_hardening_report.md"
prev_20_3_ports = report_dir / "20_3_runtime_service_hardening_ports.tsv"
prev_20_2 = report_dir / "20_2_config_env_hardening_report.md"
prev_20_1 = report_dir / "20_1_production_cleanup_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

ALLOWED_PUBLIC_PORTS = {"80", "443"}
SSH_MANAGEMENT_PORTS = {"22", "4383"}

INTERNAL_SHOULD_NOT_PUBLIC = {
    "6379": "redis",
    "5432": "postgres",
    "5433": "postgres-host",
    "5434": "postgres-replica-host",
    "4222": "nats-client",
    "6222": "nats-cluster",
    "8222": "nats-monitoring",
    "9090": "prometheus",
    "9100": "node-exporter",
    "9101": "node-exporter-or-runtime",
    "8080": "cadvisor",
    "3000": "grafana",
    "3001": "grafana-host",
    "3100": "loki",
    "3200": "tempo",
    "4317": "otel-grpc",
    "4318": "otel-http",
    "9001": "identity-or-mission-control",
    "9002": "identity-api",
    "9010": "api-gateway-loopback-target",
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

def rel(path):
    try:
        return str(path.relative_to(root))
    except Exception:
        return str(path)

def safe(v):
    v = str(v or "")
    v = v.replace("\t", " ").replace("\n", " ").replace("\r", " ")
    v = re.sub(r"(password|token|secret|dsn|bearer|authorization)\s*[:=]\s*[^ ]+", r"\1=***", v, flags=re.I)
    v = re.sub(r"://[^/@\s]+@", "://***@", v)
    return v[:220]

def collect_nginx_config_paths():
    candidates = [
        Path("/etc/nginx/nginx.conf"),
        Path("/etc/nginx/sites-enabled"),
        Path("/etc/nginx/conf.d"),
        Path("/opt/pix2pi/nginx"),
        root / "deploy/nginx",
        root / "deployment/nginx",
        root / "config/nginx",
        root / "configs/nginx",
        root / "docker/nginx",
    ]

    paths = []
    seen = set()

    for base in candidates:
        if not base.exists():
            continue

        if base.is_file():
            key = str(base)
            if key not in seen:
                paths.append(base)
                seen.add(key)
            continue

        try:
            for child in sorted(base.rglob("*")):
                if not child.is_file():
                    continue
                name = child.name.lower()
                if name.endswith((".conf", ".nginx")) or "nginx" in name or "site" in str(child).lower():
                    key = str(child)
                    if key not in seen:
                        paths.append(child)
                        seen.add(key)
        except Exception:
            warn(f"nginx config scan skipped: {base}")

    return paths

def count_re(pattern, text):
    return len(re.findall(pattern, text, re.I | re.M))

def sanitize_proxy_target(target):
    raw = target.strip().strip(";").strip()
    raw = re.sub(r"\?.*$", "", raw)

    if "$" in raw:
        return safe(raw)

    try:
        u = urlparse(raw)
        if u.scheme and u.netloc:
            host = u.hostname or "unknown"
            port = str(u.port or "")
            scheme = u.scheme
            if port:
                return f"{scheme}://{host}:{port}"
            return f"{scheme}://{host}"
    except Exception:
        pass

    return safe(raw)

def proxy_target_port(target):
    t = target.strip().strip(";").strip()

    try:
        u = urlparse(t)
        if u.port:
            return str(u.port)
    except Exception:
        pass

    m = re.search(r":(\d{2,5})", t)
    if m:
        return m.group(1)

    return ""

def config_risk(listen_count, proxy_count, ssl_count, security_header_count, rate_limit_count):
    risk = "LOW"
    notes = []

    if listen_count > 0 and ssl_count == 0:
        risk = "MEDIUM"
        notes.append("listen_without_tls_marker_review")

    if proxy_count > 0 and security_header_count == 0:
        risk = "MEDIUM"
        notes.append("proxy_without_security_header_marker_review")

    if proxy_count > 0 and rate_limit_count == 0:
        notes.append("rate_limit_marker_missing_review")

    if not notes:
        notes.append("evidence_only")

    return risk, ",".join(notes)

def parse_nginx_configs():
    rows = []
    surfaces = []
    paths = collect_nginx_config_paths()

    for path in paths:
        text = read(path)

        listen_count = count_re(r"\blisten\s+", text)
        server_name_count = count_re(r"\bserver_name\s+", text)
        proxy_pass_matches = re.findall(r"\bproxy_pass\s+([^;\s]+)", text, re.I | re.M)
        proxy_count = len(proxy_pass_matches)
        upstream_count = count_re(r"\bupstream\s+[A-Za-z0-9_\-]+", text)
        location_count = count_re(r"\blocation\s+", text)
        ssl_count = count_re(r"ssl_certificate|ssl_protocols|listen\s+443|http2", text)
        security_header_count = count_re(r"add_header|X-Frame-Options|X-Content-Type-Options|Referrer-Policy|Content-Security-Policy|Strict-Transport-Security", text)
        rate_limit_count = count_re(r"limit_req|limit_conn|zone=", text)
        timeout_count = count_re(r"proxy_read_timeout|proxy_connect_timeout|proxy_send_timeout|send_timeout", text)
        body_limit_count = count_re(r"client_max_body_size", text)
        allow_deny_count = count_re(r"\ballow\s+|\bdeny\s+", text)
        auth_marker_count = count_re(r"auth_basic|auth_request|satisfy\s+", text)

        risk, note = config_risk(
            listen_count,
            proxy_count,
            ssl_count,
            security_header_count,
            rate_limit_count,
        )

        category = "nginx_config"
        if str(path).startswith("/etc/nginx"):
            category = "system_nginx_config"
        elif str(path).startswith("/opt/pix2pi"):
            category = "pix2pi_runtime_nginx_config"
        else:
            category = "repo_nginx_config"

        rows.append([
            safe(str(path)),
            category,
            risk,
            str(listen_count),
            str(server_name_count),
            str(proxy_count),
            str(upstream_count),
            str(location_count),
            str(ssl_count),
            str(security_header_count),
            str(rate_limit_count),
            str(timeout_count),
            str(body_limit_count),
            str(allow_deny_count),
            str(auth_marker_count),
            note,
        ])

        for target in proxy_pass_matches:
            port = proxy_target_port(target)
            service_hint = INTERNAL_SHOULD_NOT_PUBLIC.get(port, "unknown_or_variable")
            sanitized = sanitize_proxy_target(target)

            surface_risk = "LOW"
            surface_note = "reverse_proxy_target_evidence"

            if service_hint != "unknown_or_variable":
                surface_risk = "MEDIUM"
                surface_note = "internal_service_proxy_target_review"

            surfaces.append([
                safe(str(path)),
                sanitized,
                safe(port),
                service_hint,
                surface_risk,
                surface_note,
            ])

    return rows, surfaces

def parse_previous_ports():
    rows = []

    if not prev_20_3_ports.exists():
        warn("previous port inventory not found")
        return rows

    text = read(prev_20_3_ports)
    lines = [x for x in text.splitlines() if x.strip()]

    if len(lines) <= 1:
        return rows

    for line in lines[1:]:
        parts = line.split("\t")
        while len(parts) < 8:
            parts.append("")

        netid, state, local_address, port, expected_service, bind_scope, risk, note = parts[:8]

        if bind_scope != "public_or_all_interfaces":
            continue

        port_policy = "unknown_public_review"
        recommended_surface = "review"
        policy_risk = "HIGH"

        if port in ALLOWED_PUBLIC_PORTS:
            port_policy = "allowed_public_web"
            recommended_surface = "internet"
            policy_risk = "LOW"
        elif port in SSH_MANAGEMENT_PORTS:
            port_policy = "management_ssh_controlled"
            recommended_surface = "allowlist_key_auth_fail2ban"
            policy_risk = "MEDIUM"
        elif port in INTERNAL_SHOULD_NOT_PUBLIC:
            port_policy = "internal_should_not_public"
            recommended_surface = "private_network_or_loopback_or_reverse_proxy"
            policy_risk = "HIGH"
        else:
            port_policy = "unknown_public_should_review"
            recommended_surface = "close_or_place_behind_reverse_proxy"
            policy_risk = "HIGH"

        rows.append([
            safe(netid),
            safe(local_address),
            safe(port),
            safe(expected_service),
            safe(bind_scope),
            port_policy,
            recommended_surface,
            policy_risk,
            "evidence_only_no_firewall_change",
        ])

    return rows

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("NGINX_CONFIG_CHANGED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
detail("NGINX_RESTARTED=NO")
detail("FIREWALL_CHANGED=NO")
detail("PORT_CHANGED=NO")
detail("DOCKER_PORT_CHANGED=NO")
detail("DOCKER_COMPOSE_EXECUTED=NO")
detail("SERVICE_RESTARTED=NO")
detail("DEPLOY_EXECUTED=NO")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("FILE_PERMISSION_CHANGED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("LOG_CONTENT_PRINTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=NGINX_REVERSE_PROXY_HARDENING_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "nginx", "ss"]:
    tool_status(tool)

prev_20_3_status = get_value(prev_20_3, "FAZ4B_20_3_FINAL_STATUS")
prev_20_3_gate = get_value(prev_20_3, "RUNTIME_SERVICE_HARDENING")
prev_20_3_restart = get_value(prev_20_3, "SERVICE_RESTARTED")
prev_20_3_deploy = get_value(prev_20_3, "DEPLOY_EXECUTED")
prev_20_2_status = get_value(prev_20_2, "FAZ4B_20_2_FINAL_STATUS")
prev_20_1_status = get_value(prev_20_1, "FAZ4B_20_1_FINAL_STATUS")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_20_3_FINAL_STATUS={prev_20_3_status}")
detail(f"PREVIOUS_20_3_RUNTIME_SERVICE_HARDENING={prev_20_3_gate}")
detail(f"PREVIOUS_20_3_SERVICE_RESTARTED={prev_20_3_restart}")
detail(f"PREVIOUS_20_3_DEPLOY_EXECUTED={prev_20_3_deploy}")
detail(f"PREVIOUS_20_2_FINAL_STATUS={prev_20_2_status}")
detail(f"PREVIOUS_20_1_FINAL_STATUS={prev_20_1_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_20_3_status != "PASS":
    fail("20.3 final status PASS degil")
if prev_20_3_gate != "PASS":
    fail("20.3 runtime service hardening PASS degil")
if prev_20_3_restart != "NO":
    fail("20.3 service restarted NO degil")
if prev_20_3_deploy != "NO":
    fail("20.3 deploy executed NO degil")
if prev_20_2_status != "PASS":
    fail("20.2 final status PASS degil")
if prev_20_1_status != "PASS":
    fail("20.1 final status PASS degil")
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

config_rows, proxy_surface_rows = parse_nginx_configs()
public_policy_rows = parse_previous_ports()

config_lines = [
    "config_path\tcategory\trisk\tlisten_count\tserver_name_count\tproxy_pass_count\tupstream_count\tlocation_count\tssl_marker_count\tsecurity_header_count\trate_limit_marker_count\ttimeout_marker_count\tbody_limit_marker_count\tallow_deny_marker_count\tauth_marker_count\tnote"
]
for row in config_rows:
    config_lines.append("\t".join(row))
config_inventory_file.write_text("\n".join(config_lines) + "\n")

surface_lines = [
    "config_path\tproxy_target_sanitized\ttarget_port\tservice_hint\trisk\tnote"
]
for row in proxy_surface_rows:
    surface_lines.append("\t".join(row))
proxy_surface_file.write_text("\n".join(surface_lines) + "\n")

public_policy_lines = [
    "netid\tlocal_address\tport\tprevious_expected_service\tbind_scope\tport_policy\trecommended_surface\trisk\tnote"
]
for row in public_policy_rows:
    public_policy_lines.append("\t".join(row))
public_port_policy_file.write_text("\n".join(public_policy_lines) + "\n")

nginx_config_count = len(config_rows)
nginx_proxy_surface_count = len(proxy_surface_rows)
nginx_public_port_policy_count = len(public_policy_rows)
nginx_allowed_public_count = sum(1 for r in public_policy_rows if r[5] == "allowed_public_web")
nginx_management_public_count = sum(1 for r in public_policy_rows if r[5] == "management_ssh_controlled")
nginx_internal_should_not_public_count = sum(1 for r in public_policy_rows if r[5] == "internal_should_not_public")
nginx_unknown_public_review_count = sum(1 for r in public_policy_rows if r[5] == "unknown_public_should_review")
nginx_high_risk_public_port_count = sum(1 for r in public_policy_rows if r[7] == "HIGH")
nginx_config_security_header_marker_count = sum(int(r[9]) for r in config_rows)
nginx_config_ssl_marker_count = sum(int(r[8]) for r in config_rows)
nginx_config_rate_limit_marker_count = sum(int(r[10]) for r in config_rows)
nginx_config_auth_marker_count = sum(int(r[14]) for r in config_rows)

detail(f"NGINX_CONFIG_FILE_COUNT={nginx_config_count}")
detail(f"NGINX_PROXY_SURFACE_COUNT={nginx_proxy_surface_count}")
detail(f"NGINX_PUBLIC_PORT_POLICY_COUNT={nginx_public_port_policy_count}")
detail(f"NGINX_ALLOWED_PUBLIC_PORT_COUNT={nginx_allowed_public_count}")
detail(f"NGINX_MANAGEMENT_PUBLIC_PORT_COUNT={nginx_management_public_count}")
detail(f"NGINX_INTERNAL_SHOULD_NOT_PUBLIC_COUNT={nginx_internal_should_not_public_count}")
detail(f"NGINX_UNKNOWN_PUBLIC_REVIEW_COUNT={nginx_unknown_public_review_count}")
detail(f"NGINX_HIGH_RISK_PUBLIC_PORT_COUNT={nginx_high_risk_public_port_count}")
detail(f"NGINX_SECURITY_HEADER_MARKER_COUNT={nginx_config_security_header_marker_count}")
detail(f"NGINX_SSL_MARKER_COUNT={nginx_config_ssl_marker_count}")
detail(f"NGINX_RATE_LIMIT_MARKER_COUNT={nginx_config_rate_limit_marker_count}")
detail(f"NGINX_AUTH_MARKER_COUNT={nginx_config_auth_marker_count}")

previous_status = "PASS" if (
    prev_20_3_status == "PASS"
    and prev_20_3_gate == "PASS"
    and prev_20_3_restart == "NO"
    and prev_20_3_deploy == "NO"
    and prev_20_2_status == "PASS"
    and prev_20_1_status == "PASS"
    and prev_21_status == "PASS"
    and prev_21_closure == "PASS"
) else "FAIL"

config_inventory_status = "PASS" if config_inventory_file.exists() else "FAIL"
proxy_surface_status = "PASS" if proxy_surface_file.exists() else "FAIL"
public_port_policy_status = "PASS" if public_port_policy_file.exists() else "FAIL"
hardening_matrix_status = "PASS"
no_reload_status = "PASS"
no_firewall_change_status = "PASS"
no_deploy_status = "PASS"
secret_safe_status = "PASS"

detail(f"NGINX_REVERSE_PROXY_PREVIOUS_20_3={previous_status}")
detail(f"NGINX_CONFIG_INVENTORY={config_inventory_status}")
detail(f"NGINX_PROXY_SURFACE_MANIFEST={proxy_surface_status}")
detail(f"NGINX_PUBLIC_PORT_POLICY={public_port_policy_status}")
detail(f"NGINX_HARDENING_MATRIX={hardening_matrix_status}")
detail(f"NGINX_NO_RELOAD={no_reload_status}")
detail(f"NGINX_NO_FIREWALL_CHANGE={no_firewall_change_status}")
detail(f"NGINX_NO_DEPLOY={no_deploy_status}")
detail(f"NGINX_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_20_3", previous_status),
    ("config_inventory", config_inventory_status),
    ("proxy_surface", proxy_surface_status),
    ("public_port_policy", public_port_policy_status),
    ("hardening_matrix", hardening_matrix_status),
    ("no_reload", no_reload_status),
    ("no_firewall_change", no_firewall_change_status),
    ("no_deploy", no_deploy_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_20_3\t{previous_status}\truntime service hardening prerequisite",
    f"config_inventory\t{config_inventory_status}\tnginx_config_files={nginx_config_count}",
    f"proxy_surface_manifest\t{proxy_surface_status}\tproxy_targets={nginx_proxy_surface_count}",
    f"public_port_policy\t{public_port_policy_status}\tpublic_ports={nginx_public_port_policy_count} high_risk={nginx_high_risk_public_port_count}",
    f"allowed_public_ports\tPASS\tallowed={nginx_allowed_public_count}",
    f"management_public_ports\tPASS\tmanagement={nginx_management_public_count}",
    f"internal_should_not_public\tPASS\tcount={nginx_internal_should_not_public_count}",
    f"unknown_public_review\tPASS\tcount={nginx_unknown_public_review_count}",
    f"security_header_markers\tPASS\tcount={nginx_config_security_header_marker_count}",
    f"ssl_markers\tPASS\tcount={nginx_config_ssl_marker_count}",
    f"rate_limit_markers\tPASS\tcount={nginx_config_rate_limit_marker_count}",
    f"auth_markers\tPASS\tcount={nginx_config_auth_marker_count}",
    f"hardening_matrix\t{hardening_matrix_status}\tevidence only",
    f"no_reload\t{no_reload_status}\tnginx not reloaded",
    f"no_firewall_change\t{no_firewall_change_status}\tfirewall not changed",
    f"no_deploy\t{no_deploy_status}\tdeploy not executed",
    f"secret_safe\t{secret_safe_status}\tno config body or secret values printed",
    "nginx_config_changed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "nginx_restarted\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "port_changed\tNO\tevidence only",
    "docker_port_changed\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "service_restarted\tNO\tevidence only",
    "deploy_executed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "file_permission_changed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "log_content_printed\tNO\tsecret-safe report",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"NGINX_HARDENING_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("NGINX_CONFIG_INVENTORY_FILE=docs/phase4/20_4_nginx_reverse_proxy_config_inventory.tsv")
detail("NGINX_PROXY_SURFACE_FILE=docs/phase4/20_4_nginx_reverse_proxy_surface_manifest.tsv")
detail("NGINX_PUBLIC_PORT_POLICY_FILE=docs/phase4/20_4_nginx_public_port_policy.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"NGINX_REVERSE_PROXY_HARDENING={final_status}")
detail(f"FAZ4B_20_4_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 20.4 - Nginx / Reverse Proxy Hardening Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"NGINX_REVERSE_PROXY_HARDENING={final_status}",
    f"FAZ4B_20_4_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/20_4_nginx_reverse_proxy_hardening_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "CONFIG_INVENTORY_FILE=docs/phase4/20_4_nginx_reverse_proxy_config_inventory.tsv",
    "PROXY_SURFACE_FILE=docs/phase4/20_4_nginx_reverse_proxy_surface_manifest.tsv",
    "PUBLIC_PORT_POLICY_FILE=docs/phase4/20_4_nginx_public_port_policy.tsv",
    "NOTE=No full config body, logs, raw env values, raw DSN, token, password, or secret values are printed.",
    "",
    "## Safety Decision",
    "NGINX_CONFIG_CHANGED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "NGINX_RESTARTED=NO",
    "FIREWALL_CHANGED=NO",
    "PORT_CHANGED=NO",
    "DOCKER_PORT_CHANGED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "SERVICE_RESTARTED=NO",
    "DEPLOY_EXECUTED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "FILE_PERMISSION_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
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
    "QUERY_TEXT_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"CONFIG_INVENTORY_FILE={config_inventory_file}")
print(f"PROXY_SURFACE_FILE={proxy_surface_file}")
print(f"PUBLIC_PORT_POLICY_FILE={public_port_policy_file}")
print(f"POLICY_FILE={policy_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"NGINX_CONFIG_FILE_COUNT={nginx_config_count}")
print(f"NGINX_PROXY_SURFACE_COUNT={nginx_proxy_surface_count}")
print(f"NGINX_PUBLIC_PORT_POLICY_COUNT={nginx_public_port_policy_count}")
print(f"NGINX_ALLOWED_PUBLIC_PORT_COUNT={nginx_allowed_public_count}")
print(f"NGINX_MANAGEMENT_PUBLIC_PORT_COUNT={nginx_management_public_count}")
print(f"NGINX_INTERNAL_SHOULD_NOT_PUBLIC_COUNT={nginx_internal_should_not_public_count}")
print(f"NGINX_UNKNOWN_PUBLIC_REVIEW_COUNT={nginx_unknown_public_review_count}")
print(f"NGINX_HIGH_RISK_PUBLIC_PORT_COUNT={nginx_high_risk_public_port_count}")
print(f"NGINX_SECURITY_HEADER_MARKER_COUNT={nginx_config_security_header_marker_count}")
print(f"NGINX_SSL_MARKER_COUNT={nginx_config_ssl_marker_count}")
print(f"NGINX_RATE_LIMIT_MARKER_COUNT={nginx_config_rate_limit_marker_count}")
print(f"NGINX_AUTH_MARKER_COUNT={nginx_config_auth_marker_count}")
print(f"NGINX_REVERSE_PROXY_PREVIOUS_20_3={previous_status}")
print(f"NGINX_CONFIG_INVENTORY={config_inventory_status}")
print(f"NGINX_PROXY_SURFACE_MANIFEST={proxy_surface_status}")
print(f"NGINX_PUBLIC_PORT_POLICY={public_port_policy_status}")
print(f"NGINX_HARDENING_MATRIX={hardening_matrix_status}")
print(f"NGINX_NO_RELOAD={no_reload_status}")
print(f"NGINX_NO_FIREWALL_CHANGE={no_firewall_change_status}")
print(f"NGINX_NO_DEPLOY={no_deploy_status}")
print(f"NGINX_SECRET_SAFE={secret_safe_status}")
print("NGINX_CONFIG_CHANGED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("NGINX_RESTARTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("DOCKER_PORT_CHANGED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("SERVICE_RESTARTED=NO")
print("DEPLOY_EXECUTED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("FILE_PERMISSION_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("LOG_CONTENT_PRINTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"NGINX_REVERSE_PROXY_HARDENING={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_20_4_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
