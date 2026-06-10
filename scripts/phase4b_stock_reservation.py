#!/usr/bin/env python3
import hashlib
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
migration_base = os.environ.get("MIGRATION_BASE", "20260428_185001_inventory_stock_reservation").strip()

report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "18_5_stock_reservation_standard.md"
report_file = report_dir / "18_5_stock_reservation_report.md"
inventory_file = report_dir / "18_5_stock_reservation_inventory.tsv"
matrix_file = report_dir / "18_5_stock_reservation_matrix.tsv"

up_file = migration_dir / f"{migration_base}.up.sql"
down_file = migration_dir / f"{migration_base}.down.sql"

prev_14 = report_dir / "14_migration_lifecycle_import_final_closure_report.md"
prev_15 = report_dir / "15_readmodel_reporting_final_closure_report.md"
prev_18_1 = report_dir / "18_1_opening_stock_report.md"
prev_18_2 = report_dir / "18_2_stock_movement_engine_report.md"
prev_18_3 = report_dir / "18_3_sales_stock_decrement_report.md"
prev_18_4 = report_dir / "18_4_purchase_stock_increment_report.md"

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

def tool_status(name):
    status = "FOUND" if which(name) else "NOT_FOUND"
    tools.append(f"TOOL_{name}={status}")
    return status == "FOUND"

def read(path):
    if not path.exists():
        return ""
    return path.read_text(errors="ignore")

def get_value(path, key):
    text = read(path)
    if not text:
        return ""
    value = ""
    pattern = re.compile(rf"^{re.escape(key)}=(.*)$")
    for line in text.splitlines():
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

def count(pattern, text, flags=re.IGNORECASE | re.MULTILINE):
    return len(re.findall(pattern, text, flags))

def table_names_from_up(text):
    return re.findall(
        r"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+inventory\.([a-z0-9_]+)\s*\(",
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
detail("STOCK_RESERVATION_EXECUTED=NO")
detail("STOCK_MOVEMENT_EXECUTED=NO")
detail("STOCK_BALANCE_MUTATION=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=STOCK_RESERVATION_MIGRATION_PAIR_ONLY")

tool_status("python3")
tool_status("grep")
tool_status("wc")
tool_status("sha256sum")

prev_14_status = get_value(prev_14, "FAZ4B_14_FINAL_STATUS")
prev_15_status = get_value(prev_15, "FAZ4B_15_FINAL_STATUS")
prev_18_1_status = get_value(prev_18_1, "FAZ4B_18_1_FINAL_STATUS")
prev_18_2_status = get_value(prev_18_2, "FAZ4B_18_2_FINAL_STATUS")
prev_18_3_status = get_value(prev_18_3, "FAZ4B_18_3_FINAL_STATUS")
prev_18_4_status = get_value(prev_18_4, "FAZ4B_18_4_FINAL_STATUS")
prev_18_4_purchase = get_value(prev_18_4, "PURCHASE_STOCK_INCREMENT")
prev_18_4_apply = get_value(prev_18_4, "DB_APPLY_EXECUTED")
prev_18_4_executed = get_value(prev_18_4, "PURCHASE_STOCK_INCREMENT_EXECUTED")

detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_15_FINAL_STATUS={prev_15_status}")
detail(f"PREVIOUS_18_1_FINAL_STATUS={prev_18_1_status}")
detail(f"PREVIOUS_18_2_FINAL_STATUS={prev_18_2_status}")
detail(f"PREVIOUS_18_3_FINAL_STATUS={prev_18_3_status}")
detail(f"PREVIOUS_18_4_FINAL_STATUS={prev_18_4_status}")
detail(f"PREVIOUS_18_4_PURCHASE_STOCK_INCREMENT={prev_18_4_purchase}")
detail(f"PREVIOUS_18_4_DB_APPLY_EXECUTED={prev_18_4_apply}")
detail(f"PREVIOUS_18_4_PURCHASE_STOCK_INCREMENT_EXECUTED={prev_18_4_executed}")

for ok, msg in [
    (prev_14_status == "PASS", "14 final status PASS degil"),
    (prev_15_status == "PASS", "15 final status PASS degil"),
    (prev_18_1_status == "PASS", "18.1 final status PASS degil"),
    (prev_18_2_status == "PASS", "18.2 final status PASS degil"),
    (prev_18_3_status == "PASS", "18.3 final status PASS degil"),
    (prev_18_4_status == "PASS", "18.4 final status PASS degil"),
    (prev_18_4_purchase == "PASS", "18.4 purchase stock increment PASS degil"),
    (prev_18_4_apply == "NO", "18.4 DB apply NO degil"),
    (prev_18_4_executed == "NO", "18.4 purchase increment executed NO degil"),
]:
    if not ok:
        fail(msg)

if not standard_file.exists():
    fail("18.5 standard doc yok")
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
    "stock_reservation_batches",
    "stock_reservations",
    "stock_reservation_lines",
    "stock_reservation_allocations",
    "stock_reservation_releases",
    "stock_reservation_validation_errors",
    "stock_reservation_expiry_runs",
]

