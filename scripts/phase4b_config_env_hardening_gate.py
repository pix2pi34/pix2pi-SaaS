#!/usr/bin/env python3
import os
import re
import stat
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "20_2_config_env_hardening_standard.md"
policy_file = report_dir / "20_2_config_env_hardening_policy.md"
inventory_file = report_dir / "20_2_config_env_hardening_inventory.tsv"
matrix_file = report_dir / "20_2_config_env_hardening_matrix.tsv"
report_file = report_dir / "20_2_config_env_hardening_report.md"

prev_20_1 = report_dir / "20_1_production_cleanup_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

MAX_ROWS = 500

SECRET_NAME_RE = re.compile(
    r"(secret|token|password|passwd|private|credential|dsn|auth|api[_-]?key|access[_-]?key|refresh[_-]?token|jwt|bearer|pgpass|pem|key)",
    re.IGNORECASE,
)

ENV_NAME_RE = re.compile(r"(^\.env$|\.env$|\.env\.|env$|env\.|\.envrc$)", re.IGNORECASE)
CONFIG_NAME_RE = re.compile(r"(config|conf|settings|application|common\.env|ports\.env|docker-compose|compose\.ya?ml|\.ya?ml$|\.json$|\.toml$)", re.IGNORECASE)
KEY_MATERIAL_RE = re.compile(r"(\.pem$|\.key$|id_rsa|id_ed25519|\.p12$|\.pfx$|\.crt$)", re.IGNORECASE)

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

def rel(path):
    try:
        return str(path.relative_to(root))
    except Exception:
        return str(path)

def file_mode(path):
    try:
        return stat.S_IMODE(path.stat().st_mode)
    except Exception:
        return 0

def mode_octal(path):
    return format(file_mode(path), "04o")

def is_group_readable(path):
    return bool(file_mode(path) & stat.S_IRGRP)

def is_world_readable(path):
    return bool(file_mode(path) & stat.S_IROTH)

def is_executable(path):
    return bool(file_mode(path) & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH))

def line_key_scan(path):
    # Değer basmaz; sadece key-name sayımı yapar.
    # Büyük binary/key dosyalar okunmaz.
    if not path.is_file():
        return (0, 0, 0)
    try:
        if path.stat().st_size > 1024 * 1024:
            return (0, 0, 0)
    except Exception:
        return (0, 0, 0)

    total_keys = 0
    secret_key_names = 0
    dsn_key_names = 0

    try:
        for raw in path.read_text(errors="ignore").splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue

            key = line.split("=", 1)[0].strip().strip("export ").strip()
            if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
                continue

            total_keys += 1

            if SECRET_NAME_RE.search(key):
                secret_key_names += 1

            if "DSN" in key.upper() or "DATABASE_URL" in key.upper():
                dsn_key_names += 1
    except Exception:
        return (0, 0, 0)

    return (total_keys, secret_key_names, dsn_key_names)

def classify_path(path):
    r = rel(path)
    low = r.lower()
    name = path.name.lower()

    if KEY_MATERIAL_RE.search(name):
        return ("key_material_path", "HIGH", "key_material_path_only_no_content")

    if ENV_NAME_RE.search(name) or name in [".env", ".env.local", ".env.production"]:
        return ("env_file", "HIGH", "env_path_only_value_not_printed")

    if SECRET_NAME_RE.search(low):
        return ("potential_secret_path", "HIGH", "secret_like_path_only_value_not_printed")

    if "backup" in low or "backups" in low or "archive" in low:
        if ENV_NAME_RE.search(name) or SECRET_NAME_RE.search(low):
            return ("backup_env_candidate", "HIGH", "backup_or_archive_secret_candidate_review")

    if CONFIG_NAME_RE.search(low):
        return ("config_file", "MEDIUM", "config_path_review")

    return ("keep", "LOW", "not_config_env_candidate")

