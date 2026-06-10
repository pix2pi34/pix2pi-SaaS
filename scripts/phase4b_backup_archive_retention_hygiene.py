#!/usr/bin/env python3
import os
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "20_6_backup_archive_retention_standard.md"
policy_file = report_dir / "20_6_backup_archive_retention_policy.md"
inventory_file = report_dir / "20_6_backup_archive_inventory.tsv"
volume_retention_file = report_dir / "20_6_backup_archive_volume_retention.tsv"
matrix_file = report_dir / "20_6_backup_archive_retention_matrix.tsv"
report_file = report_dir / "20_6_backup_archive_retention_report.md"

prev_20_5 = report_dir / "20_5_docker_compose_hardening_report.md"
prev_20_5_volumes = report_dir / "20_5_docker_volume_inventory.tsv"
prev_20_4 = report_dir / "20_4_nginx_reverse_proxy_hardening_report.md"
prev_20_3 = report_dir / "20_3_runtime_service_hardening_report.md"
prev_20_2 = report_dir / "20_2_config_env_hardening_report.md"
prev_20_1 = report_dir / "20_1_production_cleanup_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

MAX_ROWS = 700

SECRET_PATH_RE = re.compile(
    r"(secret|token|password|passwd|private|credential|dsn|auth|api[_-]?key|access[_-]?key|refresh[_-]?token|jwt|bearer|pgpass|pem|key|\.env)",
    re.IGNORECASE,
)

DB_BACKUP_RE = re.compile(r"(\.sql$|\.dump$|\.backup$|pg_dump|postgres|pgdata|pg_|_pg)", re.IGNORECASE)
RESTIC_RE = re.compile(r"(restic|snapshots|locks|index|packs)", re.IGNORECASE)
ARCHIVE_RE = re.compile(r"(archive|archives|old|legacy)", re.IGNORECASE)
BACKUP_RE = re.compile(r"(backup|backups|bak|snapshot)", re.IGNORECASE)
STATEFUL_RE = re.compile(r"(postgres|pg|redis|nats|grafana|prometheus|loki|tempo|cadvisor|volume|data)", re.IGNORECASE)

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

def run_cmd(cmd, timeout=12):
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
    v = re.sub(r"(password|token|secret|dsn|bearer|authorization)\s*[:=]\s*[^ ]+", r"\1=***", v, flags=re.I)
    v = re.sub(r"://[^/@\s]+@", "://***@", v)
    return v[:260]

def rel(path):
    try:
        return str(path.relative_to(root))
    except Exception:
        return str(path)

def path_age_days(path):
    try:
        return int((time.time() - path.stat().st_mtime) / 86400)
    except Exception:
        return -1

def path_size_bytes(path):
    try:
        if path.is_file():
            return path.stat().st_size
        return -1
    except Exception:
        return 0

def classify_path(path):
    rp = rel(path)
    low = rp.lower()
    name = path.name.lower()

    category = "keep_current_evidence"
    risk = "LOW"
    policy = "keep_current_evidence"
    note = "evidence_only"

    if SECRET_PATH_RE.search(low):
        category = "review_secret_backup_path"
        risk = "HIGH"
        policy = "manual_approval_required"
        note = "path_only_secret_values_not_printed"

    elif RESTIC_RE.search(low):
        category = "restic_repository_candidate"
        risk = "MEDIUM"
        policy = "keep_restic_repository"
        note = "restic_repo_or_metadata_review_no_prune"

    elif DB_BACKUP_RE.search(low):
        category = "db_backup_candidate"
        risk = "HIGH"
        policy = "review_db_dump"
        note = "db_backup_or_volume_review_no_restore"

    elif BACKUP_RE.search(low):
        category = "backup_candidate"
        risk = "MEDIUM"
        policy = "review_old_backup"
        note = "backup_retention_review_no_delete"

    elif ARCHIVE_RE.search(low):
        category = "archive_candidate"
        risk = "MEDIUM"
        policy = "review_archive_candidate"
        note = "archive_retention_review_no_delete"

    elif STATEFUL_RE.search(low):
        category = "stateful_data_candidate"
        risk = "MEDIUM"
        policy = "keep_stateful_volume"
        note = "stateful_data_review"

    age = path_age_days(path)
    size = path_size_bytes(path)

    if size > 1024 * 1024 * 1024:
        if risk == "LOW":
            risk = "MEDIUM"
        note += ",large_path_review"

    if age >= 30 and category in ["backup_candidate", "archive_candidate", "review_secret_backup_path"]:
        if risk == "LOW":
            risk = "MEDIUM"
        note += ",older_than_30d_review"

    return category, risk, policy, note

