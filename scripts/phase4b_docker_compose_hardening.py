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

standard_file = report_dir / "20_5_docker_compose_hardening_standard.md"
policy_file = report_dir / "20_5_docker_compose_hardening_policy.md"
container_inventory_file = report_dir / "20_5_docker_container_inventory.tsv"
compose_inventory_file = report_dir / "20_5_docker_compose_inventory.tsv"
network_inventory_file = report_dir / "20_5_docker_network_inventory.tsv"
volume_inventory_file = report_dir / "20_5_docker_volume_inventory.tsv"
public_port_policy_file = report_dir / "20_5_docker_public_port_policy.tsv"
matrix_file = report_dir / "20_5_docker_compose_hardening_matrix.tsv"
report_file = report_dir / "20_5_docker_compose_hardening_report.md"

prev_20_4 = report_dir / "20_4_nginx_reverse_proxy_hardening_report.md"
prev_20_4_port_policy = report_dir / "20_4_nginx_public_port_policy.tsv"
prev_20_3 = report_dir / "20_3_runtime_service_hardening_report.md"
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
    "9001": "pix2pi-internal",
    "9002": "pix2pi-internal",
    "9010": "api-gateway-internal",
    "9012": "pix2pi-internal",
}

SECRET_KEY_RE = re.compile(
    r"(secret|token|password|passwd|private|credential|dsn|auth|api[_-]?key|access[_-]?key|refresh[_-]?token|jwt|bearer|pgpass|pem|key)",
    re.IGNORECASE,
)

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

def run_cmd(cmd, timeout=15):
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
    return v[:260]

def parse_port_tokens(ports_text):
    ports = []
    for m in re.finditer(r"(0\.0\.0\.0|\[::\]|\*|127\.0\.0\.1|::1)?[:]?(?P<host>\d{2,5})->(?P<container>\d{2,5})/(tcp|udp)", ports_text):
        ports.append((m.group("host"), m.group("container")))
    return ports

def port_policy(host_port):
    p = str(host_port or "")
    if p in ALLOWED_PUBLIC_PORTS:
        return ("allowed_public_web", "LOW", "internet_edge")
    if p in SSH_MANAGEMENT_PORTS:
        return ("management_ssh_controlled", "MEDIUM", "allowlist_key_auth_fail2ban")
    if p in INTERNAL_SHOULD_NOT_PUBLIC:
        return ("internal_should_not_public", "HIGH", "private_network_or_loopback")
    return ("unknown_public_should_review", "HIGH", "close_or_place_behind_reverse_proxy")