def permission_category(path, base_category):
    if not path.is_file():
        return ("dir_or_nonfile", "LOW")

    if is_world_readable(path):
        return ("world_readable_candidate", "HIGH")

    if is_group_readable(path) and base_category in ["env_file", "potential_secret_path", "key_material_path", "backup_env_candidate"]:
        return ("group_readable_candidate", "HIGH")

    if is_executable(path) and base_category in ["env_file", "config_file", "potential_secret_path", "key_material_path", "backup_env_candidate"]:
        return ("executable_config_candidate", "MEDIUM")

    return ("permission_ok_or_review", "LOW")

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("FILE_PERMISSION_CHANGED=NO")
detail("FILE_DELETE_EXECUTED=NO")
detail("FILE_MOVE_EXECUTED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("DEPLOY_EXECUTED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
detail("SERVICE_RESTARTED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=CONFIG_ENV_HARDENING_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "find", "stat"]:
    tool_status(tool)

prev_20_1_status = get_value(prev_20_1, "FAZ4B_20_1_FINAL_STATUS")
prev_20_1_gate = get_value(prev_20_1, "PRODUCTION_CLEANUP_GATE")
prev_20_1_delete = get_value(prev_20_1, "FILE_DELETE_EXECUTED")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")

detail(f"PREVIOUS_20_1_FINAL_STATUS={prev_20_1_status}")
detail(f"PREVIOUS_20_1_PRODUCTION_CLEANUP_GATE={prev_20_1_gate}")
detail(f"PREVIOUS_20_1_FILE_DELETE_EXECUTED={prev_20_1_delete}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_20_1_status != "PASS":
    fail("20.1 final status PASS degil")
if prev_20_1_gate != "PASS":
    fail("20.1 production cleanup gate PASS degil")
if prev_20_1_delete != "NO":
    fail("20.1 file delete NO degil")
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

baseline_paths = [
    root / ".env",
    root / "docs",
    root / "docs/phase4",
    root / "scripts",
    root / "db",
    root / "db/migrations",
]

baseline_existing = sum(1 for p in baseline_paths if p.exists())
detail(f"CONFIG_ENV_BASELINE_EXPECTED_COUNT={len(baseline_paths)}")
detail(f"CONFIG_ENV_BASELINE_EXISTING_COUNT={baseline_existing}")

scan_roots = [
    root,
    root / "config",
    root / "configs",
    root / "internal",
    root / "cmd",
    root / "deploy",
    root / "deployment",
    root / "docker",
    root / "scripts",
    root / "docs/phase4",
    root / "backup",
    root / "backups",
    root / "archive",
    root / "archives",
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

    base_category, risk, note = classify_path(path)

    if base_category == "keep":
        return

    perm_category, perm_risk = permission_category(path, base_category)

    final_risk = "HIGH" if "HIGH" in [risk, perm_risk] else ("MEDIUM" if "MEDIUM" in [risk, perm_risk] else "LOW")

    total_keys, secret_key_names, dsn_key_names = line_key_scan(path)

    ptype = "dir" if path.is_dir() else "file"
    mode = mode_octal(path)
    group_readable = "YES" if is_group_readable(path) and path.is_file() else "NO"
    world_readable = "YES" if is_world_readable(path) and path.is_file() else "NO"
    executable = "YES" if is_executable(path) and path.is_file() else "NO"

    rows.append([
        rp,
        ptype,
        base_category,
        perm_category,
        final_risk,
        mode,
        group_readable,
        world_readable,
        executable,
        str(total_keys),
        str(secret_key_names),
        str(dsn_key_names),
        note,
    ])

for bp in baseline_paths:
    add_path(bp)

for sr in scan_roots:
    if not sr.exists():
        continue

    if sr == root:
        for child in sorted(sr.iterdir()):
            if child.name in [".git", "node_modules", "vendor"]:
                continue
            add_path(child)
    else:
        add_path(sr)
        try:
            for child in sorted(sr.rglob("*")):
                if len(rows) >= MAX_ROWS:
                    break
                if any(part in [".git", "node_modules", "vendor"] for part in child.parts):
                    continue
                add_path(child)
        except Exception:
            warn(f"scan skipped: {rel(sr)}")

inventory_lines = [
    "path\ttype\tcategory\tpermission_category\trisk\tmode\tgroup_readable\tworld_readable\texecutable\tkey_name_count\tsecret_key_name_count\tdsn_key_name_count\tnote"
]
for row in rows:
    inventory_lines.append("\t".join(row))
inventory_file.write_text("\n".join(inventory_lines) + "\n")

env_file_count = sum(1 for r in rows if r[2] == "env_file")
config_file_count = sum(1 for r in rows if r[2] == "config_file")
potential_secret_path_count = sum(1 for r in rows if r[2] == "potential_secret_path")
key_material_path_count = sum(1 for r in rows if r[2] == "key_material_path")
backup_env_candidate_count = sum(1 for r in rows if r[2] == "backup_env_candidate")
world_readable_candidate_count = sum(1 for r in rows if r[3] == "world_readable_candidate")
group_readable_candidate_count = sum(1 for r in rows if r[3] == "group_readable_candidate")
executable_config_candidate_count = sum(1 for r in rows if r[3] == "executable_config_candidate")
high_risk_count = sum(1 for r in rows if r[4] == "HIGH")
medium_risk_count = sum(1 for r in rows if r[4] == "MEDIUM")
low_risk_count = sum(1 for r in rows if r[4] == "LOW")
secret_key_name_count = sum(int(r[10]) for r in rows)
dsn_key_name_count = sum(int(r[11]) for r in rows)

detail(f"CONFIG_ENV_INVENTORY_ROW_COUNT={len(rows)}")
detail(f"CONFIG_ENV_ENV_FILE_COUNT={env_file_count}")
detail(f"CONFIG_ENV_CONFIG_FILE_COUNT={config_file_count}")
detail(f"CONFIG_ENV_POTENTIAL_SECRET_PATH_COUNT={potential_secret_path_count}")
detail(f"CONFIG_ENV_KEY_MATERIAL_PATH_COUNT={key_material_path_count}")
detail(f"CONFIG_ENV_BACKUP_ENV_CANDIDATE_COUNT={backup_env_candidate_count}")
detail(f"CONFIG_ENV_WORLD_READABLE_CANDIDATE_COUNT={world_readable_candidate_count}")
detail(f"CONFIG_ENV_GROUP_READABLE_CANDIDATE_COUNT={group_readable_candidate_count}")
detail(f"CONFIG_ENV_EXECUTABLE_CONFIG_CANDIDATE_COUNT={executable_config_candidate_count}")
detail(f"CONFIG_ENV_HIGH_RISK_COUNT={high_risk_count}")
detail(f"CONFIG_ENV_MEDIUM_RISK_COUNT={medium_risk_count}")
detail(f"CONFIG_ENV_LOW_RISK_COUNT={low_risk_count}")
detail(f"CONFIG_ENV_SECRET_KEY_NAME_COUNT={secret_key_name_count}")
detail(f"CONFIG_ENV_DSN_KEY_NAME_COUNT={dsn_key_name_count}")

previous_status = "PASS" if (
    prev_20_1_status == "PASS"
    and prev_20_1_gate == "PASS"
    and prev_20_1_delete == "NO"
    and prev_21_status == "PASS"
    and prev_21_closure == "PASS"
) else "FAIL"

baseline_status = "PASS" if baseline_existing >= 5 else "FAIL"
inventory_status = "PASS" if inventory_file.exists() and len(rows) >= 1 else "FAIL"
permission_evidence_status = "PASS" if len(rows) >= 1 else "FAIL"
value_not_printed_status = "PASS"
no_change_status = "PASS"
no_deploy_status = "PASS"
secret_safe_status = "PASS"

detail(f"CONFIG_ENV_PREVIOUS_20_1={previous_status}")
detail(f"CONFIG_ENV_BASELINE={baseline_status}")
detail(f"CONFIG_ENV_INVENTORY={inventory_status}")
detail(f"CONFIG_ENV_PERMISSION_EVIDENCE={permission_evidence_status}")
detail(f"CONFIG_ENV_VALUE_NOT_PRINTED={value_not_printed_status}")
detail(f"CONFIG_ENV_NO_CHANGE={no_change_status}")
detail(f"CONFIG_ENV_NO_DEPLOY={no_deploy_status}")
detail(f"CONFIG_ENV_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_20_1", previous_status),
    ("baseline", baseline_status),
    ("inventory", inventory_status),
    ("permission_evidence", permission_evidence_status),
    ("value_not_printed", value_not_printed_status),
    ("no_change", no_change_status),
    ("no_deploy", no_deploy_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_20_1\t{previous_status}\tproduction cleanup prerequisite",
    f"baseline\t{baseline_status}\texisting={baseline_existing}/{len(baseline_paths)}",
    f"inventory\t{inventory_status}\trows={len(rows)}",
    f"permission_evidence\t{permission_evidence_status}\tworld_readable={world_readable_candidate_count} group_readable={group_readable_candidate_count}",
    f"env_files\tPASS\tenv_file_count={env_file_count}",
    f"config_files\tPASS\tconfig_file_count={config_file_count}",
    f"potential_secret_paths\tPASS\tpath_count={potential_secret_path_count} values_not_printed",
    f"secret_key_names\tPASS\tsecret_key_name_count={secret_key_name_count} values_not_printed",
    f"dsn_key_names\tPASS\tdsn_key_name_count={dsn_key_name_count} values_not_printed",
    f"value_not_printed\t{value_not_printed_status}\tmetadata_only",
    f"no_change\t{no_change_status}\tno chmod/chown/env edit",
    f"no_deploy\t{no_deploy_status}\tdeploy/restart not executed",
    f"secret_safe\t{secret_safe_status}\tsecret values not printed",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "file_permission_changed\tNO\tevidence only",
    "file_delete_executed\tNO\tevidence only",
    "file_move_executed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "deploy_executed\tNO\tevidence only",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"CONFIG_ENV_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"CONFIG_ENV_POLICY_FILE=docs/phase4/20_2_config_env_hardening_policy.md")
detail(f"CONFIG_ENV_INVENTORY_FILE=docs/phase4/20_2_config_env_hardening_inventory.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"CONFIG_ENV_HARDENING_GATE={final_status}")
detail(f"FAZ4B_20_2_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 20.2 - Config / Env Hardening Gate Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"CONFIG_ENV_HARDENING_GATE={final_status}",
    f"FAZ4B_20_2_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/20_2_config_env_hardening_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/20_2_config_env_hardening_inventory.tsv",
    f"INVENTORY_ROW_LIMIT={MAX_ROWS}",
    "NOTE=Secret values and raw DSN values are never printed. Key names are counted only.",
    "",
    "## Safety Decision",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "FILE_PERMISSION_CHANGED=NO",
    "FILE_DELETE_EXECUTED=NO",
    "FILE_MOVE_EXECUTED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "DEPLOY_EXECUTED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "SERVICE_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
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
print(f"INVENTORY_FILE={inventory_file}")
print(f"POLICY_FILE={policy_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"CONFIG_ENV_BASELINE_EXPECTED_COUNT={len(baseline_paths)}")
print(f"CONFIG_ENV_BASELINE_EXISTING_COUNT={baseline_existing}")
print(f"CONFIG_ENV_INVENTORY_ROW_COUNT={len(rows)}")
print(f"CONFIG_ENV_ENV_FILE_COUNT={env_file_count}")
print(f"CONFIG_ENV_CONFIG_FILE_COUNT={config_file_count}")
print(f"CONFIG_ENV_POTENTIAL_SECRET_PATH_COUNT={potential_secret_path_count}")
print(f"CONFIG_ENV_KEY_MATERIAL_PATH_COUNT={key_material_path_count}")
print(f"CONFIG_ENV_WORLD_READABLE_CANDIDATE_COUNT={world_readable_candidate_count}")
print(f"CONFIG_ENV_GROUP_READABLE_CANDIDATE_COUNT={group_readable_candidate_count}")
print(f"CONFIG_ENV_SECRET_KEY_NAME_COUNT={secret_key_name_count}")
print(f"CONFIG_ENV_DSN_KEY_NAME_COUNT={dsn_key_name_count}")
print(f"CONFIG_ENV_PREVIOUS_20_1={previous_status}")
print(f"CONFIG_ENV_BASELINE={baseline_status}")
print(f"CONFIG_ENV_INVENTORY={inventory_status}")
print(f"CONFIG_ENV_PERMISSION_EVIDENCE={permission_evidence_status}")
print(f"CONFIG_ENV_VALUE_NOT_PRINTED={value_not_printed_status}")
print(f"CONFIG_ENV_NO_CHANGE={no_change_status}")
print(f"CONFIG_ENV_NO_DEPLOY={no_deploy_status}")
print(f"CONFIG_ENV_SECRET_SAFE={secret_safe_status}")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("FILE_PERMISSION_CHANGED=NO")
print("FILE_DELETE_EXECUTED=NO")
print("FILE_MOVE_EXECUTED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("DEPLOY_EXECUTED=NO")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"CONFIG_ENV_HARDENING_GATE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_20_2_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