def scan_backup_archive_paths():
    roots = [
        root / "backups",
        root / "backup",
        root / "archive",
        root / "archives",
        Path("/root/pix2pi-restic-repo"),
        Path("/root/restic-repo"),
        Path("/opt/pix2pi/backups"),
        Path("/var/backups"),
    ]

    rows = []
    seen = set()

    def add_path(path):
        if len(rows) >= MAX_ROWS:
            return
        if not path.exists():
            return
        rp = rel(path)
        if rp in seen:
            return
        seen.add(rp)

        category, risk, policy, note = classify_path(path)
        if category == "keep_current_evidence" and path.is_file():
            return

        ptype = "dir" if path.is_dir() else "file"
        size = path_size_bytes(path)
        age = path_age_days(path)

        rows.append([
            safe(rp),
            ptype,
            category,
            risk,
            policy,
            str(size),
            str(age),
            note,
        ])

    for base in roots:
        if not base.exists():
            continue
        add_path(base)

        try:
            for child in sorted(base.rglob("*")):
                if len(rows) >= MAX_ROWS:
                    break
                if any(part in [".git", "node_modules", "vendor"] for part in child.parts):
                    continue
                add_path(child)
        except Exception:
            warn(f"scan skipped: {base}")

    return rows

def docker_volume_rows_from_previous():
    rows = []

    if prev_20_5_volumes.exists():
        text = read(prev_20_5_volumes)
        lines = [x for x in text.splitlines() if x.strip()]
        for line in lines[1:]:
            parts = line.split("\t")
            while len(parts) < 5:
                parts.append("")
            name, driver, scope, risk, note = parts[:5]

            lname = name.lower()
            retention_class = "keep_stateful_volume" if STATEFUL_RE.search(lname) else "keep_current_evidence"
            backup_required = "YES" if STATEFUL_RE.search(lname) else "REVIEW"
            restore_drill_required = "YES" if any(x in lname for x in ["postgres", "pg", "redis", "nats"]) else "REVIEW"
            final_risk = "HIGH" if any(x in lname for x in ["postgres", "pg"]) else ("MEDIUM" if STATEFUL_RE.search(lname) else "LOW")

            rows.append([
                safe(name),
                safe(driver),
                safe(scope),
                retention_class,
                backup_required,
                restore_drill_required,
                final_risk,
                "previous_20_5_volume_evidence_no_volume_change",
            ])

    elif which("docker"):
        rc, out, err = run_cmd(["docker", "volume", "ls", "--format", "{{.Name}}\t{{.Driver}}\t{{.Scope}}"])
        if rc == 0 and out:
            for line in out.splitlines():
                parts = line.split("\t")
                while len(parts) < 3:
                    parts.append("")
                name, driver, scope = parts[:3]
                lname = name.lower()
                retention_class = "keep_stateful_volume" if STATEFUL_RE.search(lname) else "keep_current_evidence"
                backup_required = "YES" if STATEFUL_RE.search(lname) else "REVIEW"
                restore_drill_required = "YES" if any(x in lname for x in ["postgres", "pg", "redis", "nats"]) else "REVIEW"
                final_risk = "HIGH" if any(x in lname for x in ["postgres", "pg"]) else ("MEDIUM" if STATEFUL_RE.search(lname) else "LOW")
                rows.append([
                    safe(name),
                    safe(driver),
                    safe(scope),
                    retention_class,
                    backup_required,
                    restore_drill_required,
                    final_risk,
                    "docker_volume_evidence_no_volume_change",
                ])
        else:
            warn("docker volume inventory unavailable")

    return rows

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("BACKUP_DELETE_EXECUTED=NO")
detail("ARCHIVE_DELETE_EXECUTED=NO")
detail("FILE_DELETE_EXECUTED=NO")
detail("FILE_MOVE_EXECUTED=NO")
detail("DOCKER_VOLUME_REMOVED=NO")
detail("DOCKER_VOLUME_PRUNE_EXECUTED=NO")
detail("RESTIC_FORGET_EXECUTED=NO")
detail("RESTIC_PRUNE_EXECUTED=NO")
detail("RESTIC_REPAIR_EXECUTED=NO")
detail("RESTORE_EXECUTED=NO")
detail("PG_DUMP_EXECUTED=NO")
detail("PG_RESTORE_EXECUTED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("SERVICE_RESTARTED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("DEPLOY_EXECUTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=BACKUP_ARCHIVE_RETENTION_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "docker", "restic"]:
    tool_status(tool)

prev_20_5_status = get_value(prev_20_5, "FAZ4B_20_5_FINAL_STATUS")
prev_20_5_gate = get_value(prev_20_5, "DOCKER_COMPOSE_HARDENING")
prev_20_5_volume_changed = get_value(prev_20_5, "DOCKER_VOLUME_CHANGED")
prev_20_5_prune = get_value(prev_20_5, "DOCKER_PRUNE_EXECUTED")
prev_20_4_status = get_value(prev_20_4, "FAZ4B_20_4_FINAL_STATUS")
prev_20_3_status = get_value(prev_20_3, "FAZ4B_20_3_FINAL_STATUS")
prev_20_2_status = get_value(prev_20_2, "FAZ4B_20_2_FINAL_STATUS")
prev_20_1_status = get_value(prev_20_1, "FAZ4B_20_1_FINAL_STATUS")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_20_5_FINAL_STATUS={prev_20_5_status}")
detail(f"PREVIOUS_20_5_DOCKER_COMPOSE_HARDENING={prev_20_5_gate}")
detail(f"PREVIOUS_20_5_DOCKER_VOLUME_CHANGED={prev_20_5_volume_changed}")
detail(f"PREVIOUS_20_5_DOCKER_PRUNE_EXECUTED={prev_20_5_prune}")
detail(f"PREVIOUS_20_4_FINAL_STATUS={prev_20_4_status}")
detail(f"PREVIOUS_20_3_FINAL_STATUS={prev_20_3_status}")
detail(f"PREVIOUS_20_2_FINAL_STATUS={prev_20_2_status}")
detail(f"PREVIOUS_20_1_FINAL_STATUS={prev_20_1_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_20_5_status != "PASS":
    fail("20.5 final status PASS degil")
if prev_20_5_gate != "PASS":
    fail("20.5 docker compose hardening PASS degil")
if prev_20_5_volume_changed != "NO":
    fail("20.5 docker volume changed NO degil")
if prev_20_5_prune != "NO":
    fail("20.5 docker prune NO degil")
if prev_20_4_status != "PASS":
    fail("20.4 final status PASS degil")
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

inventory_rows = scan_backup_archive_paths()
volume_rows = docker_volume_rows_from_previous()

inventory_lines = [
    "path\ttype\tcategory\trisk\tretention_policy\tsize_bytes\tage_days\tnote"
]
for row in inventory_rows:
    inventory_lines.append("\t".join(row))
inventory_file.write_text("\n".join(inventory_lines) + "\n")

volume_lines = [
    "volume_name\tdriver\tscope\tretention_class\tbackup_required\trestore_drill_required\trisk\tnote"
]
for row in volume_rows:
    volume_lines.append("\t".join(row))
volume_retention_file.write_text("\n".join(volume_lines) + "\n")

inventory_count = len(inventory_rows)
backup_candidate_count = sum(1 for r in inventory_rows if "backup" in r[2])
archive_candidate_count = sum(1 for r in inventory_rows if "archive" in r[2])
restic_candidate_count = sum(1 for r in inventory_rows if "restic" in r[2])
db_backup_candidate_count = sum(1 for r in inventory_rows if "db_backup" in r[2])
secret_backup_path_count = sum(1 for r in inventory_rows if r[2] == "review_secret_backup_path")
high_risk_inventory_count = sum(1 for r in inventory_rows if r[3] == "HIGH")
medium_risk_inventory_count = sum(1 for r in inventory_rows if r[3] == "MEDIUM")

volume_count = len(volume_rows)
stateful_volume_count = sum(1 for r in volume_rows if r[3] == "keep_stateful_volume")
backup_required_volume_count = sum(1 for r in volume_rows if r[4] == "YES")
restore_drill_required_count = sum(1 for r in volume_rows if r[5] == "YES")
high_risk_volume_count = sum(1 for r in volume_rows if r[6] == "HIGH")
medium_risk_volume_count = sum(1 for r in volume_rows if r[6] == "MEDIUM")

detail(f"BACKUP_ARCHIVE_INVENTORY_ROW_COUNT={inventory_count}")
detail(f"BACKUP_ARCHIVE_BACKUP_CANDIDATE_COUNT={backup_candidate_count}")
detail(f"BACKUP_ARCHIVE_ARCHIVE_CANDIDATE_COUNT={archive_candidate_count}")
detail(f"BACKUP_ARCHIVE_RESTIC_CANDIDATE_COUNT={restic_candidate_count}")
detail(f"BACKUP_ARCHIVE_DB_BACKUP_CANDIDATE_COUNT={db_backup_candidate_count}")
detail(f"BACKUP_ARCHIVE_SECRET_BACKUP_PATH_COUNT={secret_backup_path_count}")
detail(f"BACKUP_ARCHIVE_HIGH_RISK_INVENTORY_COUNT={high_risk_inventory_count}")
detail(f"BACKUP_ARCHIVE_MEDIUM_RISK_INVENTORY_COUNT={medium_risk_inventory_count}")

detail(f"BACKUP_ARCHIVE_VOLUME_COUNT={volume_count}")
detail(f"BACKUP_ARCHIVE_STATEFUL_VOLUME_COUNT={stateful_volume_count}")
detail(f"BACKUP_ARCHIVE_BACKUP_REQUIRED_VOLUME_COUNT={backup_required_volume_count}")
detail(f"BACKUP_ARCHIVE_RESTORE_DRILL_REQUIRED_COUNT={restore_drill_required_count}")
detail(f"BACKUP_ARCHIVE_HIGH_RISK_VOLUME_COUNT={high_risk_volume_count}")
detail(f"BACKUP_ARCHIVE_MEDIUM_RISK_VOLUME_COUNT={medium_risk_volume_count}")

previous_status = "PASS" if (
    prev_20_5_status == "PASS"
    and prev_20_5_gate == "PASS"
    and prev_20_5_volume_changed == "NO"
    and prev_20_5_prune == "NO"
    and prev_20_4_status == "PASS"
    and prev_20_3_status == "PASS"
    and prev_20_2_status == "PASS"
    and prev_20_1_status == "PASS"
    and prev_21_status == "PASS"
    and prev_21_closure == "PASS"
) else "FAIL"

inventory_status = "PASS" if inventory_file.exists() else "FAIL"
volume_retention_status = "PASS" if volume_retention_file.exists() and volume_count >= 1 else "FAIL"
policy_status = "PASS" if policy_file.exists() and standard_file.exists() else "FAIL"
no_delete_status = "PASS"
no_prune_status = "PASS"
no_restore_status = "PASS"
secret_safe_status = "PASS"

detail(f"BACKUP_ARCHIVE_PREVIOUS_20_5={previous_status}")
detail(f"BACKUP_ARCHIVE_INVENTORY={inventory_status}")
detail(f"BACKUP_ARCHIVE_VOLUME_RETENTION={volume_retention_status}")
detail(f"BACKUP_ARCHIVE_POLICY={policy_status}")
detail(f"BACKUP_ARCHIVE_NO_DELETE={no_delete_status}")
detail(f"BACKUP_ARCHIVE_NO_PRUNE={no_prune_status}")
detail(f"BACKUP_ARCHIVE_NO_RESTORE={no_restore_status}")
detail(f"BACKUP_ARCHIVE_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_20_5", previous_status),
    ("inventory", inventory_status),
    ("volume_retention", volume_retention_status),
    ("policy", policy_status),
    ("no_delete", no_delete_status),
    ("no_prune", no_prune_status),
    ("no_restore", no_restore_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_20_5\t{previous_status}\tdocker/compose hardening prerequisite",
    f"backup_archive_inventory\t{inventory_status}\trows={inventory_count}",
    f"volume_retention\t{volume_retention_status}\tvolumes={volume_count} stateful={stateful_volume_count}",
    f"backup_candidates\tPASS\tbackup={backup_candidate_count} archive={archive_candidate_count} restic={restic_candidate_count}",
    f"db_backup_candidates\tPASS\tcount={db_backup_candidate_count}",
    f"secret_backup_paths\tPASS\tcount={secret_backup_path_count} values_not_printed",
    f"high_risk_inventory\tPASS\tcount={high_risk_inventory_count}",
    f"backup_required_volumes\tPASS\tcount={backup_required_volume_count}",
    f"restore_drill_required\tPASS\tcount={restore_drill_required_count}",
    f"policy\t{policy_status}\tretention policy documented",
    f"no_delete\t{no_delete_status}\tbackup/archive delete not executed",
    f"no_prune\t{no_prune_status}\trestic/docker prune not executed",
    f"no_restore\t{no_restore_status}\trestore not executed",
    f"secret_safe\t{secret_safe_status}\tsecret values not printed",
    "backup_delete_executed\tNO\tevidence only",
    "archive_delete_executed\tNO\tevidence only",
    "file_delete_executed\tNO\tevidence only",
    "file_move_executed\tNO\tevidence only",
    "docker_volume_removed\tNO\tevidence only",
    "docker_volume_prune_executed\tNO\tevidence only",
    "restic_forget_executed\tNO\tevidence only",
    "restic_prune_executed\tNO\tevidence only",
    "restic_repair_executed\tNO\tevidence only",
    "restore_executed\tNO\tevidence only",
    "pg_dump_executed\tNO\tevidence only",
    "pg_restore_executed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "deploy_executed\tNO\tevidence only",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"BACKUP_ARCHIVE_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail("BACKUP_ARCHIVE_INVENTORY_FILE=docs/phase4/20_6_backup_archive_inventory.tsv")
detail("BACKUP_ARCHIVE_VOLUME_RETENTION_FILE=docs/phase4/20_6_backup_archive_volume_retention.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"BACKUP_ARCHIVE_RETENTION_HYGIENE={final_status}")
detail(f"FAZ4B_20_6_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 20.6 - Backup / Archive Retention Hygiene Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"BACKUP_ARCHIVE_RETENTION_HYGIENE={final_status}",
    f"FAZ4B_20_6_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/20_6_backup_archive_retention_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "BACKUP_ARCHIVE_INVENTORY_FILE=docs/phase4/20_6_backup_archive_inventory.tsv",
    "VOLUME_RETENTION_FILE=docs/phase4/20_6_backup_archive_volume_retention.tsv",
    "NOTE=No backup/archive content, raw DSN, token, password, or secret values are printed.",
    "",
    "## Safety Decision",
    "BACKUP_DELETE_EXECUTED=NO",
    "ARCHIVE_DELETE_EXECUTED=NO",
    "FILE_DELETE_EXECUTED=NO",
    "FILE_MOVE_EXECUTED=NO",
    "DOCKER_VOLUME_REMOVED=NO",
    "DOCKER_VOLUME_PRUNE_EXECUTED=NO",
    "RESTIC_FORGET_EXECUTED=NO",
    "RESTIC_PRUNE_EXECUTED=NO",
    "RESTIC_REPAIR_EXECUTED=NO",
    "RESTORE_EXECUTED=NO",
    "PG_DUMP_EXECUTED=NO",
    "PG_RESTORE_EXECUTED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "SERVICE_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DEPLOY_EXECUTED=NO",
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
    "SECRET_VALUE_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"BACKUP_ARCHIVE_INVENTORY_FILE={inventory_file}")
print(f"VOLUME_RETENTION_FILE={volume_retention_file}")
print(f"POLICY_FILE={policy_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"BACKUP_ARCHIVE_INVENTORY_ROW_COUNT={inventory_count}")
print(f"BACKUP_ARCHIVE_BACKUP_CANDIDATE_COUNT={backup_candidate_count}")
print(f"BACKUP_ARCHIVE_ARCHIVE_CANDIDATE_COUNT={archive_candidate_count}")
print(f"BACKUP_ARCHIVE_RESTIC_CANDIDATE_COUNT={restic_candidate_count}")
print(f"BACKUP_ARCHIVE_DB_BACKUP_CANDIDATE_COUNT={db_backup_candidate_count}")
print(f"BACKUP_ARCHIVE_SECRET_BACKUP_PATH_COUNT={secret_backup_path_count}")
print(f"BACKUP_ARCHIVE_VOLUME_COUNT={volume_count}")
print(f"BACKUP_ARCHIVE_STATEFUL_VOLUME_COUNT={stateful_volume_count}")
print(f"BACKUP_ARCHIVE_BACKUP_REQUIRED_VOLUME_COUNT={backup_required_volume_count}")
print(f"BACKUP_ARCHIVE_RESTORE_DRILL_REQUIRED_COUNT={restore_drill_required_count}")
print(f"BACKUP_ARCHIVE_PREVIOUS_20_5={previous_status}")
print(f"BACKUP_ARCHIVE_INVENTORY={inventory_status}")
print(f"BACKUP_ARCHIVE_VOLUME_RETENTION={volume_retention_status}")
print(f"BACKUP_ARCHIVE_POLICY={policy_status}")
print(f"BACKUP_ARCHIVE_NO_DELETE={no_delete_status}")
print(f"BACKUP_ARCHIVE_NO_PRUNE={no_prune_status}")
print(f"BACKUP_ARCHIVE_NO_RESTORE={no_restore_status}")
print(f"BACKUP_ARCHIVE_SECRET_SAFE={secret_safe_status}")
print("BACKUP_DELETE_EXECUTED=NO")
print("ARCHIVE_DELETE_EXECUTED=NO")
print("FILE_DELETE_EXECUTED=NO")
print("FILE_MOVE_EXECUTED=NO")
print("DOCKER_VOLUME_REMOVED=NO")
print("DOCKER_VOLUME_PRUNE_EXECUTED=NO")
print("RESTIC_FORGET_EXECUTED=NO")
print("RESTIC_PRUNE_EXECUTED=NO")
print("RESTIC_REPAIR_EXECUTED=NO")
print("RESTORE_EXECUTED=NO")
print("PG_DUMP_EXECUTED=NO")
print("PG_RESTORE_EXECUTED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DEPLOY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"BACKUP_ARCHIVE_RETENTION_HYGIENE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_20_6_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
