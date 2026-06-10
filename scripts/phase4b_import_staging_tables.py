#!/usr/bin/env python3
import hashlib
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
migration_base = os.environ.get("MIGRATION_BASE", "20260428_143001_import_staging_tables").strip()

report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "14_3_import_staging_tables_standard.md"
report_file = report_dir / "14_3_import_staging_tables_report.md"
inventory_file = report_dir / "14_3_import_staging_tables_inventory.tsv"
matrix_file = report_dir / "14_3_import_staging_tables_matrix.tsv"

up_file = migration_dir / f"{migration_base}.up.sql"
down_file = migration_dir / f"{migration_base}.down.sql"

prev_14_1 = report_dir / "14_1_pilot_migration_chain_report.md"
prev_14_2 = report_dir / "14_2_reference_seed_report.md"

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
    if not path.exists():
        return "NA"
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def read(path):
    if not path.exists():
        return ""
    return path.read_text(errors="ignore")

def count(pattern, text, flags=re.IGNORECASE | re.MULTILINE):
    return len(re.findall(pattern, text, flags))

def table_names_from_up(text):
    return re.findall(
        r"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+import_pipeline\.([a-z0-9_]+)\s*\(",
        text,
        re.IGNORECASE,
    )

def all_current_migrations_valid():
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
        "invalid_count": len(invalid),
        "pair_count": len(bases),
        "missing_pair_count": len(missing),
        "duplicate_pair_count": len(duplicate),
    }

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail(f"MIGRATION_BASE={migration_base}")
detail(f"UP_FILE=db/migrations/{migration_base}.up.sql")
detail(f"DOWN_FILE=db/migrations/{migration_base}.down.sql")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=YES")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=MIGRATION_PAIR_CREATE_ONLY")

tool_status("python3")
tool_status("grep")
tool_status("wc")
tool_status("sha256sum")

prev_14_1_status = get_value(prev_14_1, "FAZ4B_14_1_FINAL_STATUS")
prev_14_1_chain = get_value(prev_14_1, "MIGRATION_CHAIN_STANDARD")
prev_14_2_status = get_value(prev_14_2, "FAZ4B_14_2_FINAL_STATUS")
prev_14_2_seed = get_value(prev_14_2, "REFERENCE_SEED_STANDARD")

detail(f"PREVIOUS_14_1_FINAL_STATUS={prev_14_1_status}")
detail(f"PREVIOUS_14_1_MIGRATION_CHAIN_STANDARD={prev_14_1_chain}")
detail(f"PREVIOUS_14_2_FINAL_STATUS={prev_14_2_status}")
detail(f"PREVIOUS_14_2_REFERENCE_SEED_STANDARD={prev_14_2_seed}")

if prev_14_1_status != "PASS":
    fail("14.1 final status PASS degil")
if prev_14_1_chain != "PASS":
    fail("14.1 migration chain standard PASS degil")
if prev_14_2_status != "PASS":
    fail("14.2 final status PASS degil")
if prev_14_2_seed != "PASS":
    fail("14.2 reference seed standard PASS degil")

if not standard_file.exists():
    fail("14.3 standard doc yok")
if not up_file.exists():
    fail("up migration file yok")
if not down_file.exists():
    fail("down migration file yok")

up_text = read(up_file)
down_text = read(down_file)

up_sha = sha256(up_file)
down_sha = sha256(down_file)

tables = table_names_from_up(up_text)
unique_tables = sorted(set(tables))

expected_tables = [
    "import_batches",
    "import_files",
    "import_customers_staging",
    "import_vendors_staging",
    "import_products_staging",
    "import_opening_stocks_staging",
    "import_price_lists_staging",
    "import_validation_errors",
    "import_row_status_events",
]

missing_tables = [t for t in expected_tables if t not in unique_tables]

create_schema_count = count(r"CREATE\s+SCHEMA\s+IF\s+NOT\s+EXISTS\s+import_pipeline", up_text)
create_table_count = len(unique_tables)
tenant_id_column_count = count(r"\btenant_id\s+text\s+NOT\s+NULL\b", up_text)
import_batch_id_count = count(r"\bimport_batch_id\s+text\s+NOT\s+NULL\b", up_text)
jsonb_payload_count = count(r"\braw_payload\s+jsonb\b", up_text)
validation_status_count = count(r"\bvalidation_status\s+text\s+NOT\s+NULL\b", up_text)
apply_status_count = count(r"\bapply_status\s+text\s+NOT\s+NULL\b", up_text)
create_index_count = count(r"CREATE\s+INDEX\s+IF\s+NOT\s+EXISTS", up_text)
drop_table_count = count(r"DROP\s+TABLE\s+IF\s+EXISTS\s+import_pipeline\.", down_text)

