#!/usr/bin/env python3
import hashlib
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
migration_base = os.environ.get("MIGRATION_BASE", "20260428_186001_inventory_negative_stock_policy").strip()

report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "18_6_negative_stock_policy_standard.md"
report_file = report_dir / "18_6_negative_stock_policy_report.md"
inventory_file = report_dir / "18_6_negative_stock_policy_inventory.tsv"
matrix_file = report_dir / "18_6_negative_stock_policy_matrix.tsv"

up_file = migration_dir / f"{migration_base}.up.sql"
down_file = migration_dir / f"{migration_base}.down.sql"

prev_14 = report_dir / "14_migration_lifecycle_import_final_closure_report.md"
prev_15 = report_dir / "15_readmodel_reporting_final_closure_report.md"
prev_18_1 = report_dir / "18_1_opening_stock_report.md"
prev_18_2 = report_dir / "18_2_stock_movement_engine_report.md"
prev_18_3 = report_dir / "18_3_sales_stock_decrement_report.md"
prev_18_4 = report_dir / "18_4_purchase_stock_increment_report.md"
prev_18_5 = report_dir / "18_5_stock_reservation_report.md"

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
detail("NEGATIVE_STOCK_POLICY_EXECUTED=NO")
detail("STOCK_MOVEMENT_EXECUTED=NO")
detail("STOCK_BALANCE_MUTATION=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=NEGATIVE_STOCK_POLICY_MIGRATION_PAIR_ONLY")

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
prev_18_5_status = get_value(prev_18_5, "FAZ4B_18_5_FINAL_STATUS")
prev_18_5_reservation = get_value(prev_18_5, "STOCK_RESERVATION")
prev_18_5_apply = get_value(prev_18_5, "DB_APPLY_EXECUTED")
prev_18_5_executed = get_value(prev_18_5, "STOCK_RESERVATION_EXECUTED")

detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_15_FINAL_STATUS={prev_15_status}")
detail(f"PREVIOUS_18_1_FINAL_STATUS={prev_18_1_status}")
detail(f"PREVIOUS_18_2_FINAL_STATUS={prev_18_2_status}")
detail(f"PREVIOUS_18_3_FINAL_STATUS={prev_18_3_status}")
detail(f"PREVIOUS_18_4_FINAL_STATUS={prev_18_4_status}")
detail(f"PREVIOUS_18_5_FINAL_STATUS={prev_18_5_status}")
detail(f"PREVIOUS_18_5_STOCK_RESERVATION={prev_18_5_reservation}")
detail(f"PREVIOUS_18_5_DB_APPLY_EXECUTED={prev_18_5_apply}")
detail(f"PREVIOUS_18_5_STOCK_RESERVATION_EXECUTED={prev_18_5_executed}")

for ok, msg in [
    (prev_14_status == "PASS", "14 final status PASS degil"),
    (prev_15_status == "PASS", "15 final status PASS degil"),
    (prev_18_1_status == "PASS", "18.1 final status PASS degil"),
    (prev_18_2_status == "PASS", "18.2 final status PASS degil"),
    (prev_18_3_status == "PASS", "18.3 final status PASS degil"),
    (prev_18_4_status == "PASS", "18.4 final status PASS degil"),
    (prev_18_5_status == "PASS", "18.5 final status PASS degil"),
    (prev_18_5_reservation == "PASS", "18.5 stock reservation PASS degil"),
    (prev_18_5_apply == "NO", "18.5 DB apply NO degil"),
    (prev_18_5_executed == "NO", "18.5 stock reservation executed NO degil"),
]:
    if not ok:
        fail(msg)

if not standard_file.exists():
    fail("18.6 standard doc yok")
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
    "negative_stock_policy_profiles",
    "negative_stock_policy_rules",
    "negative_stock_policy_exceptions",
    "negative_stock_policy_evaluations",
    "negative_stock_policy_decisions",
    "negative_stock_policy_validation_errors",
]

missing_tables = [t for t in expected_tables if t not in unique_tables]

