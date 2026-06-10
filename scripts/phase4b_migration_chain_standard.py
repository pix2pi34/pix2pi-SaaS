#!/usr/bin/env python3
import hashlib
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()

report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "14_1_pilot_migration_chain_standard.md"
report_file = report_dir / "14_1_pilot_migration_chain_report.md"
inventory_file = report_dir / "14_1_pilot_migration_chain_inventory.tsv"
matrix_file = report_dir / "14_1_pilot_migration_chain_matrix.tsv"

phase4_master = report_dir / "phase4_final_master_closure_report.md"
db_scorecard = report_dir / "14_5_2_db_production_readiness_scorecard_report.md"

failures = []
warnings = []
details = []
tools = []

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

def get_value(path, key):
    if not path.exists():
        return ""
    value = ""
    pattern = re.compile(rf"^{re.escape(key)}=(.*)$")
    for line in path.read_text(errors="ignore").splitlines():
        m = pattern.match(line.strip())
        if m:
            value = m.group(1).strip().strip('"')
    return value

def sha256(path):
    if not path.exists() or not path.is_file():
        return "NA"
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def count_regex(path, pattern):
    if not path.exists() or not path.is_file():
        return 0
    text = path.read_text(errors="ignore")
    return len(re.findall(pattern, text, re.IGNORECASE | re.MULTILINE))

def read_env_candidates():
    candidates = []
    for key in ("DB_WRITE_DSN", "DB_DSN", "DATABASE_URL", "POSTGRES_DSN"):
        value = os.environ.get(key, "").strip()
        if value:
            candidates.append((key, value))

    env_files = [
        root / ".env",
        root / "config/.env",
        root / "deploy/.env",
        Path("/opt/pix2pi/orchestrator/env/common.env"),
        Path("/etc/pix2pi/ports.env"),
    ]

    for env_file in env_files:
        if not env_file.exists():
            continue
        for line in env_file.read_text(errors="ignore").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key in ("DB_WRITE_DSN", "DB_DSN", "DATABASE_URL", "POSTGRES_DSN") and value:
                candidates.append((f"{env_file}:{key}", value))

    return candidates

def mask_dsn(dsn):
    if not dsn:
        return ""
    dsn = re.sub(r"://([^:/@]+):([^@]+)@", r"://\1:***@", dsn)
    dsn = re.sub(r"(password=)[^ ]+", r"\1***", dsn, flags=re.IGNORECASE)
    return dsn

def psql_scalar(dsn, sql):
    proc = subprocess.run(
        ["psql", dsn, "-Atqc", sql],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=8,
    )
    if proc.returncode != 0:
        return None, proc.stderr.strip()
    return proc.stdout.strip(), ""

def db_schema_migrations_check():
    if not which("psql"):
        return {
            "status": "SKIPPED",
            "reason": "psql_not_found",
            "masked_dsn": "",
            "exists": "UNKNOWN",
            "dirty": "UNKNOWN",
            "version": "UNKNOWN",
        }

    candidates = read_env_candidates()
    if not candidates:
        return {
            "status": "SKIPPED",
            "reason": "dsn_not_configured",
            "masked_dsn": "",
            "exists": "UNKNOWN",
            "dirty": "UNKNOWN",
            "version": "UNKNOWN",
        }

    source, dsn = candidates[0]
    masked = mask_dsn(dsn)

    exists, err = psql_scalar(
        dsn,
        "select exists(select 1 from information_schema.tables where table_schema='public' and table_name='schema_migrations');",
    )
    if err:
        return {
            "status": "WARN",
            "reason": "db_connection_or_query_failed",
            "masked_dsn": masked,
            "exists": "UNKNOWN",
            "dirty": "UNKNOWN",
            "version": "UNKNOWN",
        }

    if exists != "t":
        return {
            "status": "WARN",
            "reason": "schema_migrations_missing",
            "masked_dsn": masked,
            "exists": exists,
            "dirty": "UNKNOWN",
            "version": "UNKNOWN",
        }

    dirty, _ = psql_scalar(dsn, "select coalesce(bool_or(dirty), false)::text from public.schema_migrations;")
    version, _ = psql_scalar(dsn, "select coalesce(max(version),0)::text from public.schema_migrations;")

    status = "PASS" if dirty == "false" else "FAIL"
    return {
        "status": status,
        "reason": "checked",
        "masked_dsn": masked,
        "exists": exists,
        "dirty": dirty,
        "version": version,
    }

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=READ_ONLY_FILE_AND_OPTIONAL_DB_CHECK")