forbidden_up_tokens = {
    "drop_table_in_up": count(r"\bDROP\s+TABLE\b", up_text),
    "truncate_in_up": count(r"\bTRUNCATE\b", up_text),
    "alter_system_in_up": count(r"\bALTER\s+SYSTEM\b", up_text),
    "docker_in_up": count(r"\bdocker\b", up_text),
    "systemctl_in_up": count(r"\bsystemctl\b", up_text),
    "psql_in_up": count(r"\bpsql\b", up_text),
}

detail(f"UP_FILE_SHA256={up_sha}")
detail(f"DOWN_FILE_SHA256={down_sha}")
detail(f"CREATE_SCHEMA_COUNT={create_schema_count}")
detail(f"IMPORT_STAGING_TABLE_COUNT={create_table_count}")
detail(f"IMPORT_STAGING_EXPECTED_TABLE_MISSING_COUNT={len(missing_tables)}")
detail(f"IMPORT_STAGING_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
detail(f"IMPORT_STAGING_IMPORT_BATCH_ID_COLUMN_COUNT={import_batch_id_count}")
detail(f"IMPORT_STAGING_JSONB_PAYLOAD_COLUMN_COUNT={jsonb_payload_count}")
detail(f"IMPORT_STAGING_VALIDATION_STATUS_COLUMN_COUNT={validation_status_count}")
detail(f"IMPORT_STAGING_APPLY_STATUS_COLUMN_COUNT={apply_status_count}")
detail(f"IMPORT_STAGING_INDEX_COUNT={create_index_count}")
detail(f"IMPORT_STAGING_DOWN_DROP_TABLE_COUNT={drop_table_count}")

for key, value in forbidden_up_tokens.items():
    detail(f"{key.upper()}={value}")

if create_schema_count != 1:
    fail("import_pipeline create schema count 1 degil")
if create_table_count != len(expected_tables):
    fail("expected import staging table count 9 degil")
if missing_tables:
    fail("expected import staging table eksik: " + ",".join(missing_tables))
if tenant_id_column_count != len(expected_tables):
    fail("tenant_id not null column count 9 degil")
if import_batch_id_count < 8:
    fail("import_batch_id not null column count 8 altinda")
if jsonb_payload_count < 5:
    fail("raw_payload jsonb count 5 altinda")
if validation_status_count < 5:
    fail("validation_status count 5 altinda")
if apply_status_count < 5:
    fail("apply_status count 5 altinda")
if create_index_count < 10:
    fail("create index count 10 altinda")
if drop_table_count != len(expected_tables):
    fail("down migration drop table count 9 degil")
if any(forbidden_up_tokens.values()):
    fail("up migration icinde yasakli operasyon tokeni var")

chain = all_current_migrations_valid()
detail(f"CURRENT_MIGRATION_SQL_FILE_COUNT={chain['sql_count']}")
detail(f"CURRENT_MIGRATION_INVALID_NAME_COUNT={chain['invalid_count']}")
detail(f"CURRENT_MIGRATION_PAIR_COUNT={chain['pair_count']}")
detail(f"CURRENT_MIGRATION_MISSING_PAIR_COUNT={chain['missing_pair_count']}")
detail(f"CURRENT_MIGRATION_DUPLICATE_PAIR_COUNT={chain['duplicate_pair_count']}")

if chain["invalid_count"] != 0:
    fail("current migration invalid name count 0 degil")
if chain["missing_pair_count"] != 0:
    fail("current migration missing pair count 0 degil")
if chain["duplicate_pair_count"] != 0:
    fail("current migration duplicate pair count 0 degil")

pair_status = "PASS" if up_file.exists() and down_file.exists() else "FAIL"
schema_status = "PASS" if create_schema_count == 1 else "FAIL"
table_status = "PASS" if create_table_count == 9 and not missing_tables else "FAIL"
tenant_status = "PASS" if tenant_id_column_count == 9 and import_batch_id_count >= 8 else "FAIL"
index_status = "PASS" if create_index_count >= 10 else "FAIL"
down_status = "PASS" if drop_table_count == 9 else "FAIL"
risk_status = "PASS" if not any(forbidden_up_tokens.values()) else "FAIL"
chain_status = "PASS" if chain["invalid_count"] == 0 and chain["missing_pair_count"] == 0 and chain["duplicate_pair_count"] == 0 else "FAIL"

detail(f"IMPORT_STAGING_MIGRATION_PAIR={pair_status}")
detail(f"IMPORT_STAGING_SCHEMA_STATUS={schema_status}")
detail(f"IMPORT_STAGING_TABLE_STATUS={table_status}")
detail(f"IMPORT_STAGING_TENANT_SAFETY_STATUS={tenant_status}")
detail(f"IMPORT_STAGING_INDEX_STATUS={index_status}")
detail(f"IMPORT_STAGING_DOWN_STATUS={down_status}")
detail(f"IMPORT_STAGING_RISK_STATUS={risk_status}")
detail(f"IMPORT_STAGING_CHAIN_STATUS={chain_status}")

for name, status in [
    ("migration_pair", pair_status),
    ("schema", schema_status),
    ("table", table_status),
    ("tenant_safety", tenant_status),
    ("index", index_status),
    ("down", down_status),
    ("risk", risk_status),
    ("chain", chain_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

inventory_lines = ["table\tstatus\ttenant_id_required\timport_batch_id_required\tnote"]
for table in expected_tables:
    table_present = "YES" if table in unique_tables else "NO"
    batch_required = "NO" if table == "import_batches" else "YES"
    inventory_lines.append(
        f"{table}\t{table_present}\tYES\t{batch_required}\timport_pipeline.{table}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_14_1\t{prev_14_1_status}\tmigration chain prerequisite",
    f"previous_14_2\t{prev_14_2_status}\treference seed prerequisite",
    f"migration_pair\t{pair_status}\tup/down files exist",
    f"schema\t{schema_status}\tcreate_schema_count={create_schema_count}",
    f"tables\t{table_status}\ttable_count={create_table_count}",
    f"tenant_safety\t{tenant_status}\ttenant_id={tenant_id_column_count} import_batch_id={import_batch_id_count}",
    f"payload_lifecycle\t{'PASS' if jsonb_payload_count >= 5 and validation_status_count >= 5 and apply_status_count >= 5 else 'FAIL'}\tpayload={jsonb_payload_count} validation={validation_status_count} apply={apply_status_count}",
    f"indexes\t{index_status}\tindex_count={create_index_count}",
    f"down_migration\t{down_status}\tdrop_table_count={drop_table_count}",
    f"risk\t{risk_status}\tno destructive/system token in up",
    f"current_migration_chain\t{chain_status}\tpairs={chain['pair_count']}",
    "db_mutation\tNO\tmigration pair only",
    "db_apply_executed\tNO\tapply gate is later",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"IMPORT_STAGING_INVENTORY_LINE_COUNT={len(inventory_lines)}")
detail(f"IMPORT_STAGING_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"IMPORT_STAGING_TABLES={final_status}")
detail(f"FAZ4B_14_3_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 14.3 - Import / Staging Tabloları Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"IMPORT_STAGING_TABLES={final_status}",
    f"FAZ4B_14_3_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/14_3_import_staging_tables_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/14_3_import_staging_tables_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Migration Files",
    f"UP_FILE=db/migrations/{migration_base}.up.sql",
    f"DOWN_FILE=db/migrations/{migration_base}.down.sql",
    f"UP_FILE_SHA256={up_sha}",
    f"DOWN_FILE_SHA256={down_sha}",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=YES",
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
print(f"UP_FILE={up_file}")
print(f"DOWN_FILE={down_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"IMPORT_STAGING_TABLE_COUNT={create_table_count}")
print(f"IMPORT_STAGING_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
print(f"IMPORT_STAGING_INDEX_COUNT={create_index_count}")
print(f"IMPORT_STAGING_MIGRATION_PAIR={pair_status}")
print(f"IMPORT_STAGING_TABLE_STATUS={table_status}")
print(f"IMPORT_STAGING_TENANT_SAFETY_STATUS={tenant_status}")
print(f"IMPORT_STAGING_CHAIN_STATUS={chain_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"IMPORT_STAGING_TABLES={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
