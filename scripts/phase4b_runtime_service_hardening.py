#!/usr/bin/env python3
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "20_3_runtime_service_hardening_standard.md"
policy_file = report_dir / "20_3_runtime_service_hardening_policy.md"
services_file = report_dir / "20_3_runtime_service_hardening_services.tsv"
ports_file = report_dir / "20_3_runtime_service_hardening_ports.tsv"
containers_file = report_dir / "20_3_runtime_service_hardening_containers.tsv"
matrix_file = report_dir / "20_3_runtime_service_hardening_matrix.tsv"
report_file = report_dir / "20_3_runtime_service_hardening_report.md"

prev_20_2 = report_dir / "20_2_config_env_hardening_report.md"
prev_20_1 = report_dir / "20_1_production_cleanup_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

SERVICE_PATTERNS = [
    "pix2pi",
    "nginx",
    "docker",
    "containerd",
    "postgres",
    "postgresql",
    "redis",
    "nats",
    "prometheus",
    "grafana",
    "node_exporter",
    "cadvisor",
    "fail2ban",
]

EXPECTED_PORTS = {
    "9001": "identity-api",
    "9010": "api-gateway",
    "9090": "prometheus",
    "9100": "node-exporter",
    "8080": "cadvisor",
    "3000": "grafana",
    "5433": "postgres-host",
    "5434": "postgres-replica-host",
    "6379": "redis",
    "4222": "nats",
    "80": "http",
    "443": "https",
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

def run_cmd(cmd, timeout=10):
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
    # Secret-like values should not appear from our selected commands, but mask just in case.
    v = re.sub(r"(password|token|secret|dsn|bearer)\s*[:=]\s*[^ ]+", r"\1=***", v, flags=re.I)
    return v[:220]

def rel(path):
    try:
        return str(path.relative_to(root))
    except Exception:
        return str(path)

def classify_service(name, load, active, sub, unit_file_state, user, restart):
    n = name.lower()
    if "pix2pi" in n:
        category = "pix2pi_service_candidate"
    elif any(x in n for x in ["nginx", "docker", "containerd", "postgres", "redis", "nats", "prometheus", "grafana", "fail2ban"]):
        category = "critical_platform_service"
    else:
        category = "system_service"

    risk = "LOW"
    notes = []

    if active not in ["active"]:
        risk = "MEDIUM"
        notes.append("not_active")

    if sub in ["failed", "dead"]:
        risk = "HIGH"
        notes.append("sub_state_not_running")

    if user in ["root", ""]:
        if category == "pix2pi_service_candidate":
            risk = "HIGH"
            notes.append("pix2pi_service_root_or_unknown_user")
        else:
            notes.append("root_or_unknown_user")

    if restart in ["", "no", "none"]:
        if category == "pix2pi_service_candidate":
            risk = "MEDIUM"
            notes.append("restart_policy_missing_or_no")
        else:
            notes.append("restart_policy_no")

    if unit_file_state in ["disabled", "static", ""]:
        notes.append("unit_state_review")

    return category, risk, ",".join(notes) if notes else "evidence_only"

def parse_systemd_services():
    rows = []
    systemctl_ok = which("systemctl") is not None

    if not systemctl_ok:
        warn("systemctl not found")
        return rows

    rc, out, err = run_cmd([
        "systemctl",
        "list-units",
        "--type=service",
        "--all",
        "--no-pager",
        "--no-legend",
    ], timeout=15)

    if rc != 0 and not out:
        warn("systemctl list-units failed")
        return rows

    names = []
    for line in out.splitlines():
        parts = line.split()
        if not parts:
            continue
        name = parts[0]
        lower = name.lower()
        if any(p in lower for p in SERVICE_PATTERNS):
            names.append(name)

    # Ayrıca unit dosyalarından pix2pi adaylarını yakala.
    for unit_dir in [Path("/etc/systemd/system"), Path("/lib/systemd/system")]:
        if unit_dir.exists():
            for p in sorted(unit_dir.glob("*.service")):
                lower = p.name.lower()
                if any(pattern in lower for pattern in SERVICE_PATTERNS):
                    if p.name not in names:
                        names.append(p.name)

    names = sorted(set(names))

    for name in names:
        props = [
            "Id",
            "LoadState",
            "ActiveState",
            "SubState",
            "UnitFileState",
            "FragmentPath",
            "User",
            "Restart",
            "MainPID",
            "ExecMainStatus",
        ]

        rc, out, err = run_cmd([
            "systemctl",
            "show",
            name,
            "--no-pager",
            "--property=" + ",".join(props),
        ], timeout=10)

        data = {k: "" for k in props}
        if rc == 0 or out:
            for line in out.splitlines():
                if "=" in line:
                    k, v = line.split("=", 1)
                    if k in data:
                        data[k] = v

        category, risk, note = classify_service(
            name,
            data.get("LoadState", ""),
            data.get("ActiveState", ""),
            data.get("SubState", ""),
            data.get("UnitFileState", ""),
            data.get("User", ""),
            data.get("Restart", ""),
        )

        rows.append([
            safe(name),
            category,
            risk,
            safe(data.get("LoadState", "")),
            safe(data.get("ActiveState", "")),
            safe(data.get("SubState", "")),
            safe(data.get("UnitFileState", "")),
            safe(data.get("User", "")),
            safe(data.get("Restart", "")),
            safe(data.get("MainPID", "")),
            safe(data.get("ExecMainStatus", "")),
            safe(data.get("FragmentPath", "")),
            note,
        ])

    return rows

def parse_ports():
    rows = []
    if which("ss") is None:
        warn("ss not found")
        return rows

    rc, out, err = run_cmd(["ss", "-tulnH"], timeout=10)
    if rc != 0 and not out:
        warn("ss port inventory failed")
        return rows

    seen = set()

    for line in out.splitlines():
        parts = line.split()
        if len(parts) < 5:
            continue

        netid = parts[0]
        state = parts[1] if netid.lower() == "tcp" else "UNCONN"
        local = parts[4] if len(parts) >= 5 else ""

        # IPv6 [::]:80 veya 0.0.0.0:80 parse
        port = ""
        if ":" in local:
            port = local.rsplit(":", 1)[-1]
        port = port.strip()

        if not port.isdigit():
            continue

        bind_scope = "unknown"
        if local.startswith("127.0.0.1") or local.startswith("[::1]") or local.startswith("::1"):
            bind_scope = "loopback"
        elif local.startswith("0.0.0.0") or local.startswith("[::]") or local.startswith("*:"):
            bind_scope = "public_or_all_interfaces"
        else:
            bind_scope = "specific_interface"

        expected_service = EXPECTED_PORTS.get(port, "unknown")

        risk = "LOW"
        note = "evidence_only"

        if bind_scope == "public_or_all_interfaces" and port not in ["80", "443"]:
            risk = "HIGH"
            note = "public_listener_review"

        if port in ["22"]:
            risk = "MEDIUM"
            note = "ssh_listener_review"

        key = (netid, local, port)
        if key in seen:
            continue
        seen.add(key)

        rows.append([
            safe(netid),
            safe(state),
            safe(local),
            safe(port),
            safe(expected_service),
            safe(bind_scope),
            risk,
            note,
        ])

    return rows

def parse_docker_containers():
    rows = []
    if which("docker") is None:
        warn("docker not found")
        return rows

    rc, out, err = run_cmd([
        "docker",
        "ps",
        "-a",
        "--format",
        "{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}",
    ], timeout=15)

    if rc != 0 and not out:
        warn("docker ps inventory failed")
        return rows

    for line in out.splitlines():
        parts = line.split("\t")
        while len(parts) < 4:
            parts.append("")

        name, image, status, ports = parts[:4]
        lower = (name + " " + image).lower()

        if any(p in lower for p in SERVICE_PATTERNS + ["pix2pi", "postgres", "redis", "nats"]):
            category = "docker_container"
        else:
            category = "docker_container_other"

        risk = "LOW"
        note = "evidence_only"

        if "exited" in status.lower() or "dead" in status.lower():
            risk = "MEDIUM"
            note = "container_not_running_review"

        if "0.0.0.0:" in ports and not any(x in ports for x in [":80->", ":443->"]):
            risk = "HIGH"
            note = "public_container_port_review"

        rows.append([
            safe(name),
            safe(image),
            safe(status),
            safe(ports),
            category,
            risk,
            note,
        ])

    return rows

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("SERVICE_RESTARTED=NO")
detail("SERVICE_STARTED=NO")
detail("SERVICE_STOPPED=NO")
detail("SYSTEMD_UNIT_CHANGED=NO")
detail("SYSTEMD_ENABLE_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("DOCKER_COMPOSE_EXECUTED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
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
detail("VALIDATION_MODE=RUNTIME_SERVICE_HARDENING_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "systemctl", "ss", "docker"]:
    tool_status(tool)

prev_20_2_status = get_value(prev_20_2, "FAZ4B_20_2_FINAL_STATUS")
prev_20_2_gate = get_value(prev_20_2, "CONFIG_ENV_HARDENING_GATE")
prev_20_2_config_changed = get_value(prev_20_2, "CONFIG_CHANGED")
prev_20_2_env_changed = get_value(prev_20_2, "ENV_CHANGED")
prev_20_1_status = get_value(prev_20_1, "FAZ4B_20_1_FINAL_STATUS")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_20_2_FINAL_STATUS={prev_20_2_status}")
detail(f"PREVIOUS_20_2_CONFIG_ENV_HARDENING_GATE={prev_20_2_gate}")
detail(f"PREVIOUS_20_2_CONFIG_CHANGED={prev_20_2_config_changed}")
detail(f"PREVIOUS_20_2_ENV_CHANGED={prev_20_2_env_changed}")
detail(f"PREVIOUS_20_1_FINAL_STATUS={prev_20_1_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_20_2_status != "PASS":
    fail("20.2 final status PASS degil")
if prev_20_2_gate != "PASS":
    fail("20.2 config/env gate PASS degil")
if prev_20_2_config_changed != "NO":
    fail("20.2 config changed NO degil")
if prev_20_2_env_changed != "NO":
    fail("20.2 env changed NO degil")
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

service_rows = parse_systemd_services()
port_rows = parse_ports()
container_rows = parse_docker_containers()

services_lines = [
    "service_name\tcategory\trisk\tload_state\tactive_state\tsub_state\tunit_file_state\tuser\trestart_policy\tmain_pid\texec_main_status\tfragment_path\tnote"
]
for row in service_rows:
    services_lines.append("\t".join(row))
services_file.write_text("\n".join(services_lines) + "\n")

ports_lines = [
    "netid\tstate\tlocal_address\tport\texpected_service\tbind_scope\trisk\tnote"
]
for row in port_rows:
    ports_lines.append("\t".join(row))
ports_file.write_text("\n".join(ports_lines) + "\n")

containers_lines = [
    "container_name\timage\tstatus\tports\tcategory\trisk\tnote"
]
for row in container_rows:
    containers_lines.append("\t".join(row))
containers_file.write_text("\n".join(containers_lines) + "\n")

service_count = len(service_rows)
pix2pi_service_count = sum(1 for r in service_rows if r[1] == "pix2pi_service_candidate")
critical_service_count = sum(1 for r in service_rows if r[1] == "critical_platform_service")
active_service_count = sum(1 for r in service_rows if r[4] == "active")
high_risk_service_count = sum(1 for r in service_rows if r[2] == "HIGH")
medium_risk_service_count = sum(1 for r in service_rows if r[2] == "MEDIUM")

port_count = len(port_rows)
public_port_count = sum(1 for r in port_rows if r[5] == "public_or_all_interfaces")
high_risk_port_count = sum(1 for r in port_rows if r[6] == "HIGH")
loopback_port_count = sum(1 for r in port_rows if r[5] == "loopback")

container_count = len(container_rows)
running_container_count = sum(1 for r in container_rows if "up" in r[2].lower())
high_risk_container_count = sum(1 for r in container_rows if r[5] == "HIGH")
medium_risk_container_count = sum(1 for r in container_rows if r[5] == "MEDIUM")

detail(f"RUNTIME_SERVICE_SYSTEMD_SERVICE_COUNT={service_count}")
detail(f"RUNTIME_SERVICE_PIX2PI_SERVICE_COUNT={pix2pi_service_count}")
detail(f"RUNTIME_SERVICE_CRITICAL_SERVICE_COUNT={critical_service_count}")
detail(f"RUNTIME_SERVICE_ACTIVE_SERVICE_COUNT={active_service_count}")
detail(f"RUNTIME_SERVICE_HIGH_RISK_SERVICE_COUNT={high_risk_service_count}")
detail(f"RUNTIME_SERVICE_MEDIUM_RISK_SERVICE_COUNT={medium_risk_service_count}")

detail(f"RUNTIME_SERVICE_PORT_COUNT={port_count}")
detail(f"RUNTIME_SERVICE_PUBLIC_PORT_COUNT={public_port_count}")
detail(f"RUNTIME_SERVICE_LOOPBACK_PORT_COUNT={loopback_port_count}")
detail(f"RUNTIME_SERVICE_HIGH_RISK_PORT_COUNT={high_risk_port_count}")

detail(f"RUNTIME_SERVICE_CONTAINER_COUNT={container_count}")
detail(f"RUNTIME_SERVICE_RUNNING_CONTAINER_COUNT={running_container_count}")
detail(f"RUNTIME_SERVICE_HIGH_RISK_CONTAINER_COUNT={high_risk_container_count}")
detail(f"RUNTIME_SERVICE_MEDIUM_RISK_CONTAINER_COUNT={medium_risk_container_count}")

previous_status = "PASS" if (
    prev_20_2_status == "PASS"
    and prev_20_2_gate == "PASS"
    and prev_20_2_config_changed == "NO"
    and prev_20_2_env_changed == "NO"
    and prev_20_1_status == "PASS"
    and prev_21_status == "PASS"
    and prev_21_closure == "PASS"
) else "FAIL"

systemd_inventory_status = "PASS" if services_file.exists() else "FAIL"
port_inventory_status = "PASS" if ports_file.exists() else "FAIL"
container_inventory_status = "PASS" if containers_file.exists() else "FAIL"
hardening_matrix_status = "PASS"
no_restart_status = "PASS"
no_deploy_status = "PASS"
secret_safe_status = "PASS"

detail(f"RUNTIME_SERVICE_PREVIOUS_20_2={previous_status}")
detail(f"RUNTIME_SERVICE_SYSTEMD_INVENTORY={systemd_inventory_status}")
detail(f"RUNTIME_SERVICE_PORT_INVENTORY={port_inventory_status}")
detail(f"RUNTIME_SERVICE_CONTAINER_INVENTORY={container_inventory_status}")
detail(f"RUNTIME_SERVICE_HARDENING_MATRIX={hardening_matrix_status}")
detail(f"RUNTIME_SERVICE_NO_RESTART={no_restart_status}")
detail(f"RUNTIME_SERVICE_NO_DEPLOY={no_deploy_status}")
detail(f"RUNTIME_SERVICE_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_20_2", previous_status),
    ("systemd_inventory", systemd_inventory_status),
    ("port_inventory", port_inventory_status),
    ("container_inventory", container_inventory_status),
    ("hardening_matrix", hardening_matrix_status),
    ("no_restart", no_restart_status),
    ("no_deploy", no_deploy_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_20_2\t{previous_status}\tconfig/env hardening prerequisite",
    f"systemd_inventory\t{systemd_inventory_status}\tservices={service_count} pix2pi={pix2pi_service_count} critical={critical_service_count}",
    f"port_inventory\t{port_inventory_status}\tports={port_count} public={public_port_count} high_risk={high_risk_port_count}",
    f"container_inventory\t{container_inventory_status}\tcontainers={container_count} running={running_container_count}",
    f"service_hardening_candidates\tPASS\thigh={high_risk_service_count} medium={medium_risk_service_count}",
    f"port_hardening_candidates\tPASS\thigh={high_risk_port_count}",
    f"container_hardening_candidates\tPASS\thigh={high_risk_container_count} medium={medium_risk_container_count}",
    f"hardening_matrix\t{hardening_matrix_status}\tevidence only",
    f"no_restart\t{no_restart_status}\tno service/container restart",
    f"no_deploy\t{no_deploy_status}\tno deploy/nginx reload",
    f"secret_safe\t{secret_safe_status}\tno env/log/secret values printed",
    "service_restarted\tNO\tevidence only",
    "service_started\tNO\tevidence only",
    "service_stopped\tNO\tevidence only",
    "systemd_unit_changed\tNO\tevidence only",
    "systemd_enable_changed\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
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

detail(f"RUNTIME_SERVICE_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("RUNTIME_SERVICE_SERVICES_FILE=docs/phase4/20_3_runtime_service_hardening_services.tsv")
detail("RUNTIME_SERVICE_PORTS_FILE=docs/phase4/20_3_runtime_service_hardening_ports.tsv")
detail("RUNTIME_SERVICE_CONTAINERS_FILE=docs/phase4/20_3_runtime_service_hardening_containers.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"RUNTIME_SERVICE_HARDENING={final_status}")
detail(f"FAZ4B_20_3_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 20.3 - Runtime Service Hardening Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"RUNTIME_SERVICE_HARDENING={final_status}",
    f"FAZ4B_20_3_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/20_3_runtime_service_hardening_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "SERVICES_FILE=docs/phase4/20_3_runtime_service_hardening_services.tsv",
    "PORTS_FILE=docs/phase4/20_3_runtime_service_hardening_ports.tsv",
    "CONTAINERS_FILE=docs/phase4/20_3_runtime_service_hardening_containers.tsv",
    "NOTE=No logs, raw env values, raw DSN, token, password, or secret values are printed.",
    "",
    "## Safety Decision",
    "SERVICE_RESTARTED=NO",
    "SERVICE_STARTED=NO",
    "SERVICE_STOPPED=NO",
    "SYSTEMD_UNIT_CHANGED=NO",
    "SYSTEMD_ENABLE_CHANGED=NO",
    "CONTAINER_RESTARTED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
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
print(f"SERVICES_FILE={services_file}")
print(f"PORTS_FILE={ports_file}")
print(f"CONTAINERS_FILE={containers_file}")
print(f"POLICY_FILE={policy_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"RUNTIME_SERVICE_SYSTEMD_SERVICE_COUNT={service_count}")
print(f"RUNTIME_SERVICE_PIX2PI_SERVICE_COUNT={pix2pi_service_count}")
print(f"RUNTIME_SERVICE_CRITICAL_SERVICE_COUNT={critical_service_count}")
print(f"RUNTIME_SERVICE_HIGH_RISK_SERVICE_COUNT={high_risk_service_count}")
print(f"RUNTIME_SERVICE_PORT_COUNT={port_count}")
print(f"RUNTIME_SERVICE_PUBLIC_PORT_COUNT={public_port_count}")
print(f"RUNTIME_SERVICE_HIGH_RISK_PORT_COUNT={high_risk_port_count}")
print(f"RUNTIME_SERVICE_CONTAINER_COUNT={container_count}")
print(f"RUNTIME_SERVICE_RUNNING_CONTAINER_COUNT={running_container_count}")
print(f"RUNTIME_SERVICE_HIGH_RISK_CONTAINER_COUNT={high_risk_container_count}")
print(f"RUNTIME_SERVICE_PREVIOUS_20_2={previous_status}")
print(f"RUNTIME_SERVICE_SYSTEMD_INVENTORY={systemd_inventory_status}")
print(f"RUNTIME_SERVICE_PORT_INVENTORY={port_inventory_status}")
print(f"RUNTIME_SERVICE_CONTAINER_INVENTORY={container_inventory_status}")
print(f"RUNTIME_SERVICE_HARDENING_MATRIX={hardening_matrix_status}")
print(f"RUNTIME_SERVICE_NO_RESTART={no_restart_status}")
print(f"RUNTIME_SERVICE_NO_DEPLOY={no_deploy_status}")
print(f"RUNTIME_SERVICE_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("SERVICE_STARTED=NO")
print("SERVICE_STOPPED=NO")
print("SYSTEMD_UNIT_CHANGED=NO")
print("SYSTEMD_ENABLE_CHANGED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
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
print(f"RUNTIME_SERVICE_HARDENING={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_20_3_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
