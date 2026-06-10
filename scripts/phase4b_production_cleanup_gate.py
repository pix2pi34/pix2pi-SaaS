#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "20_1_production_cleanup_standard.md"
policy_file = report_dir / "20_1_production_cleanup_policy.md"
inventory_file = report_dir / "20_1_production_cleanup_inventory.tsv"
matrix_file = report_dir / "20_1_production_cleanup_matrix.tsv"
report_file = report_dir / "20_1_production_cleanup_report.md"

prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"
prev_21_7 = report_dir / "21_7_security_rbac_audit_final_closure_report.md"
prev_19 = report_dir / "19_panel_admin_professionalization_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

MAX_INVENTORY_ROWS = 400

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

def safe_size(path):
    try:
        if path.is_file():
            return path.stat().st_size
        if path.is_dir():
            return -1
    except Exception:
        return 0
    return 0

def migration_chain_status():
    legacy_pattern = re.compile(
        r"^(?P<legacy_seq>\d{3})_(?P<name>[a-z0-9_]+)\.(?P<direction>up|down)\.sql$"
    )
    modern_pattern = re.compile(
        r"^(?P<date>\d{8})_(?P<seq>\d{4,8})_(?P<name>[a-z0-9_]+)\.(?P<direction>up|down)\.sql$"
    )

    all_sql = sorted(migration_dir.glob("*.sql")) if migration_dir.exists() else []
    invalid = []
    bases = {}

    for path in all_sql:
        m = modern_pattern.match(path.name)
        if m:
            base = f"{m.group('date')}_{m.group('seq')}_{m.group('name')}"
            direction = m.group("direction")
        else:
            m = legacy_pattern.match(path.name)
            if m:
                base = f"{m.group('legacy_seq')}_{m.group('name')}"
                direction = m.group("direction")
            else:
                invalid.append(path.name)
                continue

        bases.setdefault(base, {"up": 0, "down": 0})
        bases[base][direction] += 1

    missing = []
    duplicate = []
    for base, pair in bases.items():
        if pair["up"] != 1 or pair["down"] != 1:
            missing.append(base)
        if pair["up"] > 1 or pair["down"] > 1:
            duplicate.append(base)

    return {
        "sql_count": len(all_sql),
        "pair_count": len(bases),
        "invalid_count": len(invalid),
        "missing_pair_count": len(missing),
        "duplicate_pair_count": len(duplicate),
    }

def classify_path(path):
    name = path.name.lower()
    r = rel(path)
    low = r.lower()

    if any(x in name for x in [".env", "secret", "token", "passwd", "password", ".pem", ".key", "id_rsa", ".pgpass"]):
        return ("potential_secret_path", "HIGH", "review_path_only_no_content_printed")

    if path.is_dir() and name in ["backups", "backup", "archive", "archives"]:
        return ("backup_archive_root", "MEDIUM", "candidate_root_review_later")

    if any(part.lower().startswith("backups") for part in path.parts):
        return ("backup_candidate", "MEDIUM", "backup_evidence_candidate_keep_until_cleanup_approval")

    if any(part.lower() in ["archive", "archives", "old", "tmp", "temp", "scratch"] for part in path.parts):
        return ("archive_temp_candidate", "MEDIUM", "manual_review_before_cleanup")

    if name.endswith((".bak", ".old", ".orig", ".tmp", ".save", ".swp")):
        return ("old_file_candidate", "MEDIUM", "manual_review_before_cleanup")

    if low.startswith("docs/phase4/"):
        return ("generated_report", "LOW", "phase4_evidence_keep")

    if low.startswith("scripts/phase4b_") or low.startswith("scripts/test_phase4b_"):
        return ("script_file", "LOW", "phase4_script_keep")

    if low.startswith("db/migrations/") and name.endswith(".sql"):
        return ("migration_file", "LOW", "migration_pair_keep")

    if r in ["docs", "docs/phase4", "scripts", "db", "db/migrations"]:
        return ("production_baseline", "LOW", "baseline_required")

    return ("keep", "LOW", "not_cleanup_candidate")

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("FILE_DELETE_EXECUTED=NO")
detail("FILE_MOVE_EXECUTED=NO")
detail("FILE_PERMISSION_CHANGED=NO")
detail("ENV_CHANGED=NO")
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
detail("VALIDATION_MODE=PRODUCTION_CLEANUP_EVIDENCE_ONLY")

