#!/usr/bin/env python3
import hashlib
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
migration_base = os.environ.get("MIGRATION_BASE", "20260429_211001_security_role_matrix").strip()

report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "21_1_role_matrix_standard.md"
report_file = report_dir / "21_1_role_matrix_report.md"
inventory_file = report_dir / "21_1_role_matrix_inventory.tsv"
matrix_file = report_dir / "21_1_role_matrix_matrix.tsv"

up_file = migration_dir / f"{migration_base}.up.sql"
down_file = migration_dir / f"{migration_base}.down.sql"

prev_14 = report_dir / "14_migration_lifecycle_import_final_closure_report.md"
prev_15 = report_dir / "15_readmodel_reporting_final_closure_report.md"
prev_18 = report_dir / "18_inventory_pilot_motor_final_closure_report.md"
prev_19 = report_dir / "19_panel_admin_professionalization_final_closure_report.md"

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
        r"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+platform_security\.([a-z0-9_]+)\s*\(",
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
detail("RBAC_ENFORCEMENT_EXECUTED=NO")
detail("AUDIT_LOG_WRITE_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=ROLE_MATRIX_MIGRATION_PAIR_ONLY")

for tool in ["python3", "grep", "wc", "sha256sum"]:
    tool_status(tool)

prev_14_status = get_value(prev_14, "FAZ4B_14_FINAL_STATUS")
prev_15_status = get_value(prev_15, "FAZ4B_15_FINAL_STATUS")
prev_18_status = get_value(prev_18, "FAZ4B_18_FINAL_STATUS")
prev_19_status = get_value(prev_19, "FAZ4B_19_FINAL_STATUS")
prev_19_panel = get_value(prev_19, "PANEL_ADMIN_FINAL_CLOSURE")
prev_19_apply = get_value(prev_19, "DB_APPLY_EXECUTED")

detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_15_FINAL_STATUS={prev_15_status}")
detail(f"PREVIOUS_18_FINAL_STATUS={prev_18_status}")
detail(f"PREVIOUS_19_FINAL_STATUS={prev_19_status}")
detail(f"PREVIOUS_19_PANEL_ADMIN_FINAL_CLOSURE={prev_19_panel}")
detail(f"PREVIOUS_19_DB_APPLY_EXECUTED={prev_19_apply}")

for ok, msg in [
    (prev_14_status == "PASS", "14 final status PASS degil"),
    (prev_15_status == "PASS", "15 final status PASS degil"),
    (prev_18_status == "PASS", "18 final status PASS degil"),
    (prev_19_status == "PASS", "19 final status PASS degil"),
    (prev_19_panel == "PASS", "19 panel final closure PASS degil"),
    (prev_19_apply == "NO", "19 DB apply NO degil"),
]:
    if not ok:
        fail(msg)

if not standard_file.exists():
    fail("21.1 standard doc yok")
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
    "role_matrix_profiles",
    "role_definitions",
    "permission_definitions",
    "role_permission_matrix",
    "role_scope_rules",
    "role_matrix_validation_errors",
]

missing_tables = [t for t in expected_tables if t not in unique_tables]