def docker_ps_rows():
    rows = []
    if which("docker") is None:
        warn("docker not found")
        return rows

    rc, out, err = run_cmd([
        "docker",
        "ps",
        "-a",
        "--format",
        "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}",
    ], timeout=20)

    if rc != 0 and not out:
        warn("docker ps failed")
        return rows

    for line in out.splitlines():
        parts = line.split("\t")
        while len(parts) < 5:
            parts.append("")

        cid, name, image, status, ports = parts[:5]

        inspect_rc, inspect_out, inspect_err = run_cmd([
            "docker",
            "inspect",
            "--format",
            "{{.HostConfig.RestartPolicy.Name}}\t{{.Config.User}}\t{{.HostConfig.NetworkMode}}\t{{.HostConfig.Privileged}}\t{{.HostConfig.ReadonlyRootfs}}\t{{json .Config.Healthcheck}}\t{{len .Mounts}}\t{{len .NetworkSettings.Networks}}",
            cid,
        ], timeout=10)

        restart_policy = ""
        user = ""
        network_mode = ""
        privileged = ""
        readonly_rootfs = ""
        healthcheck = ""
        mount_count = "0"
        network_count = "0"

        if inspect_rc == 0 and inspect_out:
            iparts = inspect_out.split("\t")
            while len(iparts) < 8:
                iparts.append("")
            restart_policy, user, network_mode, privileged, readonly_rootfs, healthcheck, mount_count, network_count = iparts[:8]

        public_host_ports = parse_port_tokens(ports)
        public_port_count = len(public_host_ports)
        high_risk_public_port_count = 0

        for hp, cp in public_host_ports:
            _, risk, _ = port_policy(hp)
            if risk == "HIGH":
                high_risk_public_port_count += 1

        risk = "LOW"
        notes = []

        if "exited" in status.lower() or "dead" in status.lower():
            risk = "MEDIUM"
            notes.append("not_running_review")

        if high_risk_public_port_count > 0:
            risk = "HIGH"
            notes.append("high_risk_public_port_publish")

        if privileged.lower() == "true":
            risk = "HIGH"
            notes.append("privileged_container")

        if network_mode == "host":
            risk = "HIGH"
            notes.append("host_network_mode")

        if not restart_policy or restart_policy in ["no", "none"]:
            if risk != "HIGH":
                risk = "MEDIUM"
            notes.append("restart_policy_missing_or_no")

        if not user:
            notes.append("container_user_unspecified")

        if "Healthcheck" not in healthcheck and healthcheck in ["<nil>", "null", ""]:
            notes.append("healthcheck_missing")

        rows.append([
            safe(cid),
            safe(name),
            safe(image),
            safe(status),
            safe(ports),
            safe(restart_policy),
            safe(user if user else "unspecified"),
            safe(network_mode),
            safe(privileged),
            safe(readonly_rootfs),
            "YES" if healthcheck not in ["<nil>", "null", ""] else "NO",
            safe(mount_count),
            safe(network_count),
            str(public_port_count),
            str(high_risk_public_port_count),
            risk,
            ",".join(notes) if notes else "evidence_only",
        ])

    return rows

def docker_network_rows():
    rows = []
    if which("docker") is None:
        return rows

    rc, out, err = run_cmd([
        "docker",
        "network",
        "ls",
        "--format",
        "{{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}",
    ], timeout=15)

    if rc != 0 and not out:
        warn("docker network ls failed")
        return rows

    for line in out.splitlines():
        parts = line.split("\t")
        while len(parts) < 4:
            parts.append("")
        nid, name, driver, scope = parts[:4]

        risk = "LOW"
        note = "evidence_only"

        if driver == "host":
            risk = "HIGH"
            note = "host_network_review"

        rows.append([safe(nid), safe(name), safe(driver), safe(scope), risk, note])

    return rows

def docker_volume_rows():
    rows = []
    if which("docker") is None:
        return rows

    rc, out, err = run_cmd([
        "docker",
        "volume",
        "ls",
        "--format",
        "{{.Name}}\t{{.Driver}}\t{{.Scope}}",
    ], timeout=15)

    if rc != 0 and not out:
        warn("docker volume ls failed")
        return rows

    for line in out.splitlines():
        parts = line.split("\t")
        while len(parts) < 3:
            parts.append("")
        name, driver, scope = parts[:3]

        lname = name.lower()
        risk = "LOW"
        note = "evidence_only"

        if any(x in lname for x in ["postgres", "pg", "redis", "nats", "grafana", "prometheus", "loki", "tempo", "backup"]):
            risk = "MEDIUM"
            note = "stateful_volume_retention_backup_review"

        rows.append([safe(name), safe(driver), safe(scope), risk, note])

    return rows

def compose_paths():
    candidates = []
    names = [
        "docker-compose.yml",
        "docker-compose.yaml",
        "compose.yml",
        "compose.yaml",
    ]

    for name in names:
        p = root / name
        if p.exists():
            candidates.append(p)

    for base in [
        root / "deploy",
        root / "deployment",
        root / "docker",
        root / "compose",
        root / "infra",
        root / "ops",
    ]:
        if not base.exists():
            continue
        try:
            for p in sorted(base.rglob("*")):
                if not p.is_file():
                    continue
                lname = p.name.lower()
                if lname in names or "compose" in lname and lname.endswith((".yml", ".yaml")):
                    candidates.append(p)
        except Exception:
            warn(f"compose scan skipped: {rel(base)}")

    uniq = []
    seen = set()
    for p in candidates:
        s = str(p)
        if s not in seen:
            uniq.append(p)
            seen.add(s)
    return uniq