missing_tables = [t for t in expected_tables if t not in unique_tables]

create_schema_count = count(r"CREATE\s+SCHEMA\s+IF\s+NOT\s+EXISTS\s+inventory", up_text)
create_table_count = len(unique_tables)
tenant_id_column_count = count(r"\btenant_id\s+text\s+NOT\s+NULL\b", up_text)
stock_reservation_id_count = count(r"\bstock_reservation_id\s+text", up_text)
stock_reservation_line_id_count = count(r"\bstock_reservation_line_id\s+text", up_text)
product_code_count = count(r"\bproduct_code\s+text", up_text)
location_code_count = count(r"\blocation_code\s+text", up_text)
quantity_count = count(r"\bquantity\s+numeric\(18,4\)\s+NOT\s+NULL\b", up_text)
reserved_quantity_count = count(r"\breserved_quantity\s+numeric\(18,4\)\s+NOT\s+NULL\b", up_text)
available_quantity_count = count(r"\bavailable_quantity\s+numeric\(18,4\)\s+NOT\s+NULL\b", up_text)
reserved_quantity_delta_count = count(r"\breserved_quantity_delta\s+numeric\(18,4\)\s+NOT\s+NULL\b", up_text)
available_quantity_delta_count = count(r"\bavailable_quantity_delta\s+numeric\(18,4\)\s+NOT\s+NULL\b", up_text)
expires_at_count = count(r"\bexpires_at\s+timestamptz\b", up_text)
expires_before_count = count(r"\bexpires_before\s+timestamptz\s+NOT\s+NULL\b", up_text)
idempotency_key_count = count(r"\bidempotency_key\s+text\s+NOT\s+NULL\b", up_text)
status_code_count = count(r"\bstatus_code\s+text\s+NOT\s+NULL", up_text)
reservation_status_count = count(r"\breservation_status\s+text\s+NOT\s+NULL", up_text)
unique_constraint_count = count(r"\bUNIQUE\s*\(", up_text)
create_index_count = count(r"CREATE\s+INDEX\s+IF\s+NOT\s+EXISTS", up_text)
drop_table_count = count(r"DROP\s+TABLE\s+IF\s+EXISTS\s+inventory\.", down_text)

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
detail(f"STOCK_RESERVATION_TABLE_COUNT={create_table_count}")
detail(f"STOCK_RESERVATION_EXPECTED_TABLE_MISSING_COUNT={len(missing_tables)}")
detail(f"STOCK_RESERVATION_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
detail(f"STOCK_RESERVATION_ID_REFERENCE_COUNT={stock_reservation_id_count}")
detail(f"STOCK_RESERVATION_LINE_ID_REFERENCE_COUNT={stock_reservation_line_id_count}")
detail(f"STOCK_RESERVATION_PRODUCT_CODE_COLUMN_COUNT={product_code_count}")
detail(f"STOCK_RESERVATION_LOCATION_CODE_COLUMN_COUNT={location_code_count}")
detail(f"STOCK_RESERVATION_QUANTITY_COUNT={quantity_count}")
detail(f"STOCK_RESERVATION_RESERVED_QUANTITY_COUNT={reserved_quantity_count}")
detail(f"STOCK_RESERVATION_AVAILABLE_QUANTITY_COUNT={available_quantity_count}")
detail(f"STOCK_RESERVATION_RESERVED_DELTA_COUNT={reserved_quantity_delta_count}")
detail(f"STOCK_RESERVATION_AVAILABLE_DELTA_COUNT={available_quantity_delta_count}")
detail(f"STOCK_RESERVATION_EXPIRES_AT_COUNT={expires_at_count}")
detail(f"STOCK_RESERVATION_EXPIRES_BEFORE_COUNT={expires_before_count}")
detail(f"STOCK_RESERVATION_IDEMPOTENCY_KEY_COUNT={idempotency_key_count}")
detail(f"STOCK_RESERVATION_STATUS_CODE_COLUMN_COUNT={status_code_count}")
detail(f"STOCK_RESERVATION_RESERVATION_STATUS_COUNT={reservation_status_count}")
detail(f"STOCK_RESERVATION_UNIQUE_CONSTRAINT_COUNT={unique_constraint_count}")
detail(f"STOCK_RESERVATION_INDEX_COUNT={create_index_count}")
detail(f"STOCK_RESERVATION_DOWN_DROP_TABLE_COUNT={drop_table_count}")

for key, value in forbidden_up_tokens.items():
    detail(f"{key.upper()}={value}")

if create_schema_count != 1:
    fail("inventory create schema count 1 degil")
if create_table_count != len(expected_tables):
    fail("expected stock reservation table count 7 degil")
if missing_tables:
    fail("expected stock reservation table eksik: " + ",".join(missing_tables))
if tenant_id_column_count != len(expected_tables):
    fail("tenant_id not null column count 7 degil")
if stock_reservation_id_count < 5:
    fail("stock_reservation_id count 5 altinda")
if stock_reservation_line_id_count < 4:
    fail("stock_reservation_line_id count 4 altinda")
if product_code_count < 4:
    fail("product_code count 4 altinda")
if location_code_count < 4:
    fail("location_code count 4 altinda")
if quantity_count < 4:
    fail("quantity count 4 altinda")
if reserved_quantity_count < 3:
    fail("reserved_quantity count 3 altinda")
if available_quantity_count < 3:
    fail("available_quantity count 3 altinda")
if reserved_quantity_delta_count < 3:
    fail("reserved_quantity_delta count 3 altinda")
if available_quantity_delta_count < 3:
    fail("available_quantity_delta count 3 altinda")
if expires_at_count < 3:
    fail("expires_at count 3 altinda")
if expires_before_count < 1:
    fail("expires_before count 1 altinda")
if idempotency_key_count < 4:
    fail("idempotency_key count 4 altinda")
if status_code_count < 5:
    fail("status_code count 5 altinda")
if reservation_status_count < 4:
    fail("reservation_status count 4 altinda")
if unique_constraint_count < 10:
    fail("unique constraint count 10 altinda")
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
reservation_ref_status = "PASS" if stock_reservation_id_count >= 5 and stock_reservation_line_id_count >= 4 else "FAIL"
quantity_status = "PASS" if quantity_count >= 4 and reserved_quantity_count >= 3 and available_quantity_count >= 3 else "FAIL"
delta_status = "PASS" if reserved_quantity_delta_count >= 3 and available_quantity_delta_count >= 3 else "FAIL"
expiry_status = "PASS" if expires_at_count >= 3 and expires_before_count >= 1 else "FAIL"
idempotency_status = "PASS" if idempotency_key_count >= 4 else "FAIL"
lifecycle_status = "PASS" if status_code_count >= 5 and reservation_status_count >= 4 else "FAIL"
index_status = "PASS" if create_index_count >= 14 else "FAIL"
down_status = "PASS" if drop_table_count == 7 else "FAIL"
risk_status = "PASS" if not any(forbidden_up_tokens.values()) else "FAIL"
chain_status = "PASS" if chain["invalid_count"] == 0 and chain["missing_pair_count"] == 0 and chain["duplicate_pair_count"] == 0 else "FAIL"

detail(f"STOCK_RESERVATION_MIGRATION_PAIR={pair_status}")
detail(f"STOCK_RESERVATION_SCHEMA_STATUS={schema_status}")
detail(f"STOCK_RESERVATION_TABLE_STATUS={table_status}")
detail(f"STOCK_RESERVATION_TENANT_SAFETY_STATUS={tenant_status}")
detail(f"STOCK_RESERVATION_REFERENCE_STATUS={reservation_ref_status}")
detail(f"STOCK_RESERVATION_QUANTITY_STATUS={quantity_status}")
detail(f"STOCK_RESERVATION_DELTA_STATUS={delta_status}")
detail(f"STOCK_RESERVATION_EXPIRY_STATUS={expiry_status}")
detail(f"STOCK_RESERVATION_IDEMPOTENCY_STATUS={idempotency_status}")
detail(f"STOCK_RESERVATION_LIFECYCLE_STATUS={lifecycle_status}")
detail(f"STOCK_RESERVATION_INDEX_STATUS={index_status}")
detail(f"STOCK_RESERVATION_DOWN_STATUS={down_status}")
detail(f"STOCK_RESERVATION_RISK_STATUS={risk_status}")
detail(f"STOCK_RESERVATION_CHAIN_STATUS={chain_status}")

for name, status in [
    ("migration_pair", pair_status),
    ("schema", schema_status),
    ("table", table_status),
    ("tenant_safety", tenant_status),
    ("reservation_reference", reservation_ref_status),
    ("quantity", quantity_status),
    ("delta", delta_status),
    ("expiry", expiry_status),
    ("idempotency", idempotency_status),
    ("lifecycle", lifecycle_status),
    ("index", index_status),
    ("down", down_status),
    ("risk", risk_status),
    ("chain", chain_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

inventory_lines = ["table\tstatus\ttenant_id_required\tpurpose\tnote"]
purpose = {
    "stock_reservation_batches": "reservation_batch_header",
    "stock_reservations": "reservation_header",
    "stock_reservation_lines": "reservation_line_items",
    "stock_reservation_allocations": "reserved_available_delta_candidates",
    "stock_reservation_releases": "reservation_release_lifecycle",
    "stock_reservation_validation_errors": "reservation_validation",
    "stock_reservation_expiry_runs": "reservation_expiry_gate",
}
for table in expected_tables:
    table_present = "YES" if table in unique_tables else "NO"
    inventory_lines.append(
        f"{table}\t{table_present}\tYES\t{purpose[table]}\tinventory.{table}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_14\t{prev_14_status}\tmigration lifecycle prerequisite",
    f"previous_15\t{prev_15_status}\treadmodel/reporting prerequisite",
    f"previous_18_1\t{prev_18_1_status}\topening stock prerequisite",
    f"previous_18_2\t{prev_18_2_status}\tstock movement prerequisite",
    f"previous_18_3\t{prev_18_3_status}\tsales decrement prerequisite",
    f"previous_18_4\t{prev_18_4_status}\tpurchase increment prerequisite",
    f"migration_pair\t{pair_status}\tup/down files exist",
    f"schema\t{schema_status}\tcreate_schema_count={create_schema_count}",
    f"tables\t{table_status}\ttable_count={create_table_count}",
    f"tenant_safety\t{tenant_status}\ttenant_id={tenant_id_column_count}",
    f"reservation_reference\t{reservation_ref_status}\treservation_id={stock_reservation_id_count} line_id={stock_reservation_line_id_count}",
    f"quantity\t{quantity_status}\tquantity={quantity_count} reserved={reserved_quantity_count} available={available_quantity_count}",
    f"delta\t{delta_status}\treserved_delta={reserved_quantity_delta_count} available_delta={available_quantity_delta_count}",
    f"expiry\t{expiry_status}\texpires_at={expires_at_count} expires_before={expires_before_count}",
    f"idempotency\t{idempotency_status}\tidempotency_key={idempotency_key_count}",
    f"lifecycle\t{lifecycle_status}\tstatus_code={status_code_count} reservation_status={reservation_status_count}",
    f"indexes\t{index_status}\tindex_count={create_index_count}",
    f"down_migration\t{down_status}\tdrop_table_count={drop_table_count}",
    f"risk\t{risk_status}\tno destructive/system token in up",
    f"current_migration_chain\t{chain_status}\tpairs={chain['pair_count']}",
    "db_mutation\tNO\tmigration pair only",
    "db_apply_executed\tNO\tapply gate is later",
    "stock_reservation_executed\tNO\truntime later",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"STOCK_RESERVATION_INVENTORY_LINE_COUNT={len(inventory_lines)}")
detail(f"STOCK_RESERVATION_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"STOCK_RESERVATION={final_status}")
detail(f"FAZ4B_18_5_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 18.5 - Stock Reservation Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"STOCK_RESERVATION={final_status}",
    f"FAZ4B_18_5_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/18_5_stock_reservation_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/18_5_stock_reservation_matrix.tsv",
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
    "STOCK_RESERVATION_EXECUTED=NO",
    "STOCK_MOVEMENT_EXECUTED=NO",
    "STOCK_BALANCE_MUTATION=NO",
    "POSTGRES_CONFIG_CHANGED=NO",
    "CONTAINER_RESTARTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "",
    "## Issues",
    *(failures if failures else ["OK ✅ issue yok"]),
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
print(f"STOCK_RESERVATION_TABLE_COUNT={create_table_count}")
print(f"STOCK_RESERVATION_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
print(f"STOCK_RESERVATION_INDEX_COUNT={create_index_count}")
print(f"STOCK_RESERVATION_MIGRATION_PAIR={pair_status}")
print(f"STOCK_RESERVATION_TABLE_STATUS={table_status}")
print(f"STOCK_RESERVATION_TENANT_SAFETY_STATUS={tenant_status}")
print(f"STOCK_RESERVATION_QUANTITY_STATUS={quantity_status}")
print(f"STOCK_RESERVATION_EXPIRY_STATUS={expiry_status}")
print(f"STOCK_RESERVATION_CHAIN_STATUS={chain_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("STOCK_RESERVATION_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"STOCK_RESERVATION={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
