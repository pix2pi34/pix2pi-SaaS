#!/usr/bin/env python3
import hashlib
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
migration_base = os.environ.get("MIGRATION_BASE", "20260428_155001_search_index_projection_tables").strip()

report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "15_5_search_index_projection_tables_standard.md"
report_file = report_dir / "15_5_search_index_projection_tables_report.md"
inventory_file = report_dir / "15_5_search_index_projection_tables_inventory.tsv"
matrix_file = report_dir / "15_5_search_index_projection_tables_matrix.tsv"

up_file = migration_dir / f"{migration_base}.up.sql"
down_file = migration_dir / f"{migration_base}.down.sql"

prev_14 = report_dir / "14_migration_lifecycle_import_final_closure_report.md"
prev_15_2 = report_dir / "15_2_finance_reporting_mart_report.md"
prev_15_3 = report_dir / "15_3_ebelge_export_reporting_mart_report.md"
prev_15_4 = report_dir / "15_4_payment_reconciliation_reporting_mart_report.md"

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
        r"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+search_projection\.([a-z0-9_]+)\s*\(",
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
detail("VALIDATION_MODE=SEARCH_INDEX_PROJECTION_MIGRATION_PAIR_ONLY")

tool_status("python3")
tool_status("grep")
tool_status("wc")
tool_status("sha256sum")

prev_14_status = get_value(prev_14, "FAZ4B_14_FINAL_STATUS")
prev_14_tests = get_value(prev_14, "MIGRATION_LIFECYCLE_IMPORT_TESTS")
prev_15_2_status = get_value(prev_15_2, "FAZ4B_15_2_FINAL_STATUS")
prev_15_2_mart = get_value(prev_15_2, "FINANCE_REPORTING_MART")
prev_15_3_status = get_value(prev_15_3, "FAZ4B_15_3_FINAL_STATUS")
prev_15_3_mart = get_value(prev_15_3, "EBELGE_EXPORT_REPORTING_MART")
prev_15_4_status = get_value(prev_15_4, "FAZ4B_15_4_FINAL_STATUS")
prev_15_4_mart = get_value(prev_15_4, "PAYMENT_RECONCILIATION_REPORTING_MART")
prev_15_4_db_apply = get_value(prev_15_4, "DB_APPLY_EXECUTED")

detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_14_MIGRATION_LIFECYCLE_IMPORT_TESTS={prev_14_tests}")
detail(f"PREVIOUS_15_2_FINAL_STATUS={prev_15_2_status}")
detail(f"PREVIOUS_15_2_FINANCE_REPORTING_MART={prev_15_2_mart}")
detail(f"PREVIOUS_15_3_FINAL_STATUS={prev_15_3_status}")
detail(f"PREVIOUS_15_3_EBELGE_EXPORT_REPORTING_MART={prev_15_3_mart}")
detail(f"PREVIOUS_15_4_FINAL_STATUS={prev_15_4_status}")
detail(f"PREVIOUS_15_4_PAYMENT_RECONCILIATION_REPORTING_MART={prev_15_4_mart}")
detail(f"PREVIOUS_15_4_DB_APPLY_EXECUTED={prev_15_4_db_apply}")

if prev_14_status != "PASS":
    fail("14 final status PASS degil")
if prev_14_tests != "PASS":
    fail("14 migration lifecycle import tests PASS degil")
if prev_15_2_status != "PASS":
    fail("15.2 final status PASS degil")
if prev_15_2_mart != "PASS":
    fail("15.2 finance reporting mart PASS degil")
if prev_15_3_status != "PASS":
    fail("15.3 final status PASS degil")
if prev_15_3_mart != "PASS":
    fail("15.3 ebelge export reporting mart PASS degil")
if prev_15_4_status != "PASS":
    fail("15.4 final status PASS degil")
if prev_15_4_mart != "PASS":
    fail("15.4 payment reconciliation reporting mart PASS degil")
if prev_15_4_db_apply != "NO":
    fail("15.4 DB apply NO degil")

if not standard_file.exists():
    fail("15.5 standard doc yok")
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
    "party_search_documents",
    "product_search_documents",
    "inventory_search_documents",
    "business_document_search_documents",
    "finance_search_documents",
    "global_search_documents",
    "search_projection_rebuild_state",
]

missing_tables = [t for t in expected_tables if t not in unique_tables]