tool_status("python3")
tool_status("grep")
tool_status("wc")
tool_status("sha256sum")
tool_status("psql")

phase4_final = get_value(phase4_master, "FAZ4_FINAL_STATUS")
phase5_gate = get_value(phase4_master, "FAZ5_TRANSITION_GATE")
db_readiness = get_value(db_scorecard, "DB_PRODUCTION_READINESS_STATUS")
db_score = get_value(db_scorecard, "DB_PRODUCTION_READINESS_SCORE")
db_grade = get_value(db_scorecard, "DB_PRODUCTION_READINESS_GRADE")

detail(f"PREVIOUS_PHASE4_FINAL_STATUS={phase4_final}")
detail(f"PREVIOUS_PHASE5_TRANSITION_GATE={phase5_gate}")
detail(f"PREVIOUS_DB_PRODUCTION_READINESS_STATUS={db_readiness}")
detail(f"PREVIOUS_DB_PRODUCTION_READINESS_SCORE={db_score}")
detail(f"PREVIOUS_DB_PRODUCTION_READINESS_GRADE={db_grade}")

if not standard_file.exists():
    fail("standard doc yok")

if not migration_dir.exists():
    fail("db/migrations dizini yok")

legacy_pattern = re.compile(
    r"^(?P<legacy_seq>\d{3})_(?P<name>[a-z0-9_]+)\.(?P<direction>up|down)\.sql$"
)

modern_pattern = re.compile(
    r"^(?P<date>\d{8})_(?P<seq>\d{4,8})_(?P<name>[a-z0-9_]+)\.(?P<direction>up|down)\.sql$"
)

all_sql_files = sorted(migration_dir.glob("*.sql")) if migration_dir.exists() else []
valid = []
invalid = []

for path in all_sql_files:
    naming_mode = ""
    version = ""
    name = ""
    direction = ""

    m = modern_pattern.match(path.name)
    if m:
        naming_mode = "modern_timestamp"
        version = f"{m.group('date')}_{m.group('seq')}"
        name = m.group("name")
        direction = m.group("direction")
    else:
        m = legacy_pattern.match(path.name)
        if m:
            naming_mode = "legacy_seq"
            version = m.group("legacy_seq")
            name = m.group("name")
            direction = m.group("direction")

    if not version:
        invalid.append(path)
        continue

    valid.append({
        "path": path,
        "file": path.name,
        "version": version,
        "name": name,
        "base": f"{version}_{name}",
        "direction": direction,
        "naming_mode": naming_mode,
        "sha256": sha256(path),
        "size": path.stat().st_size,
    })

bases = {}
versions = {}
for item in valid:
    bases.setdefault(item["base"], {"up": [], "down": []})
    bases[item["base"]][item["direction"]].append(item)
    versions.setdefault(item["version"], set()).add(item["base"])

up_count = sum(1 for item in valid if item["direction"] == "up")
down_count = sum(1 for item in valid if item["direction"] == "down")
pair_count = 0
missing_down = []
missing_up = []
duplicate_base = []
duplicate_version = []

for base, pair in bases.items():
    if pair["up"] and pair["down"]:
        pair_count += 1
    if pair["up"] and not pair["down"]:
        missing_down.append(base)
    if pair["down"] and not pair["up"]:
        missing_up.append(base)
    if len(pair["up"]) > 1 or len(pair["down"]) > 1:
        duplicate_base.append(base)

for version, base_set in versions.items():
    if len(base_set) > 1:
        duplicate_version.append(version)

empty_down = []
high_risk_up = []
shell_token_up = []
alter_system_up = []