create_schema_count = count(r"CREATE\s+SCHEMA\s+IF\s+NOT\s+EXISTS\s+inventory", up_text)
create_table_count = len(unique_tables)
tenant_id_column_count = count(r"\btenant_id\s+text\s+NOT\s+NULL\b", up_text)
policy_code_count = count(r"\bpolicy_code\s+text", up_text)
policy_mode_count = count(r"\bpolicy_mode\s+text\s+NOT\s+NULL", up_text)
decision_action_count = count(r"\bdecision_action\s+text\s+NOT\s+NULL", up_text)
allow_negative_count = count(r"\ballow_negative_stock\s+boolean\s+NOT\s+NULL", up_text)
product_code_count = count(r"\bproduct_code\s+text", up_text)
location_code_count = count(r"\blocation_code\s+text", up_text)
available_quantity_count = count(r"\bavailable_quantity\s+numeric\(18,4\)\s+NOT\s+NULL", up_text)
negative_quantity_count = count(r"\bnegative_quantity\s+numeric\(18,4\)\s+NOT\s+NULL", up_text)
max_negative_count = count(r"\bmax_negative_quantity\s+numeric\(18,4\)\s+NOT\s+NULL", up_text)
requested_quantity_count = count(r"\brequested_quantity\s+numeric\(18,4\)\s+NOT\s+NULL", up_text)
stock_movement_ref_count = count(r"\bstock_movement_(id|line_id)\s+text", up_text)
approval_required_count = count(r"\bapproval_required\s+boolean\s+NOT\s+NULL", up_text)
idempotency_key_count = count(r"\bidempotency_key\s+text\s+NOT\s+NULL\b", up_text)
status_code_count = count(r"\bstatus_code\s+text\s+NOT\s+NULL", up_text)
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
detail(f"NEGATIVE_STOCK_POLICY_TABLE_COUNT={create_table_count}")
detail(f"NEGATIVE_STOCK_POLICY_EXPECTED_TABLE_MISSING_COUNT={len(missing_tables)}")
detail(f"NEGATIVE_STOCK_POLICY_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
detail(f"NEGATIVE_STOCK_POLICY_POLICY_CODE_COUNT={policy_code_count}")
detail(f"NEGATIVE_STOCK_POLICY_POLICY_MODE_COUNT={policy_mode_count}")
detail(f"NEGATIVE_STOCK_POLICY_DECISION_ACTION_COUNT={decision_action_count}")
detail(f"NEGATIVE_STOCK_POLICY_ALLOW_NEGATIVE_COUNT={allow_negative_count}")
detail(f"NEGATIVE_STOCK_POLICY_PRODUCT_CODE_COLUMN_COUNT={product_code_count}")
detail(f"NEGATIVE_STOCK_POLICY_LOCATION_CODE_COLUMN_COUNT={location_code_count}")
detail(f"NEGATIVE_STOCK_POLICY_AVAILABLE_QUANTITY_COUNT={available_quantity_count}")
detail(f"NEGATIVE_STOCK_POLICY_NEGATIVE_QUANTITY_COUNT={negative_quantity_count}")
detail(f"NEGATIVE_STOCK_POLICY_MAX_NEGATIVE_QUANTITY_COUNT={max_negative_count}")
detail(f"NEGATIVE_STOCK_POLICY_REQUESTED_QUANTITY_COUNT={requested_quantity_count}")
detail(f"NEGATIVE_STOCK_POLICY_STOCK_MOVEMENT_REF_COUNT={stock_movement_ref_count}")
detail(f"NEGATIVE_STOCK_POLICY_APPROVAL_REQUIRED_COUNT={approval_required_count}")
detail(f"NEGATIVE_STOCK_POLICY_IDEMPOTENCY_KEY_COUNT={idempotency_key_count}")
detail(f"NEGATIVE_STOCK_POLICY_STATUS_CODE_COLUMN_COUNT={status_code_count}")
detail(f"NEGATIVE_STOCK_POLICY_UNIQUE_CONSTRAINT_COUNT={unique_constraint_count}")
detail(f"NEGATIVE_STOCK_POLICY_INDEX_COUNT={create_index_count}")
detail(f"NEGATIVE_STOCK_POLICY_DOWN_DROP_TABLE_COUNT={drop_table_count}")

for key, value in forbidden_up_tokens.items():
    detail(f"{key.upper()}={value}")

if create_schema_count != 1:
    fail("inventory create schema count 1 degil")
if create_table_count != len(expected_tables):
    fail("expected negative stock policy table count 6 degil")
if missing_tables:
    fail("expected negative stock policy table eksik: " + ",".join(missing_tables))
if tenant_id_column_count != len(expected_tables):
    fail("tenant_id not null column count 6 degil")
if policy_code_count < 3:
    fail("policy_code count 3 altinda")
if policy_mode_count < 4:
    fail("policy_mode count 4 altinda")
if decision_action_count < 4:
    fail("decision_action count 4 altinda")
if allow_negative_count < 4:
    fail("allow_negative_stock count 4 altinda")
if product_code_count < 4:
    fail("product_code count 4 altinda")
if location_code_count < 4:
    fail("location_code count 4 altinda")
if available_quantity_count < 2:
    fail("available_quantity count 2 altinda")
if negative_quantity_count < 2:
    fail("negative_quantity count 2 altinda")
if max_negative_count < 2:
    fail("max_negative_quantity count 2 altinda")
if requested_quantity_count < 2:
    fail("requested_quantity count 2 altinda")
if stock_movement_ref_count < 2:
    fail("stock movement reference count 2 altinda")
if approval_required_count < 2:
    fail("approval_required count 2 altinda")
if idempotency_key_count < 2:
    fail("idempotency_key count 2 altinda")
if status_code_count < 4:
    fail("status_code count 4 altinda")
if unique_constraint_count < 8:
    fail("unique constraint count 8 altinda")
if create_index_count < 12:
    fail("create index count 12 altinda")
if drop_table_count != len(expected_tables):
    fail("down migration drop table count 6 degil")
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
table_status = "PASS" if create_table_count == 6 and not missing_tables else "FAIL"
tenant_status = "PASS" if tenant_id_column_count == 6 else "FAIL"
policy_mode_status = "PASS" if policy_mode_count >= 4 and decision_action_count >= 4 and allow_negative_count >= 4 else "FAIL"
scope_status = "PASS" if product_code_count >= 4 and location_code_count >= 4 else "FAIL"
quantity_status = "PASS" if available_quantity_count >= 2 and negative_quantity_count >= 2 and max_negative_count >= 2 and requested_quantity_count >= 2 else "FAIL"
movement_ref_status = "PASS" if stock_movement_ref_count >= 2 else "FAIL"
approval_status = "PASS" if approval_required_count >= 2 else "FAIL"
idempotency_status = "PASS" if idempotency_key_count >= 2 else "FAIL"
index_status = "PASS" if create_index_count >= 12 else "FAIL"
down_status = "PASS" if drop_table_count == 6 else "FAIL"
risk_status = "PASS" if not any(forbidden_up_tokens.values()) else "FAIL"
chain_status = "PASS" if chain["invalid_count"] == 0 and chain["missing_pair_count"] == 0 and chain["duplicate_pair_count"] == 0 else "FAIL"

detail(f"NEGATIVE_STOCK_POLICY_MIGRATION_PAIR={pair_status}")
detail(f"NEGATIVE_STOCK_POLICY_SCHEMA_STATUS={schema_status}")
detail(f"NEGATIVE_STOCK_POLICY_TABLE_STATUS={table_status}")
detail(f"NEGATIVE_STOCK_POLICY_TENANT_SAFETY_STATUS={tenant_status}")
detail(f"NEGATIVE_STOCK_POLICY_MODE_STATUS={policy_mode_status}")
detail(f"NEGATIVE_STOCK_POLICY_SCOPE_STATUS={scope_status}")
detail(f"NEGATIVE_STOCK_POLICY_QUANTITY_STATUS={quantity_status}")
detail(f"NEGATIVE_STOCK_POLICY_MOVEMENT_REF_STATUS={movement_ref_status}")
detail(f"NEGATIVE_STOCK_POLICY_APPROVAL_STATUS={approval_status}")
detail(f"NEGATIVE_STOCK_POLICY_IDEMPOTENCY_STATUS={idempotency_status}")
detail(f"NEGATIVE_STOCK_POLICY_INDEX_STATUS={index_status}")
detail(f"NEGATIVE_STOCK_POLICY_DOWN_STATUS={down_status}")
detail(f"NEGATIVE_STOCK_POLICY_RISK_STATUS={risk_status}")
detail(f"NEGATIVE_STOCK_POLICY_CHAIN_STATUS={chain_status}")

for name, status in [
    ("migration_pair", pair_status),
    ("schema", schema_status),
    ("table", table_status),
    ("tenant_safety", tenant_status),
    ("policy_mode", policy_mode_status),
    ("scope", scope_status),
    ("quantity", quantity_status),
    ("movement_ref", movement_ref_status),
    ("approval", approval_status),
    ("idempotency", idempotency_status),
    ("index", index_status),
    ("down", down_status),
    ("risk", risk_status),
    ("chain", chain_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

inventory_lines = ["table\tstatus\ttenant_id_required\tpurpose\tnote"]
purpose = {
    "negative_stock_policy_profiles": "policy_profile_header",
    "negative_stock_policy_rules": "product_location_policy_rules",
    "negative_stock_policy_exceptions": "approved_policy_exceptions",
    "negative_stock_policy_evaluations": "runtime_evaluation_evidence",
    "negative_stock_policy_decisions": "policy_decision_evidence",
    "negative_stock_policy_validation_errors": "policy_validation",
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
    f"previous_18_5\t{prev_18_5_status}\tstock reservation prerequisite",
    f"migration_pair\t{pair_status}\tup/down files exist",
    f"schema\t{schema_status}\tcreate_schema_count={create_schema_count}",
    f"tables\t{table_status}\ttable_count={create_table_count}",
    f"tenant_safety\t{tenant_status}\ttenant_id={tenant_id_column_count}",
    f"policy_mode\t{policy_mode_status}\tpolicy_mode={policy_mode_count} decision_action={decision_action_count} allow_negative={allow_negative_count}",
    f"scope\t{scope_status}\tproduct={product_code_count} location={location_code_count}",
    f"quantity\t{quantity_status}\tavailable={available_quantity_count} negative={negative_quantity_count} max_negative={max_negative_count}",
    f"movement_ref\t{movement_ref_status}\tstock_movement_ref={stock_movement_ref_count}",
    f"approval\t{approval_status}\tapproval_required={approval_required_count}",
    f"idempotency\t{idempotency_status}\tidempotency_key={idempotency_key_count}",
    f"indexes\t{index_status}\tindex_count={create_index_count}",
    f"down_migration\t{down_status}\tdrop_table_count={drop_table_count}",
    f"risk\t{risk_status}\tno destructive/system token in up",
    f"current_migration_chain\t{chain_status}\tpairs={chain['pair_count']}",
    "db_mutation\tNO\tmigration pair only",
    "db_apply_executed\tNO\tapply gate is later",
    "negative_stock_policy_executed\tNO\truntime later",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"NEGATIVE_STOCK_POLICY_INVENTORY_LINE_COUNT={len(inventory_lines)}")
detail(f"NEGATIVE_STOCK_POLICY_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"NEGATIVE_STOCK_POLICY={final_status}")
detail(f"FAZ4B_18_6_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 18.6 - Negative Stock Policy Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"NEGATIVE_STOCK_POLICY={final_status}",
    f"FAZ4B_18_6_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/18_6_negative_stock_policy_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/18_6_negative_stock_policy_matrix.tsv",
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
    "NEGATIVE_STOCK_POLICY_EXECUTED=NO",
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
print(f"NEGATIVE_STOCK_POLICY_TABLE_COUNT={create_table_count}")
print(f"NEGATIVE_STOCK_POLICY_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
print(f"NEGATIVE_STOCK_POLICY_INDEX_COUNT={create_index_count}")
print(f"NEGATIVE_STOCK_POLICY_MIGRATION_PAIR={pair_status}")
print(f"NEGATIVE_STOCK_POLICY_TABLE_STATUS={table_status}")
print(f"NEGATIVE_STOCK_POLICY_TENANT_SAFETY_STATUS={tenant_status}")
print(f"NEGATIVE_STOCK_POLICY_MODE_STATUS={policy_mode_status}")
print(f"NEGATIVE_STOCK_POLICY_QUANTITY_STATUS={quantity_status}")
print(f"NEGATIVE_STOCK_POLICY_CHAIN_STATUS={chain_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("NEGATIVE_STOCK_POLICY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"NEGATIVE_STOCK_POLICY={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