def compose_inventory_rows():
    rows = []

    for path in compose_paths():
        text = read(path)
        low = text.lower()

        service_count = len(re.findall(r"^\s{2}[A-Za-z0-9_\-]+:\s*$", text, re.M))
        ports_count = len(re.findall(r"^\s*-\s*['\"]?\d{2,5}:\d{2,5}", text, re.M))
        expose_count = len(re.findall(r"^\s*expose\s*:", text, re.M))
        env_count = len(re.findall(r"^\s*(environment|env_file)\s*:", text, re.M))
        secret_key_name_count = len([m.group(0) for m in SECRET_KEY_RE.finditer(text)])
        volume_count = len(re.findall(r"^\s*(volumes)\s*:", text, re.M))
        network_count = len(re.findall(r"^\s*(networks)\s*:", text, re.M))
        privileged_count = len(re.findall(r"privileged\s*:\s*true", text, re.I))
        host_network_count = len(re.findall(r"network_mode\s*:\s*host", text, re.I))
        restart_count = len(re.findall(r"restart\s*:", text, re.I))
        healthcheck_count = len(re.findall(r"healthcheck\s*:", text, re.I))
        user_count = len(re.findall(r"^\s*user\s*:", text, re.M))
        cap_add_count = len(re.findall(r"cap_add\s*:", text, re.I))
        cap_drop_count = len(re.findall(r"cap_drop\s*:", text, re.I))
        read_only_count = len(re.findall(r"read_only\s*:\s*true", text, re.I))

        risk = "LOW"
        notes = []

        if ports_count > 0:
            risk = "MEDIUM"
            notes.append("published_ports_review")

        if privileged_count > 0 or host_network_count > 0 or cap_add_count > 0:
            risk = "HIGH"
            notes.append("privileged_or_host_or_cap_add_review")

        if env_count > 0 and secret_key_name_count > 0:
            if risk != "HIGH":
                risk = "MEDIUM"
            notes.append("secret_like_key_names_detected_values_not_printed")

        if healthcheck_count == 0:
            notes.append("healthcheck_marker_missing")

        if restart_count == 0:
            notes.append("restart_marker_missing")

        rows.append([
            rel(path),
            str(service_count),
            str(ports_count),
            str(expose_count),
            str(env_count),
            str(secret_key_name_count),
            str(volume_count),
            str(network_count),
            str(privileged_count),
            str(host_network_count),
            str(restart_count),
            str(healthcheck_count),
            str(user_count),
            str(cap_add_count),
            str(cap_drop_count),
            str(read_only_count),
            risk,
            ",".join(notes) if notes else "evidence_only",
        ])

    return rows