create_schema_count = count(r"CREATE\s+SCHEMA\s+IF\s+NOT\s+EXISTS\s+platform_security", up_text)
create_table_count = len(unique_tables)
tenant_id_column_count = count(r"\btenant_id\s+text\s+NOT\s+NULL\b", up_text)
role_code_count = count(r"\brole_code\s+text\s+NOT\s+NULL|\brole_code\s+text", up_text)
permission_code_count = count(r"\bpermission_code\s+text\s+NOT\s+NULL|\bpermission_code\s+text", up_text)
resource_area_count = count(r"\bresource_area\s+text\s+NOT\s+NULL|\bresource_area\s+text", up_text)
action_code_count = count(r"\baction_code\s+text\s+NOT\s+NULL|\baction_code\s+text", up_text)
allow_access_count = count(r"\ballow_access\s+boolean\s+NOT\s+NULL", up_text)
requires_audit_count = count(r"\brequires_audit\s+boolean\s+NOT\s+NULL", up_text)
high_risk_count = count(r"\bhigh_risk\s+boolean\s+NOT\s+NULL", up_text)
support_role_count = count(r"\bis_support_role\s+boolean\s+NOT\s+NULL|support_access|support_role", up_text)
super_admin_boundary_count = count(r"\bsuper_admin_boundary|is_super_admin_boundary", up_text)
cross_tenant_count = count(r"cross_tenant|allow_cross_tenant|can_cross_tenant", up_text)
status_code_count = count(r"\bstatus_code\s+text\s+NOT\s+NULL", up_text)
unique_constraint_count = count(r"\bUNIQUE\s*\(", up_text)
create_index_count = count(r"CREATE\s+INDEX\s+IF\s+NOT\s+EXISTS", up_text)
drop_table_count = count(r"DROP\s+TABLE\s+IF\s+EXISTS\s+platform_security\.", down_text)

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
detail(f"ROLE_MATRIX_TABLE_COUNT={create_table_count}")
detail(f"ROLE_MATRIX_EXPECTED_TABLE_MISSING_COUNT={len(missing_tables)}")
detail(f"ROLE_MATRIX_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
detail(f"ROLE_MATRIX_ROLE_CODE_COUNT={role_code_count}")
detail(f"ROLE_MATRIX_PERMISSION_CODE_COUNT={permission_code_count}")
detail(f"ROLE_MATRIX_RESOURCE_AREA_COUNT={resource_area_count}")
detail(f"ROLE_MATRIX_ACTION_CODE_COUNT={action_code_count}")
detail(f"ROLE_MATRIX_ALLOW_ACCESS_COUNT={allow_access_count}")
detail(f"ROLE_MATRIX_REQUIRES_AUDIT_COUNT={requires_audit_count}")
detail(f"ROLE_MATRIX_HIGH_RISK_COUNT={high_risk_count}")
detail(f"ROLE_MATRIX_SUPPORT_ROLE_COUNT={support_role_count}")
detail(f"ROLE_MATRIX_SUPER_ADMIN_BOUNDARY_COUNT={super_admin_boundary_count}")
detail(f"ROLE_MATRIX_CROSS_TENANT_COUNT={cross_tenant_count}")
detail(f"ROLE_MATRIX_STATUS_CODE_COLUMN_COUNT={status_code_count}")
detail(f"ROLE_MATRIX_UNIQUE_CONSTRAINT_COUNT={unique_constraint_count}")
detail(f"ROLE_MATRIX_INDEX_COUNT={create_index_count}")
detail(f"ROLE_MATRIX_DOWN_DROP_TABLE_COUNT={drop_table_count}")

for key, value in forbidden_up_tokens.items():
    detail(f"{key.upper()}={value}")

if create_schema_count != 1:
    fail("platform_security create schema count 1 degil")
if create_table_count != len(expected_tables):
    fail("expected role matrix table count 6 degil")
if missing_tables:
    fail("expected role matrix table eksik: " + ",".join(missing_tables))
if tenant_id_column_count != len(expected_tables):
    fail("tenant_id not null column count 6 degil")
if role_code_count < 4:
    fail("role_code count 4 altinda")
if permission_code_count < 4:
    fail("permission_code count 4 altinda")
if resource_area_count < 3:
    fail("resource_area count 3 altinda")
if action_code_count < 3:
    fail("action_code count 3 altinda")
if allow_access_count < 1:
    fail("allow_access count 1 altinda")
if requires_audit_count < 3:
    fail("requires_audit count 3 altinda")
if high_risk_count < 2:
    fail("high_risk count 2 altinda")
if support_role_count < 3:
    fail("support role reference count 3 altinda")
if super_admin_boundary_count < 2:
    fail("super admin boundary count 2 altinda")
if cross_tenant_count < 3:
    fail("cross tenant boundary count 3 altinda")
if status_code_count < 5:
    fail("status_code count 5 altinda")
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
role_status = "PASS" if role_code_count >= 4 and permission_code_count >= 4 else "FAIL"
permission_status = "PASS" if resource_area_count >= 3 and action_code_count >= 3 and allow_access_count >= 1 else "FAIL"
audit_status = "PASS" if requires_audit_count >= 3 and high_risk_count >= 2 else "FAIL"
boundary_status = "PASS" if support_role_count >= 3 and super_admin_boundary_count >= 2 and cross_tenant_count >= 3 else "FAIL"
index_status = "PASS" if create_index_count >= 12 else "FAIL"
down_status = "PASS" if drop_table_count == 6 else "FAIL"
risk_status = "PASS" if not any(forbidden_up_tokens.values()) else "FAIL"
chain_status = "PASS" if chain["invalid_count"] == 0 and chain["missing_pair_count"] == 0 and chain["duplicate_pair_count"] == 0 else "FAIL"

detail(f"ROLE_MATRIX_MIGRATION_PAIR={pair_status}")
detail(f"ROLE_MATRIX_SCHEMA_STATUS={schema_status}")
detail(f"ROLE_MATRIX_TABLE_STATUS={table_status}")
detail(f"ROLE_MATRIX_TENANT_SAFETY_STATUS={tenant_status}")
detail(f"ROLE_MATRIX_ROLE_STATUS={role_status}")
detail(f"ROLE_MATRIX_PERMISSION_STATUS={permission_status}")
detail(f"ROLE_MATRIX_AUDIT_READY_STATUS={audit_status}")
detail(f"ROLE_MATRIX_BOUNDARY_STATUS={boundary_status}")
detail(f"ROLE_MATRIX_INDEX_STATUS={index_status}")
detail(f"ROLE_MATRIX_DOWN_STATUS={down_status}")
detail(f"ROLE_MATRIX_RISK_STATUS={risk_status}")
detail(f"ROLE_MATRIX_CHAIN_STATUS={chain_status}")

for name, status in [
    ("migration_pair", pair_status),
    ("schema", schema_status),
    ("table", table_status),
    ("tenant_safety", tenant_status),
    ("role", role_status),
    ("permission", permission_status),
    ("audit_ready", audit_status),
    ("boundary", boundary_status),
    ("index", index_status),
    ("down", down_status),
    ("risk", risk_status),
    ("chain", chain_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

inventory_lines = ["table\tstatus\ttenant_id_required\tpurpose\tnote"]
purpose = {
    "role_matrix_profiles": "role_matrix_profile_header",
    "role_definitions": "tenant_role_catalog",
    "permission_definitions": "permission_catalog",
    "role_permission_matrix": "role_permission_allow_deny_matrix",
    "role_scope_rules": "role_scope_and_boundary_rules",
    "role_matrix_validation_errors": "role_matrix_validation",
}
for table in expected_tables:
    table_present = "YES" if table in unique_tables else "NO"
    inventory_lines.append(
        f"{table}\t{table_present}\tYES\t{purpose[table]}\tplatform_security.{table}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_14\t{prev_14_status}\tmigration lifecycle prerequisite",
    f"previous_15\t{prev_15_status}\treadmodel/reporting prerequisite",
    f"previous_18\t{prev_18_status}\tinventory prerequisite",
    f"previous_19\t{prev_19_status}\tpanel/admin prerequisite",
    f"migration_pair\t{pair_status}\tup/down files exist",
    f"schema\t{schema_status}\tcreate_schema_count={create_schema_count}",
    f"tables\t{table_status}\ttable_count={create_table_count}",
    f"tenant_safety\t{tenant_status}\ttenant_id={tenant_id_column_count}",
    f"role\t{role_status}\trole_code={role_code_count} permission_code={permission_code_count}",
    f"permission\t{permission_status}\tresource_area={resource_area_count} action_code={action_code_count}",
    f"audit_ready\t{audit_status}\trequires_audit={requires_audit_count} high_risk={high_risk_count}",
    f"boundary\t{boundary_status}\tsupport={support_role_count} super_admin={super_admin_boundary_count} cross_tenant={cross_tenant_count}",
    f"indexes\t{index_status}\tindex_count={create_index_count}",
    f"down_migration\t{down_status}\tdrop_table_count={drop_table_count}",
    f"risk\t{risk_status}\tno destructive/system token in up",
    f"current_migration_chain\t{chain_status}\tpairs={chain['pair_count']}",
    "db_mutation\tNO\tmigration pair only",
    "db_apply_executed\tNO\tapply gate is later",
    "rbac_enforcement_executed\tNO\tpermission guard later",
    "audit_log_write_executed\tNO\taudit runtime later",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"ROLE_MATRIX_INVENTORY_LINE_COUNT={len(inventory_lines)}")
detail(f"ROLE_MATRIX_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"ROLE_MATRIX={final_status}")
detail(f"FAZ4B_21_1_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 21.1 - Role Matrix Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"ROLE_MATRIX={final_status}",
    f"FAZ4B_21_1_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/21_1_role_matrix_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/21_1_role_matrix_matrix.tsv",
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
    "RBAC_ENFORCEMENT_EXECUTED=NO",
    "AUDIT_LOG_WRITE_EXECUTED=NO",
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
print(f"ROLE_MATRIX_TABLE_COUNT={create_table_count}")
print(f"ROLE_MATRIX_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
print(f"ROLE_MATRIX_INDEX_COUNT={create_index_count}")
print(f"ROLE_MATRIX_MIGRATION_PAIR={pair_status}")
print(f"ROLE_MATRIX_TABLE_STATUS={table_status}")
print(f"ROLE_MATRIX_TENANT_SAFETY_STATUS={tenant_status}")
print(f"ROLE_MATRIX_ROLE_STATUS={role_status}")
print(f"ROLE_MATRIX_PERMISSION_STATUS={permission_status}")
print(f"ROLE_MATRIX_AUDIT_READY_STATUS={audit_status}")
print(f"ROLE_MATRIX_BOUNDARY_STATUS={boundary_status}")
print(f"ROLE_MATRIX_CHAIN_STATUS={chain_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("RBAC_ENFORCEMENT_EXECUTED=NO")
print("AUDIT_LOG_WRITE_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"ROLE_MATRIX={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