for tool in ["python3", "grep", "wc", "find"]:
    tool_status(tool)

prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(prev_21, "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")
prev_21_7_status = get_value(prev_21_7, "FAZ4B_21_7_FINAL_STATUS")
prev_19_status = get_value(prev_19, "FAZ4B_19_FINAL_STATUS")

detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")
detail(f"PREVIOUS_21_7_FINAL_STATUS={prev_21_7_status}")
detail(f"PREVIOUS_19_FINAL_STATUS={prev_19_status}")

if prev_21_status != "PASS":
    fail("21 final status PASS degil")
if prev_21_closure != "PASS":
    fail("21 security closure PASS degil")
if prev_21_7_status != "PASS":
    fail("21.7 final status PASS degil")
if prev_19_status != "PASS":
    fail("19 final status PASS degil")

for path, label in [
    (standard_file, "standard doc"),
    (policy_file, "policy doc"),
]:
    if not path.exists():
        fail(f"{label} yok")

baseline_paths = [
    root / "docs",
    root / "docs/phase4",
    root / "scripts",
    root / "db",
    root / "db/migrations",
]

baseline_existing = sum(1 for p in baseline_paths if p.exists())
baseline_missing = [rel(p) for p in baseline_paths if not p.exists()]

detail(f"PRODUCTION_BASELINE_EXPECTED_COUNT={len(baseline_paths)}")
detail(f"PRODUCTION_BASELINE_EXISTING_COUNT={baseline_existing}")
detail(f"PRODUCTION_BASELINE_MISSING_COUNT={len(baseline_missing)}")

if baseline_missing:
    fail("baseline path eksik: " + ",".join(baseline_missing))

candidate_rows = []
category_counts = {}
risk_counts = {"LOW": 0, "MEDIUM": 0, "HIGH": 0, "CRITICAL": 0}

# Top-level + important generated areas. Avoid huge deep scan.
scan_roots = [
    root,
    root / "docs/phase4",
    root / "scripts",
    root / "db/migrations",
    root / "backups",
    root / "archive",
    root / "archives",
]

seen = set()

def add_path(path):
    if len(candidate_rows) >= MAX_INVENTORY_ROWS:
        return
    if not path.exists():
        return
    rp = rel(path)
    if rp in seen:
        return
    seen.add(rp)
    category, risk, note = classify_path(path)
    if category == "keep":
        return
    ptype = "dir" if path.is_dir() else "file"
    size = safe_size(path)
    candidate_rows.append([rp, ptype, category, risk, str(size), note])
    category_counts[category] = category_counts.get(category, 0) + 1
    risk_counts[risk] = risk_counts.get(risk, 0) + 1

for p in baseline_paths:
    add_path(p)

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
                if len(candidate_rows) >= MAX_INVENTORY_ROWS:
                    break
                if any(part in [".git", "node_modules", "vendor"] for part in child.parts):
                    continue
                add_path(child)
        except Exception:
            warn(f"scan skipped: {rel(sr)}")

inventory_lines = ["path\ttype\tcategory\trisk\tsize_bytes\tnote"]
for row in candidate_rows:
    inventory_lines.append("\t".join(row))
inventory_file.write_text("\n".join(inventory_lines) + "\n")

cleanup_candidate_count = sum(1 for row in candidate_rows if row[2] in [
    "backup_candidate",
    "backup_archive_root",
    "archive_temp_candidate",
    "old_file_candidate",
])
potential_secret_path_count = sum(1 for row in candidate_rows if row[2] == "potential_secret_path")
generated_report_count = sum(1 for row in candidate_rows if row[2] == "generated_report")
script_file_count = sum(1 for row in candidate_rows if row[2] == "script_file")
migration_file_count = sum(1 for row in candidate_rows if row[2] == "migration_file")