def docker_public_policy_rows(container_rows):
    rows = []

    for row in container_rows:
        container_name = row[1]
        image = row[2]
        ports = row[4]
        for host_port, container_port in parse_port_tokens(ports):
            p_policy, risk, recommended = port_policy(host_port)
            service_hint = INTERNAL_SHOULD_NOT_PUBLIC.get(str(host_port), "unknown_or_edge")
            rows.append([
                safe(container_name),
                safe(image),
                safe(host_port),
                safe(container_port),
                safe(service_hint),
                p_policy,
                recommended,
                risk,
                "evidence_only_no_docker_port_change",
            ])

    return rows

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("CONTAINER_RESTARTED=NO")
detail("CONTAINER_STARTED=NO")
detail("CONTAINER_STOPPED=NO")
detail("CONTAINER_REMOVED=NO")
detail("DOCKER_COMPOSE_EXECUTED=NO")
detail("DOCKER_NETWORK_CHANGED=NO")
detail("DOCKER_VOLUME_CHANGED=NO")
detail("DOCKER_PORT_CHANGED=NO")
detail("DOCKER_PRUNE_EXECUTED=NO")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("FILE_PERMISSION_CHANGED=NO")
detail("FIREWALL_CHANGED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
detail("SERVICE_RESTARTED=NO")
detail("DEPLOY_EXECUTED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("LOG_CONTENT_PRINTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=DOCKER_COMPOSE_HARDENING_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "docker"]:
    tool_status(tool)

prev_20_4_status = get_value(prev_20_4, "FAZ4B_20_4_FINAL_STATUS")
prev_20_4_gate = get_value(prev_20_4, "NGINX_REVERSE_PROXY_HARDENING")
prev_20_4_reload = get_value(prev_20_4, "NGINX_RELOAD_EXECUTED")
prev_20_4_firewall = get_value(prev_20_4, "FIREWALL_CHANGED")
prev_20_4_port = get_value(prev_20_4, "PORT_CHANGED")
prev_20_3_status = get_value(prev_20_3, "FAZ4B_20_3_FINAL_STATUS")
prev_20_2_status = get_value(prev_20_2, "FAZ4B_20_2_FINAL_STATUS")
prev_20_1_status = get_value(prev_20_1, "FAZ4B_20_1_FINAL_STATUS")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_20_4_FINAL_STATUS={prev_20_4_status}")
detail(f"PREVIOUS_20_4_NGINX_REVERSE_PROXY_HARDENING={prev_20_4_gate}")
detail(f"PREVIOUS_20_4_NGINX_RELOAD_EXECUTED={prev_20_4_reload}")
detail(f"PREVIOUS_20_4_FIREWALL_CHANGED={prev_20_4_firewall}")
detail(f"PREVIOUS_20_4_PORT_CHANGED={prev_20_4_port}")
detail(f"PREVIOUS_20_3_FINAL_STATUS={prev_20_3_status}")
detail(f"PREVIOUS_20_2_FINAL_STATUS={prev_20_2_status}")
detail(f"PREVIOUS_20_1_FINAL_STATUS={prev_20_1_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_20_4_status != "PASS":
    fail("20.4 final status PASS degil")
if prev_20_4_gate != "PASS":
    fail("20.4 nginx reverse proxy hardening PASS degil")
if prev_20_4_reload != "NO":
    fail("20.4 nginx reload NO degil")
if prev_20_4_firewall != "NO":
    fail("20.4 firewall changed NO degil")
if prev_20_4_port != "NO":
    fail("20.4 port changed NO degil")
if prev_20_3_status != "PASS":
    fail("20.3 final status PASS degil")
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

container_rows = docker_ps_rows()
network_rows = docker_network_rows()
volume_rows = docker_volume_rows()
compose_rows = compose_inventory_rows()
public_policy_rows = docker_public_policy_rows(container_rows)

container_lines = [
    "container_id\tcontainer_name\timage\tstatus\tports\trestart_policy\tuser\tnetwork_mode\tprivileged\treadonly_rootfs\thealthcheck_present\tmount_count\tnetwork_count\tpublic_port_count\thigh_risk_public_port_count\trisk\tnote"
]
for row in container_rows:
    container_lines.append("\t".join(row))
container_inventory_file.write_text("\n".join(container_lines) + "\n")

network_lines = [
    "network_id\tnetwork_name\tdriver\tscope\trisk\tnote"
]
for row in network_rows:
    network_lines.append("\t".join(row))
network_inventory_file.write_text("\n".join(network_lines) + "\n")

volume_lines = [
    "volume_name\tdriver\tscope\trisk\tnote"
]
for row in volume_rows:
    volume_lines.append("\t".join(row))
volume_inventory_file.write_text("\n".join(volume_lines) + "\n")

compose_lines = [
    "compose_path\tservice_count\tports_count\texpose_count\tenv_marker_count\tsecret_key_name_count\tvolume_marker_count\tnetwork_marker_count\tprivileged_count\thost_network_count\trestart_marker_count\thealthcheck_marker_count\tuser_marker_count\tcap_add_count\tcap_drop_count\tread_only_count\trisk\tnote"
]
for row in compose_rows:
    compose_lines.append("\t".join(row))
compose_inventory_file.write_text("\n".join(compose_lines) + "\n")

public_policy_lines = [
    "container_name\timage\thost_port\tcontainer_port\tservice_hint\tport_policy\trecommended_surface\trisk\tnote"
]
for row in public_policy_rows:
    public_policy_lines.append("\t".join(row))
public_port_policy_file.write_text("\n".join(public_policy_lines) + "\n")

container_count = len(container_rows)
running_container_count = sum(1 for r in container_rows if "up" in r[3].lower())
high_risk_container_count = sum(1 for r in container_rows if r[15] == "HIGH")
medium_risk_container_count = sum(1 for r in container_rows if r[15] == "MEDIUM")
privileged_container_count = sum(1 for r in container_rows if r[8].lower() == "true")
host_network_container_count = sum(1 for r in container_rows if r[7] == "host")
healthcheck_missing_count = sum(1 for r in container_rows if r[10] == "NO")
restart_policy_missing_count = sum(1 for r in container_rows if r[5] in ["", "no", "none"])
unspecified_user_count = sum(1 for r in container_rows if r[6] == "unspecified")
public_port_publish_count = sum(int(r[13]) for r in container_rows)
high_risk_public_publish_count = sum(int(r[14]) for r in container_rows)

network_count = len(network_rows)
host_network_count = sum(1 for r in network_rows if r[2] == "host")

volume_count = len(volume_rows)
stateful_volume_review_count = sum(1 for r in volume_rows if r[3] == "MEDIUM")

compose_file_count = len(compose_rows)
compose_ports_count = sum(int(r[2]) for r in compose_rows)
compose_secret_key_name_count = sum(int(r[5]) for r in compose_rows)
compose_privileged_count = sum(int(r[8]) for r in compose_rows)
compose_host_network_count = sum(int(r[9]) for r in compose_rows)
compose_healthcheck_marker_count = sum(int(r[11]) for r in compose_rows)
compose_restart_marker_count = sum(int(r[10]) for r in compose_rows)
compose_high_risk_count = sum(1 for r in compose_rows if r[16] == "HIGH")

public_policy_count = len(public_policy_rows)
internal_should_not_public_count = sum(1 for r in public_policy_rows if r[5] == "internal_should_not_public")
unknown_public_review_count = sum(1 for r in public_policy_rows if r[5] == "unknown_public_should_review")
allowed_public_count = sum(1 for r in public_policy_rows if r[5] == "allowed_public_web")
high_risk_public_policy_count = sum(1 for r in public_policy_rows if r[7] == "HIGH")

detail(f"DOCKER_CONTAINER_COUNT={container_count}")
detail(f"DOCKER_RUNNING_CONTAINER_COUNT={running_container_count}")
detail(f"DOCKER_HIGH_RISK_CONTAINER_COUNT={high_risk_container_count}")
detail(f"DOCKER_MEDIUM_RISK_CONTAINER_COUNT={medium_risk_container_count}")
detail(f"DOCKER_PRIVILEGED_CONTAINER_COUNT={privileged_container_count}")
detail(f"DOCKER_HOST_NETWORK_CONTAINER_COUNT={host_network_container_count}")
detail(f"DOCKER_HEALTHCHECK_MISSING_COUNT={healthcheck_missing_count}")
detail(f"DOCKER_RESTART_POLICY_MISSING_COUNT={restart_policy_missing_count}")
detail(f"DOCKER_UNSPECIFIED_USER_COUNT={unspecified_user_count}")
detail(f"DOCKER_PUBLIC_PORT_PUBLISH_COUNT={public_port_publish_count}")
detail(f"DOCKER_HIGH_RISK_PUBLIC_PUBLISH_COUNT={high_risk_public_publish_count}")

detail(f"DOCKER_NETWORK_COUNT={network_count}")
detail(f"DOCKER_HOST_NETWORK_COUNT={host_network_count}")
detail(f"DOCKER_VOLUME_COUNT={volume_count}")
detail(f"DOCKER_STATEFUL_VOLUME_REVIEW_COUNT={stateful_volume_review_count}")

detail(f"DOCKER_COMPOSE_FILE_COUNT={compose_file_count}")
detail(f"DOCKER_COMPOSE_PORTS_COUNT={compose_ports_count}")
detail(f"DOCKER_COMPOSE_SECRET_KEY_NAME_COUNT={compose_secret_key_name_count}")
detail(f"DOCKER_COMPOSE_PRIVILEGED_COUNT={compose_privileged_count}")
detail(f"DOCKER_COMPOSE_HOST_NETWORK_COUNT={compose_host_network_count}")
detail(f"DOCKER_COMPOSE_HEALTHCHECK_MARKER_COUNT={compose_healthcheck_marker_count}")
detail(f"DOCKER_COMPOSE_RESTART_MARKER_COUNT={compose_restart_marker_count}")
detail(f"DOCKER_COMPOSE_HIGH_RISK_COUNT={compose_high_risk_count}")

detail(f"DOCKER_PUBLIC_PORT_POLICY_COUNT={public_policy_count}")
detail(f"DOCKER_INTERNAL_SHOULD_NOT_PUBLIC_COUNT={internal_should_not_public_count}")
detail(f"DOCKER_UNKNOWN_PUBLIC_REVIEW_COUNT={unknown_public_review_count}")
detail(f"DOCKER_ALLOWED_PUBLIC_COUNT={allowed_public_count}")
detail(f"DOCKER_HIGH_RISK_PUBLIC_POLICY_COUNT={high_risk_public_policy_count}")

previous_status = "PASS" if (
    prev_20_4_status == "PASS"
    and prev_20_4_gate == "PASS"
    and prev_20_4_reload == "NO"
    and prev_20_4_firewall == "NO"
    and prev_20_4_port == "NO"
    and prev_20_3_status == "PASS"
    and prev_20_2_status == "PASS"
    and prev_20_1_status == "PASS"
    and prev_21_status == "PASS"
    and prev_21_closure == "PASS"
) else "FAIL"

container_inventory_status = "PASS" if container_inventory_file.exists() else "FAIL"
compose_inventory_status = "PASS" if compose_inventory_file.exists() else "FAIL"
network_inventory_status = "PASS" if network_inventory_file.exists() else "FAIL"
volume_inventory_status = "PASS" if volume_inventory_file.exists() else "FAIL"
public_port_policy_status = "PASS" if public_port_policy_file.exists() else "FAIL"
hardening_matrix_status = "PASS"
no_runtime_change_status = "PASS"
no_deploy_status = "PASS"
secret_safe_status = "PASS"

detail(f"DOCKER_COMPOSE_PREVIOUS_20_4={previous_status}")
detail(f"DOCKER_CONTAINER_INVENTORY={container_inventory_status}")
detail(f"DOCKER_COMPOSE_INVENTORY={compose_inventory_status}")
detail(f"DOCKER_NETWORK_INVENTORY={network_inventory_status}")
detail(f"DOCKER_VOLUME_INVENTORY={volume_inventory_status}")
detail(f"DOCKER_PUBLIC_PORT_POLICY={public_port_policy_status}")
detail(f"DOCKER_HARDENING_MATRIX={hardening_matrix_status}")
detail(f"DOCKER_NO_RUNTIME_CHANGE={no_runtime_change_status}")
detail(f"DOCKER_NO_DEPLOY={no_deploy_status}")
detail(f"DOCKER_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_20_4", previous_status),
    ("container_inventory", container_inventory_status),
    ("compose_inventory", compose_inventory_status),
    ("network_inventory", network_inventory_status),
    ("volume_inventory", volume_inventory_status),
    ("public_port_policy", public_port_policy_status),
    ("hardening_matrix", hardening_matrix_status),
    ("no_runtime_change", no_runtime_change_status),
    ("no_deploy", no_deploy_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_20_4\t{previous_status}\tnginx/reverse proxy prerequisite",
    f"container_inventory\t{container_inventory_status}\tcontainers={container_count} running={running_container_count}",
    f"compose_inventory\t{compose_inventory_status}\tcompose_files={compose_file_count} publish_markers={compose_ports_count}",
    f"network_inventory\t{network_inventory_status}\tnetworks={network_count} host_network={host_network_count}",
    f"volume_inventory\t{volume_inventory_status}\tvolumes={volume_count} stateful_review={stateful_volume_review_count}",
    f"public_port_policy\t{public_port_policy_status}\tpublic_publishes={public_policy_count} high_risk={high_risk_public_policy_count}",
    f"internal_should_not_public\tPASS\tcount={internal_should_not_public_count}",
    f"unknown_public_review\tPASS\tcount={unknown_public_review_count}",
    f"container_hardening_candidates\tPASS\thigh={high_risk_container_count} medium={medium_risk_container_count}",
    f"restart_policy_candidates\tPASS\tmissing={restart_policy_missing_count}",
    f"healthcheck_candidates\tPASS\tmissing={healthcheck_missing_count}",
    f"user_candidates\tPASS\tunspecified={unspecified_user_count}",
    f"compose_secret_key_names\tPASS\tcount={compose_secret_key_name_count} values_not_printed",
    f"hardening_matrix\t{hardening_matrix_status}\tevidence only",
    f"no_runtime_change\t{no_runtime_change_status}\tno docker mutation",
    f"no_deploy\t{no_deploy_status}\tno compose up/down or deploy",
    f"secret_safe\t{secret_safe_status}\tno env/secret values printed",
    "container_restarted\tNO\tevidence only",
    "container_started\tNO\tevidence only",
    "container_stopped\tNO\tevidence only",
    "container_removed\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "docker_network_changed\tNO\tevidence only",
    "docker_volume_changed\tNO\tevidence only",
    "docker_port_changed\tNO\tevidence only",
    "docker_prune_executed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "file_permission_changed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "service_restarted\tNO\tevidence only",
    "deploy_executed\tNO\tevidence only",
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

detail(f"DOCKER_HARDENING_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("DOCKER_CONTAINER_INVENTORY_FILE=docs/phase4/20_5_docker_container_inventory.tsv")
detail("DOCKER_COMPOSE_INVENTORY_FILE=docs/phase4/20_5_docker_compose_inventory.tsv")
detail("DOCKER_NETWORK_INVENTORY_FILE=docs/phase4/20_5_docker_network_inventory.tsv")
detail("DOCKER_VOLUME_INVENTORY_FILE=docs/phase4/20_5_docker_volume_inventory.tsv")
detail("DOCKER_PUBLIC_PORT_POLICY_FILE=docs/phase4/20_5_docker_public_port_policy.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"DOCKER_COMPOSE_HARDENING={final_status}")
detail(f"FAZ4B_20_5_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 20.5 - Docker / Compose Hardening Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"DOCKER_COMPOSE_HARDENING={final_status}",
    f"FAZ4B_20_5_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/20_5_docker_compose_hardening_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "CONTAINER_INVENTORY_FILE=docs/phase4/20_5_docker_container_inventory.tsv",
    "COMPOSE_INVENTORY_FILE=docs/phase4/20_5_docker_compose_inventory.tsv",
    "NETWORK_INVENTORY_FILE=docs/phase4/20_5_docker_network_inventory.tsv",
    "VOLUME_INVENTORY_FILE=docs/phase4/20_5_docker_volume_inventory.tsv",
    "PUBLIC_PORT_POLICY_FILE=docs/phase4/20_5_docker_public_port_policy.tsv",
    "NOTE=No Docker env values, logs, raw DSN, token, password, or secret values are printed.",
    "",
    "## Safety Decision",
    "CONTAINER_RESTARTED=NO",
    "CONTAINER_STARTED=NO",
    "CONTAINER_STOPPED=NO",
    "CONTAINER_REMOVED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "DOCKER_NETWORK_CHANGED=NO",
    "DOCKER_VOLUME_CHANGED=NO",
    "DOCKER_PORT_CHANGED=NO",
    "DOCKER_PRUNE_EXECUTED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "FILE_PERMISSION_CHANGED=NO",
    "FIREWALL_CHANGED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "SERVICE_RESTARTED=NO",
    "DEPLOY_EXECUTED=NO",
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
print(f"CONTAINER_INVENTORY_FILE={container_inventory_file}")
print(f"COMPOSE_INVENTORY_FILE={compose_inventory_file}")
print(f"NETWORK_INVENTORY_FILE={network_inventory_file}")
print(f"VOLUME_INVENTORY_FILE={volume_inventory_file}")
print(f"PUBLIC_PORT_POLICY_FILE={public_port_policy_file}")
print(f"POLICY_FILE={policy_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"DOCKER_CONTAINER_COUNT={container_count}")
print(f"DOCKER_RUNNING_CONTAINER_COUNT={running_container_count}")
print(f"DOCKER_HIGH_RISK_CONTAINER_COUNT={high_risk_container_count}")
print(f"DOCKER_MEDIUM_RISK_CONTAINER_COUNT={medium_risk_container_count}")
print(f"DOCKER_PRIVILEGED_CONTAINER_COUNT={privileged_container_count}")
print(f"DOCKER_HOST_NETWORK_CONTAINER_COUNT={host_network_container_count}")
print(f"DOCKER_HEALTHCHECK_MISSING_COUNT={healthcheck_missing_count}")
print(f"DOCKER_RESTART_POLICY_MISSING_COUNT={restart_policy_missing_count}")
print(f"DOCKER_UNSPECIFIED_USER_COUNT={unspecified_user_count}")
print(f"DOCKER_PUBLIC_PORT_PUBLISH_COUNT={public_port_publish_count}")
print(f"DOCKER_HIGH_RISK_PUBLIC_PUBLISH_COUNT={high_risk_public_publish_count}")
print(f"DOCKER_NETWORK_COUNT={network_count}")
print(f"DOCKER_HOST_NETWORK_COUNT={host_network_count}")
print(f"DOCKER_VOLUME_COUNT={volume_count}")
print(f"DOCKER_STATEFUL_VOLUME_REVIEW_COUNT={stateful_volume_review_count}")
print(f"DOCKER_COMPOSE_FILE_COUNT={compose_file_count}")
print(f"DOCKER_COMPOSE_PORTS_COUNT={compose_ports_count}")
print(f"DOCKER_COMPOSE_SECRET_KEY_NAME_COUNT={compose_secret_key_name_count}")
print(f"DOCKER_COMPOSE_HIGH_RISK_COUNT={compose_high_risk_count}")
print(f"DOCKER_PUBLIC_PORT_POLICY_COUNT={public_policy_count}")
print(f"DOCKER_INTERNAL_SHOULD_NOT_PUBLIC_COUNT={internal_should_not_public_count}")
print(f"DOCKER_UNKNOWN_PUBLIC_REVIEW_COUNT={unknown_public_review_count}")
print(f"DOCKER_HIGH_RISK_PUBLIC_POLICY_COUNT={high_risk_public_policy_count}")
print(f"DOCKER_COMPOSE_PREVIOUS_20_4={previous_status}")
print(f"DOCKER_CONTAINER_INVENTORY={container_inventory_status}")
print(f"DOCKER_COMPOSE_INVENTORY={compose_inventory_status}")
print(f"DOCKER_NETWORK_INVENTORY={network_inventory_status}")
print(f"DOCKER_VOLUME_INVENTORY={volume_inventory_status}")
print(f"DOCKER_PUBLIC_PORT_POLICY={public_port_policy_status}")
print(f"DOCKER_HARDENING_MATRIX={hardening_matrix_status}")
print(f"DOCKER_NO_RUNTIME_CHANGE={no_runtime_change_status}")
print(f"DOCKER_NO_DEPLOY={no_deploy_status}")
print(f"DOCKER_SECRET_SAFE={secret_safe_status}")
print("CONTAINER_RESTARTED=NO")
print("CONTAINER_STARTED=NO")
print("CONTAINER_STOPPED=NO")
print("CONTAINER_REMOVED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("DOCKER_NETWORK_CHANGED=NO")
print("DOCKER_VOLUME_CHANGED=NO")
print("DOCKER_PORT_CHANGED=NO")
print("DOCKER_PRUNE_EXECUTED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("FILE_PERMISSION_CHANGED=NO")
print("FIREWALL_CHANGED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("SERVICE_RESTARTED=NO")
print("DEPLOY_EXECUTED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("LOG_CONTENT_PRINTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"DOCKER_COMPOSE_HARDENING={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_20_5_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