for item in valid:
    path = item["path"]
    if item["direction"] == "down" and item["size"] == 0:
        empty_down.append(item["base"])
    if item["direction"] == "up":
        high_risk = count_regex(path, r"\b(drop\s+table|truncate\s+table|drop\s+schema|drop\s+database)\b")
        shell_risk = count_regex(path, r"\b(docker|systemctl|psql\s|curl\s|wget\s|bash\s|sh\s)\b")
        alter_system = count_regex(path, r"\balter\s+system\b")
        if high_risk:
            high_risk_up.append(item["base"])
        if shell_risk:
            shell_token_up.append(item["base"])
        if alter_system:
            alter_system_up.append(item["base"])

naming_status = "PASS" if not invalid else "FAIL"
pairing_status = "PASS" if not missing_down and not missing_up else "FAIL"
duplicate_status = "PASS" if not duplicate_base and not duplicate_version else "FAIL"
rollback_status = "PASS" if not empty_down else "FAIL"
risk_status = "PASS" if not alter_system_up and not shell_token_up else "FAIL"

detail(f"MIGRATION_DIR=db/migrations")
legacy_file_count = sum(1 for item in valid if item.get("naming_mode") == "legacy_seq")
modern_file_count = sum(1 for item in valid if item.get("naming_mode") == "modern_timestamp")

detail(f"MIGRATION_SQL_FILE_COUNT={len(all_sql_files)}")
detail(f"MIGRATION_VALID_FILE_COUNT={len(valid)}")
detail(f"MIGRATION_INVALID_NAME_COUNT={len(invalid)}")
detail(f"MIGRATION_LEGACY_FILE_COUNT={legacy_file_count}")
detail(f"MIGRATION_MODERN_FILE_COUNT={modern_file_count}")
detail(f"MIGRATION_UP_FILE_COUNT={up_count}")
detail(f"MIGRATION_DOWN_FILE_COUNT={down_count}")
detail(f"MIGRATION_PAIR_COUNT={pair_count}")
detail(f"MIGRATION_MISSING_DOWN_COUNT={len(missing_down)}")
detail(f"MIGRATION_MISSING_UP_COUNT={len(missing_up)}")
detail(f"MIGRATION_DUPLICATE_BASE_COUNT={len(duplicate_base)}")
detail(f"MIGRATION_DUPLICATE_VERSION_COUNT={len(duplicate_version)}")
detail(f"MIGRATION_EMPTY_DOWN_COUNT={len(empty_down)}")
detail(f"MIGRATION_HIGH_RISK_UP_COUNT={len(high_risk_up)}")
detail(f"MIGRATION_SHELL_TOKEN_UP_COUNT={len(shell_token_up)}")
detail(f"MIGRATION_ALTER_SYSTEM_UP_COUNT={len(alter_system_up)}")
detail(f"MIGRATION_NAMING_STATUS={naming_status}")
detail(f"MIGRATION_PAIRING_STATUS={pairing_status}")
detail(f"MIGRATION_DUPLICATE_STATUS={duplicate_status}")
detail(f"MIGRATION_ROLLBACK_FILE_STATUS={rollback_status}")
detail(f"MIGRATION_RISK_STATUS={risk_status}")

if len(all_sql_files) == 0:
    fail("migration sql dosyasi yok")
if naming_status != "PASS":
    fail("migration naming standard PASS degil")
if pairing_status != "PASS":
    fail("migration up/down pairing PASS degil")
if duplicate_status != "PASS":
    fail("migration duplicate status PASS degil")
if rollback_status != "PASS":
    fail("rollback/down file status PASS degil")
if risk_status != "PASS":
    fail("up migration icinde shell token veya alter system riski var")

db_check = db_schema_migrations_check()
detail(f"DB_SCHEMA_MIGRATIONS_CHECK={db_check['status']}")
detail(f"DB_SCHEMA_MIGRATIONS_REASON={db_check['reason']}")
detail(f"DB_DSN_STATUS={'CONFIGURED_MASKED' if db_check['masked_dsn'] else 'NOT_CONFIGURED_OR_SKIPPED'}")
detail(f"DB_DSN_MASKED={db_check['masked_dsn']}")
detail(f"DB_SCHEMA_MIGRATIONS_EXISTS={db_check['exists']}")
detail(f"DB_SCHEMA_MIGRATIONS_DIRTY_STATE={db_check['dirty']}")
detail(f"DB_SCHEMA_MIGRATIONS_VERSION={db_check['version']}")