detail(f"PRODUCTION_CLEANUP_INVENTORY_ROW_COUNT={len(candidate_rows)}")
detail(f"PRODUCTION_CLEANUP_CANDIDATE_COUNT={cleanup_candidate_count}")
detail(f"PRODUCTION_CLEANUP_POTENTIAL_SECRET_PATH_COUNT={potential_secret_path_count}")
detail(f"PRODUCTION_CLEANUP_GENERATED_REPORT_COUNT={generated_report_count}")
detail(f"PRODUCTION_CLEANUP_SCRIPT_FILE_COUNT={script_file_count}")
detail(f"PRODUCTION_CLEANUP_MIGRATION_FILE_COUNT={migration_file_count}")
detail(f"PRODUCTION_CLEANUP_HIGH_RISK_PATH_COUNT={risk_counts.get('HIGH', 0)}")
detail(f"PRODUCTION_CLEANUP_MEDIUM_RISK_PATH_COUNT={risk_counts.get('MEDIUM', 0)}")
detail(f"PRODUCTION_CLEANUP_LOW_RISK_PATH_COUNT={risk_counts.get('LOW', 0)}")

chain = migration_chain_status()

detail(f"PRODUCTION_CLEANUP_MIGRATION_SQL_FILE_COUNT={chain['sql_count']}")
detail(f"PRODUCTION_CLEANUP_MIGRATION_PAIR_COUNT={chain['pair_count']}")
detail(f"PRODUCTION_CLEANUP_MIGRATION_INVALID_NAME_COUNT={chain['invalid_count']}")
detail(f"PRODUCTION_CLEANUP_MIGRATION_MISSING_PAIR_COUNT={chain['missing_pair_count']}")
detail(f"PRODUCTION_CLEANUP_MIGRATION_DUPLICATE_PAIR_COUNT={chain['duplicate_pair_count']}")

previous_status = "PASS" if (
    prev_21_status == "PASS"
    and prev_21_closure == "PASS"
    and prev_21_7_status == "PASS"
    and prev_19_status == "PASS"
) else "FAIL"

baseline_status = "PASS" if baseline_existing == len(baseline_paths) else "FAIL"
inventory_status = "PASS" if inventory_file.exists() and len(candidate_rows) >= 5 else "FAIL"
migration_chain_status_value = "PASS" if (
    chain["invalid_count"] == 0
    and chain["missing_pair_count"] == 0
    and chain["duplicate_pair_count"] == 0
) else "FAIL"
no_delete_status = "PASS"
no_move_status = "PASS"
no_deploy_status = "PASS"
secret_safe_status = "PASS"