create_schema_count = count(r"CREATE\s+SCHEMA\s+IF\s+NOT\s+EXISTS\s+search_projection", up_text)
create_table_count = len(unique_tables)
tenant_id_column_count = count(r"\btenant_id\s+text\s+NOT\s+NULL\b", up_text)
entity_id_column_count = count(r"\bentity_id\s+text\s+NOT\s+NULL\b", up_text)
entity_type_column_count = count(r"\bentity_type\s+text\s+NOT\s+NULL", up_text)
search_text_column_count = count(r"\bsearch_text\s+text\s+NOT\s+NULL\b", up_text)
search_keywords_column_count = count(r"\bsearch_keywords\s+text\[\]\s+NOT\s+NULL\b", up_text)
jsonb_route_params_count = count(r"\broute_params\s+jsonb\b", up_text)
numeric_metric_count = count(r"\bnumeric\(", up_text)
unique_constraint_count = count(r"\bUNIQUE\s*\(", up_text)
create_index_count = count(r"CREATE\s+INDEX\s+IF\s+NOT\s+EXISTS", up_text)
drop_table_count = count(r"DROP\s+TABLE\s+IF\s+EXISTS\s+search_projection\.", down_text)

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
detail(f"SEARCH_INDEX_TABLE_COUNT={create_table_count}")
detail(f"SEARCH_INDEX_EXPECTED_TABLE_MISSING_COUNT={len(missing_tables)}")
detail(f"SEARCH_INDEX_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
detail(f"SEARCH_INDEX_ENTITY_ID_COLUMN_COUNT={entity_id_column_count}")
detail(f"SEARCH_INDEX_ENTITY_TYPE_COLUMN_COUNT={entity_type_column_count}")
detail(f"SEARCH_INDEX_SEARCH_TEXT_COLUMN_COUNT={search_text_column_count}")
detail(f"SEARCH_INDEX_SEARCH_KEYWORDS_COLUMN_COUNT={search_keywords_column_count}")
detail(f"SEARCH_INDEX_JSONB_ROUTE_PARAMS_COUNT={jsonb_route_params_count}")
detail(f"SEARCH_INDEX_NUMERIC_METRIC_COUNT={numeric_metric_count}")
detail(f"SEARCH_INDEX_UNIQUE_CONSTRAINT_COUNT={unique_constraint_count}")
detail(f"SEARCH_INDEX_INDEX_COUNT={create_index_count}")
detail(f"SEARCH_INDEX_DOWN_DROP_TABLE_COUNT={drop_table_count}")

for key, value in forbidden_up_tokens.items():
    detail(f"{key.upper()}={value}")

if create_schema_count != 1:
    fail("search_projection create schema count 1 degil")
if create_table_count != len(expected_tables):
    fail("expected search projection table count 7 degil")
if missing_tables:
    fail("expected search projection table eksik: " + ",".join(missing_tables))
if tenant_id_column_count != len(expected_tables):
    fail("tenant_id not null column count 7 degil")
if entity_id_column_count < 6:
    fail("entity_id column count 6 altinda")
if entity_type_column_count < 6:
    fail("entity_type column count 6 altinda")
if search_text_column_count < 6:
    fail("search_text column count 6 altinda")
if search_keywords_column_count < 6:
    fail("search_keywords column count 6 altinda")
if unique_constraint_count != len(expected_tables):
    fail("unique constraint count 7 degil")
if create_index_count < 14:
    fail("create index count 14 altinda")
if drop_table_count != len(expected_tables):
    fail("down migration drop table count 7 degil")
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
table_status = "PASS" if create_table_count == 7 and not missing_tables else "FAIL"
tenant_status = "PASS" if tenant_id_column_count == 7 else "FAIL"
entity_status = "PASS" if entity_id_column_count >= 6 and entity_type_column_count >= 6 else "FAIL"
search_text_status = "PASS" if search_text_column_count >= 6 and search_keywords_column_count >= 6 else "FAIL"
global_route_status = "PASS" if jsonb_route_params_count >= 1 else "FAIL"
index_status = "PASS" if create_index_count >= 14 else "FAIL"
down_status = "PASS" if drop_table_count == 7 else "FAIL"
risk_status = "PASS" if not any(forbidden_up_tokens.values()) else "FAIL"
chain_status = "PASS" if chain["invalid_count"] == 0 and chain["missing_pair_count"] == 0 and chain["duplicate_pair_count"] == 0 else "FAIL"

detail(f"SEARCH_INDEX_MIGRATION_PAIR={pair_status}")
detail(f"SEARCH_INDEX_SCHEMA_STATUS={schema_status}")
detail(f"SEARCH_INDEX_TABLE_STATUS={table_status}")
detail(f"SEARCH_INDEX_TENANT_SAFETY_STATUS={tenant_status}")
detail(f"SEARCH_INDEX_ENTITY_STATUS={entity_status}")
detail(f"SEARCH_INDEX_SEARCH_TEXT_STATUS={search_text_status}")
detail(f"SEARCH_INDEX_GLOBAL_ROUTE_STATUS={global_route_status}")
detail(f"SEARCH_INDEX_INDEX_STATUS={index_status}")
detail(f"SEARCH_INDEX_DOWN_STATUS={down_status}")
detail(f"SEARCH_INDEX_RISK_STATUS={risk_status}")
detail(f"SEARCH_INDEX_CHAIN_STATUS={chain_status}")

for name, status in [
    ("migration_pair", pair_status),
    ("schema", schema_status),
    ("table", table_status),
    ("tenant_safety", tenant_status),
    ("entity", entity_status),
    ("search_text", search_text_status),
    ("global_route", global_route_status),
    ("index", index_status),
    ("down", down_status),
    ("risk", risk_status),
    ("chain", chain_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

inventory_lines = ["table\tstatus\ttenant_id_required\tentity_id\tsearch_text\tsearch_keywords\tnote"]
for table in expected_tables:
    table_present = "YES" if table in unique_tables else "NO"
    entity_required = "NO" if table == "search_projection_rebuild_state" else "YES"
    search_required = "NO" if table == "search_projection_rebuild_state" else "YES"
    inventory_lines.append(
        f"{table}\t{table_present}\tYES\t{entity_required}\t{search_required}\t{search_required}\tsearch_projection.{table}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_14\t{prev_14_status}\tmigration lifecycle prerequisite",
    f"previous_15_2\t{prev_15_2_status}\tfinance reporting prerequisite",
    f"previous_15_3\t{prev_15_3_status}\tebelge/export prerequisite",
    f"previous_15_4\t{prev_15_4_status}\tpayment/reconciliation prerequisite",
    f"migration_pair\t{pair_status}\tup/down files exist",
    f"schema\t{schema_status}\tcreate_schema_count={create_schema_count}",
    f"tables\t{table_status}\ttable_count={create_table_count}",
    f"tenant_safety\t{tenant_status}\ttenant_id={tenant_id_column_count}",
    f"entity\t{entity_status}\tentity_id={entity_id_column_count} entity_type={entity_type_column_count}",
    f"search_text\t{search_text_status}\tsearch_text={search_text_column_count} keywords={search_keywords_column_count}",
    f"global_route\t{global_route_status}\tjsonb_route_params={jsonb_route_params_count}",
    f"indexes\t{index_status}\tindex_count={create_index_count}",
    f"down_migration\t{down_status}\tdrop_table_count={drop_table_count}",
    f"risk\t{risk_status}\tno destructive/system token in up",
    f"current_migration_chain\t{chain_status}\tpairs={chain['pair_count']}",
    "db_mutation\tNO\tmigration pair only",
    "db_apply_executed\tNO\tapply gate is later",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"SEARCH_INDEX_INVENTORY_LINE_COUNT={len(inventory_lines)}")
detail(f"SEARCH_INDEX_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"SEARCH_INDEX_PROJECTION_TABLES={final_status}")
detail(f"FAZ4B_15_5_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 15.5 - Search / Index Projection Tabloları Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"SEARCH_INDEX_PROJECTION_TABLES={final_status}",
    f"FAZ4B_15_5_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/15_5_search_index_projection_tables_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/15_5_search_index_projection_tables_matrix.tsv",
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
print(f"SEARCH_INDEX_TABLE_COUNT={create_table_count}")
print(f"SEARCH_INDEX_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
print(f"SEARCH_INDEX_ENTITY_ID_COLUMN_COUNT={entity_id_column_count}")
print(f"SEARCH_INDEX_SEARCH_TEXT_COLUMN_COUNT={search_text_column_count}")
print(f"SEARCH_INDEX_INDEX_COUNT={create_index_count}")
print(f"SEARCH_INDEX_MIGRATION_PAIR={pair_status}")
print(f"SEARCH_INDEX_TABLE_STATUS={table_status}")
print(f"SEARCH_INDEX_TENANT_SAFETY_STATUS={tenant_status}")
print(f"SEARCH_INDEX_CHAIN_STATUS={chain_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"SEARCH_INDEX_PROJECTION_TABLES={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