if db_check["status"] == "FAIL":
    fail("schema_migrations dirty state temiz degil")
elif db_check["status"] == "WARN":
    warn(f"schema_migrations DB check warning: {db_check['reason']}")

inventory_lines = ["version\tname\tbase\tdirection\tnaming_mode\tfile\tsize_bytes\tsha256"]
for item in valid:
    inventory_lines.append(
        f"{item['version']}\t{item['name']}\t{item['base']}\t{item['direction']}\t{item.get('naming_mode','UNKNOWN')}\t{item['file']}\t{item['size']}\t{item['sha256']}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

matrix_lines = [
    "gate\tstatus\tnote",
    f"migration_directory\t{'PASS' if migration_dir.exists() else 'FAIL'}\tdb/migrations",
    f"migration_naming\t{naming_status}\tinvalid_count={len(invalid)}",
    f"migration_pairing\t{pairing_status}\tmissing_down={len(missing_down)} missing_up={len(missing_up)}",
    f"migration_duplicates\t{duplicate_status}\tduplicate_base={len(duplicate_base)} duplicate_version={len(duplicate_version)}",
    f"rollback_files\t{rollback_status}\tempty_down={len(empty_down)}",
    f"up_sql_risk\t{risk_status}\thigh_risk={len(high_risk_up)} shell_token={len(shell_token_up)} alter_system={len(alter_system_up)}",
    f"schema_migrations_db_check\t{db_check['status']}\tdirty={db_check['dirty']} version={db_check['version']}",
    "db_mutation\tNO\tread-only standard validation",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"MIGRATION_CHAIN_INVENTORY_LINE_COUNT={len(inventory_lines)}")
detail(f"MIGRATION_CHAIN_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"MIGRATION_CHAIN_STANDARD={final_status}")
detail(f"FAZ4B_14_1_FINAL_STATUS={final_status}")

risk_block = []
if invalid:
    risk_block.append("INVALID_NAMES=" + ",".join(p.name for p in invalid[:20]))
if missing_down:
    risk_block.append("MISSING_DOWN=" + ",".join(missing_down[:20]))
if missing_up:
    risk_block.append("MISSING_UP=" + ",".join(missing_up[:20]))
if duplicate_base:
    risk_block.append("DUPLICATE_BASE=" + ",".join(duplicate_base[:20]))
if duplicate_version:
    risk_block.append("DUPLICATE_VERSION=" + ",".join(duplicate_version[:20]))
if high_risk_up:
    risk_block.append("HIGH_RISK_UP=" + ",".join(high_risk_up[:20]))

report_lines = [
    "# FAZ 4B / 14.1 - Migration Chain Standardı Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"MIGRATION_CHAIN_STANDARD={final_status}",
    f"FAZ4B_14_1_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/14_1_pilot_migration_chain_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/14_1_pilot_migration_chain_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Risks",
    *(risk_block if risk_block else ["OK ✅ migration chain major risk yok"]),
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "POSTGRES_CONFIG_CHANGED=NO",
    "CONTAINER_RESTARTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
    "",
    "## Secret Safety",
    "RAW_DSN_PRINTED=NO",
    "POSTGRES_PASSWORD_PRINTED=NO",
    "AUTH_TOKEN_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"MIGRATION_SQL_FILE_COUNT={len(all_sql_files)}")
print(f"MIGRATION_LEGACY_FILE_COUNT={legacy_file_count}")
print(f"MIGRATION_MODERN_FILE_COUNT={modern_file_count}")
print(f"MIGRATION_PAIR_COUNT={pair_count}")
print(f"MIGRATION_NAMING_STATUS={naming_status}")
print(f"MIGRATION_PAIRING_STATUS={pairing_status}")
print(f"MIGRATION_DUPLICATE_STATUS={duplicate_status}")
print(f"MIGRATION_ROLLBACK_FILE_STATUS={rollback_status}")
print(f"DB_SCHEMA_MIGRATIONS_CHECK={db_check['status']}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"MIGRATION_CHAIN_STANDARD={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