detail(f"PRODUCTION_CLEANUP_PREVIOUS_21={previous_status}")
detail(f"PRODUCTION_CLEANUP_BASELINE={baseline_status}")
detail(f"PRODUCTION_CLEANUP_INVENTORY={inventory_status}")
detail(f"PRODUCTION_CLEANUP_MIGRATION_CHAIN={migration_chain_status_value}")
detail(f"PRODUCTION_CLEANUP_NO_DELETE={no_delete_status}")
detail(f"PRODUCTION_CLEANUP_NO_MOVE={no_move_status}")
detail(f"PRODUCTION_CLEANUP_NO_DEPLOY={no_deploy_status}")
detail(f"PRODUCTION_CLEANUP_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_21", previous_status),
    ("baseline", baseline_status),
    ("inventory", inventory_status),
    ("migration_chain", migration_chain_status_value),
    ("no_delete", no_delete_status),
    ("no_move", no_move_status),
    ("no_deploy", no_deploy_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_21\t{previous_status}\tsecurity final prerequisite",
    f"baseline\t{baseline_status}\texisting={baseline_existing}/{len(baseline_paths)}",
    f"inventory\t{inventory_status}\trows={len(candidate_rows)}",
    f"migration_chain\t{migration_chain_status_value}\tpairs={chain['pair_count']}",
    f"cleanup_candidates\tPASS\tcandidate_count={cleanup_candidate_count}",
    f"potential_secret_paths\tPASS\tpath_count={potential_secret_path_count} values_not_printed",
    f"no_delete\t{no_delete_status}\tfile delete not executed",
    f"no_move\t{no_move_status}\tfile move not executed",
    f"no_deploy\t{no_deploy_status}\tdeploy/restart not executed",
    f"secret_safe\t{secret_safe_status}\tsecret values not printed",
    "file_delete_executed\tNO\tevidence only",
    "file_move_executed\tNO\tevidence only",
    "file_permission_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "deploy_executed\tNO\tevidence only",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "query_text_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"PRODUCTION_CLEANUP_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"PRODUCTION_CLEANUP_POLICY_FILE=docs/phase4/20_1_production_cleanup_policy.md")
detail(f"PRODUCTION_CLEANUP_INVENTORY_FILE=docs/phase4/20_1_production_cleanup_inventory.tsv")

final_status = "PASS" if not failures else "FAIL"
detail(f"PRODUCTION_CLEANUP_GATE={final_status}")
detail(f"FAZ4B_20_1_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 20.1 - Production File / Folder Cleanup Gate Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"PRODUCTION_CLEANUP_GATE={final_status}",
    f"FAZ4B_20_1_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/20_1_production_cleanup_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/20_1_production_cleanup_inventory.tsv",
    f"INVENTORY_ROW_LIMIT={MAX_INVENTORY_ROWS}",
    "NOTE=Secret values are never printed. Potential secret paths are path-only evidence.",
    "",
    "## Safety Decision",
    "FILE_DELETE_EXECUTED=NO",
    "FILE_MOVE_EXECUTED=NO",
    "FILE_PERMISSION_CHANGED=NO",
    "ENV_CHANGED=NO",
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
print(f"PRODUCTION_BASELINE_EXPECTED_COUNT={len(baseline_paths)}")
print(f"PRODUCTION_BASELINE_EXISTING_COUNT={baseline_existing}")
print(f"PRODUCTION_CLEANUP_INVENTORY_ROW_COUNT={len(candidate_rows)}")
print(f"PRODUCTION_CLEANUP_CANDIDATE_COUNT={cleanup_candidate_count}")
print(f"PRODUCTION_CLEANUP_POTENTIAL_SECRET_PATH_COUNT={potential_secret_path_count}")
print(f"PRODUCTION_CLEANUP_MIGRATION_PAIR_COUNT={chain['pair_count']}")
print(f"PRODUCTION_CLEANUP_MIGRATION_INVALID_NAME_COUNT={chain['invalid_count']}")
print(f"PRODUCTION_CLEANUP_MIGRATION_MISSING_PAIR_COUNT={chain['missing_pair_count']}")
print(f"PRODUCTION_CLEANUP_MIGRATION_DUPLICATE_PAIR_COUNT={chain['duplicate_pair_count']}")
print(f"PRODUCTION_CLEANUP_PREVIOUS_21={previous_status}")
print(f"PRODUCTION_CLEANUP_BASELINE={baseline_status}")
print(f"PRODUCTION_CLEANUP_INVENTORY={inventory_status}")
print(f"PRODUCTION_CLEANUP_MIGRATION_CHAIN={migration_chain_status_value}")
print(f"PRODUCTION_CLEANUP_NO_DELETE={no_delete_status}")
print(f"PRODUCTION_CLEANUP_NO_MOVE={no_move_status}")
print(f"PRODUCTION_CLEANUP_NO_DEPLOY={no_deploy_status}")
print(f"PRODUCTION_CLEANUP_SECRET_SAFE={secret_safe_status}")
print("FILE_DELETE_EXECUTED=NO")
print("FILE_MOVE_EXECUTED=NO")
print("FILE_PERMISSION_CHANGED=NO")
print("ENV_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("DEPLOY_EXECUTED=NO")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"PRODUCTION_CLEANUP_GATE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_20_1_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
