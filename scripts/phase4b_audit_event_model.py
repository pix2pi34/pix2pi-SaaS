#!/usr/bin/env python3
import hashlib
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
migration_base = os.environ.get("MIGRATION_BASE", "20260429_213001_security_audit_event_model").strip()

report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "21_3_audit_event_model_standard.md"
report_file = report_dir / "21_3_audit_event_model_report.md"
inventory_file = report_dir / "21_3_audit_event_model_inventory.tsv"
matrix_file = report_dir / "21_3_audit_event_model_matrix.tsv"

up_file = migration_dir / f"{migration_base}.up.sql"
down_file = migration_dir / f"{migration_base}.down.sql"

prev_21_2 = report_dir / "21_2_permission_guard_report.md"
prev_21_1 = report_dir / "21_1_role_matrix_report.md"
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
detail("AUDIT_LOG_WRITE_EXECUTED=NO")
detail("AUDIT_INTEGRITY_CHAIN_EXECUTED=NO")
detail("PERMISSION_GUARD_EXECUTED=NO")
detail("RBAC_ENFORCEMENT_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=AUDIT_EVENT_MODEL_MIGRATION_PAIR_ONLY")

for tool in ["python3", "grep", "wc", "sha256sum"]:
    tool_status(tool)

prev_21_2_status = get_value(prev_21_2, "FAZ4B_21_2_FINAL_STATUS")
prev_21_2_domain = get_value(prev_21_2, "PERMISSION_GUARD")
prev_21_2_apply = get_value(prev_21_2, "DB_APPLY_EXECUTED")
prev_21_2_audit_write = get_value(prev_21_2, "AUDIT_LOG_WRITE_EXECUTED")
prev_21_1_status = get_value(prev_21_1, "FAZ4B_21_1_FINAL_STATUS")
prev_21_1_domain = get_value(prev_21_1, "ROLE_MATRIX")
prev_19_status = get_value(prev_19, "FAZ4B_19_FINAL_STATUS")

detail(f"PREVIOUS_21_2_FINAL_STATUS={prev_21_2_status}")
detail(f"PREVIOUS_21_2_PERMISSION_GUARD={prev_21_2_domain}")
detail(f"PREVIOUS_21_2_DB_APPLY_EXECUTED={prev_21_2_apply}")
detail(f"PREVIOUS_21_2_AUDIT_LOG_WRITE_EXECUTED={prev_21_2_audit_write}")
detail(f"PREVIOUS_21_1_FINAL_STATUS={prev_21_1_status}")
detail(f"PREVIOUS_21_1_ROLE_MATRIX={prev_21_1_domain}")
detail(f"PREVIOUS_19_FINAL_STATUS={prev_19_status}")

for ok, msg in [
    (prev_21_2_status == "PASS", "21.2 final status PASS degil"),
    (prev_21_2_domain == "PASS", "21.2 permission guard PASS degil"),
    (prev_21_2_apply == "NO", "21.2 DB apply NO degil"),
    (prev_21_2_audit_write == "NO", "21.2 audit log write NO degil"),
    (prev_21_1_status == "PASS", "21.1 final status PASS degil"),
    (prev_21_1_domain == "PASS", "21.1 role matrix PASS degil"),
    (prev_19_status == "PASS", "19 final status PASS degil"),
]:
    if not ok:
        fail(msg)

if not standard_file.exists():
    fail("21.3 standard doc yok")
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
    "audit_event_streams",
    "audit_events",
    "audit_actor_contexts",
    "audit_resource_contexts",
    "audit_decision_contexts",
    "audit_integrity_chain",
]

missing_tables = [t for t in expected_tables if t not in unique_tables]

create_schema_count = count(r"CREATE\s+SCHEMA\s+IF\s+NOT\s+EXISTS\s+platform_security", up_text)
create_table_count = len(unique_tables)
tenant_id_column_count = count(r"\btenant_id\s+text\s+NOT\s+NULL\b", up_text)
audit_event_id_count = count(r"\baudit_event_id\s+text", up_text)
actor_count = count(r"actor_", up_text)
resource_count = count(r"resource_", up_text)
decision_count = count(r"\bdecision\s+text\s+NOT\s+NULL|deny_reason|allow_access", up_text)
deny_reason_count = count(r"deny_reason", up_text)
high_risk_count = count(r"high_risk\s+boolean\s+NOT\s+NULL", up_text)
audit_required_count = count(r"audit_required\s+boolean\s+NOT\s+NULL", up_text)
request_id_count = count(r"\brequest_id\s+text", up_text)
correlation_id_count = count(r"\bcorrelation_id\s+text", up_text)
event_hash_count = count(r"\bevent_hash\s+text", up_text)
previous_event_hash_count = count(r"previous_event_hash", up_text)
chain_hash_count = count(r"chain_hash", up_text)
immutable_count = count(r"immutable|hash_chain|chain_no|verification_status", up_text)
boundary_count = count(r"boundary|cross_tenant|super_admin|support_access", up_text)
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
detail(f"AUDIT_EVENT_MODEL_TABLE_COUNT={create_table_count}")
detail(f"AUDIT_EVENT_MODEL_EXPECTED_TABLE_MISSING_COUNT={len(missing_tables)}")
detail(f"AUDIT_EVENT_MODEL_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
detail(f"AUDIT_EVENT_MODEL_AUDIT_EVENT_ID_COUNT={audit_event_id_count}")
detail(f"AUDIT_EVENT_MODEL_ACTOR_REF_COUNT={actor_count}")
detail(f"AUDIT_EVENT_MODEL_RESOURCE_REF_COUNT={resource_count}")
detail(f"AUDIT_EVENT_MODEL_DECISION_REF_COUNT={decision_count}")
detail(f"AUDIT_EVENT_MODEL_DENY_REASON_COUNT={deny_reason_count}")
detail(f"AUDIT_EVENT_MODEL_HIGH_RISK_COUNT={high_risk_count}")
detail(f"AUDIT_EVENT_MODEL_AUDIT_REQUIRED_COUNT={audit_required_count}")
detail(f"AUDIT_EVENT_MODEL_REQUEST_ID_COUNT={request_id_count}")
detail(f"AUDIT_EVENT_MODEL_CORRELATION_ID_COUNT={correlation_id_count}")
detail(f"AUDIT_EVENT_MODEL_EVENT_HASH_COUNT={event_hash_count}")
detail(f"AUDIT_EVENT_MODEL_PREVIOUS_EVENT_HASH_COUNT={previous_event_hash_count}")
detail(f"AUDIT_EVENT_MODEL_CHAIN_HASH_COUNT={chain_hash_count}")
detail(f"AUDIT_EVENT_MODEL_IMMUTABLE_REF_COUNT={immutable_count}")
detail(f"AUDIT_EVENT_MODEL_BOUNDARY_REF_COUNT={boundary_count}")
detail(f"AUDIT_EVENT_MODEL_UNIQUE_CONSTRAINT_COUNT={unique_constraint_count}")
detail(f"AUDIT_EVENT_MODEL_INDEX_COUNT={create_index_count}")
detail(f"AUDIT_EVENT_MODEL_DOWN_DROP_TABLE_COUNT={drop_table_count}")

for key, value in forbidden_up_tokens.items():
    detail(f"{key.upper()}={value}")

if create_schema_count != 1:
    fail("platform_security create schema count 1 degil")
if create_table_count != len(expected_tables):
    fail("expected audit event table count 6 degil")
if missing_tables:
    fail("expected audit event table eksik: " + ",".join(missing_tables))
if tenant_id_column_count != len(expected_tables):
    fail("tenant_id not null column count 6 degil")
if audit_event_id_count < 6:
    fail("audit_event_id count 6 altinda")
if actor_count < 8:
    fail("actor reference count 8 altinda")
if resource_count < 8:
    fail("resource reference count 8 altinda")
if decision_count < 7:
    fail("decision reference count 7 altinda")
if deny_reason_count < 2:
    fail("deny_reason count 2 altinda")
if high_risk_count < 2:
    fail("high_risk count 2 altinda")
if audit_required_count < 2:
    fail("audit_required count 2 altinda")
if request_id_count < 1:
    fail("request_id count 1 altinda")
if correlation_id_count < 1:
    fail("correlation_id count 1 altinda")
if event_hash_count < 3:
    fail("event_hash count 3 altinda")
if previous_event_hash_count < 2:
    fail("previous_event_hash count 2 altinda")
if chain_hash_count < 2:
    fail("chain_hash count 2 altinda")
if immutable_count < 6:
    fail("immutable/hash chain reference count 6 altinda")
if boundary_count < 5:
    fail("boundary reference count 5 altinda")
if unique_constraint_count < 8:
    fail("unique constraint count 8 altinda")
if create_index_count < 14:
    fail("create index count 14 altinda")
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
actor_status = "PASS" if actor_count >= 8 else "FAIL"
resource_status = "PASS" if resource_count >= 8 else "FAIL"
decision_status = "PASS" if decision_count >= 7 and deny_reason_count >= 2 and high_risk_count >= 2 else "FAIL"
trace_status = "PASS" if request_id_count >= 1 and correlation_id_count >= 1 else "FAIL"
immutable_status = "PASS" if event_hash_count >= 3 and previous_event_hash_count >= 2 and chain_hash_count >= 2 and immutable_count >= 6 else "FAIL"
boundary_status = "PASS" if boundary_count >= 5 else "FAIL"
index_status = "PASS" if create_index_count >= 14 else "FAIL"
down_status = "PASS" if drop_table_count == 6 else "FAIL"
risk_status = "PASS" if not any(forbidden_up_tokens.values()) else "FAIL"
chain_status = "PASS" if chain["invalid_count"] == 0 and chain["missing_pair_count"] == 0 and chain["duplicate_pair_count"] == 0 else "FAIL"

detail(f"AUDIT_EVENT_MODEL_MIGRATION_PAIR={pair_status}")
detail(f"AUDIT_EVENT_MODEL_SCHEMA_STATUS={schema_status}")
detail(f"AUDIT_EVENT_MODEL_TABLE_STATUS={table_status}")
detail(f"AUDIT_EVENT_MODEL_TENANT_SAFETY_STATUS={tenant_status}")
detail(f"AUDIT_EVENT_MODEL_ACTOR_STATUS={actor_status}")
detail(f"AUDIT_EVENT_MODEL_RESOURCE_STATUS={resource_status}")
detail(f"AUDIT_EVENT_MODEL_DECISION_READY={decision_status}")
detail(f"AUDIT_EVENT_MODEL_TRACE_READY={trace_status}")
detail(f"AUDIT_EVENT_MODEL_IMMUTABLE_READY={immutable_status}")
detail(f"AUDIT_EVENT_MODEL_BOUNDARY_READY={boundary_status}")
detail(f"AUDIT_EVENT_MODEL_INDEX_STATUS={index_status}")
detail(f"AUDIT_EVENT_MODEL_DOWN_STATUS={down_status}")
detail(f"AUDIT_EVENT_MODEL_RISK_STATUS={risk_status}")
detail(f"AUDIT_EVENT_MODEL_CHAIN_STATUS={chain_status}")

for name, status in [
    ("migration_pair", pair_status),
    ("schema", schema_status),
    ("table", table_status),
    ("tenant_safety", tenant_status),
    ("actor", actor_status),
    ("resource", resource_status),
    ("decision", decision_status),
    ("trace", trace_status),
    ("immutable", immutable_status),
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
    "audit_event_streams": "audit_stream_catalog",
    "audit_events": "audit_event_header",
    "audit_actor_contexts": "actor_context",
    "audit_resource_contexts": "resource_context",
    "audit_decision_contexts": "permission_decision_context",
    "audit_integrity_chain": "immutable_hash_chain",
}
for table in expected_tables:
    table_present = "YES" if table in unique_tables else "NO"
    inventory_lines.append(
        f"{table}\t{table_present}\tYES\t{purpose[table]}\tplatform_security.{table}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_21_2\t{prev_21_2_status}\tpermission guard prerequisite",
    f"previous_21_1\t{prev_21_1_status}\trole matrix prerequisite",
    f"previous_19\t{prev_19_status}\tpanel/admin prerequisite",
    f"migration_pair\t{pair_status}\tup/down files exist",
    f"schema\t{schema_status}\tcreate_schema_count={create_schema_count}",
    f"tables\t{table_status}\ttable_count={create_table_count}",
    f"tenant_safety\t{tenant_status}\ttenant_id={tenant_id_column_count}",
    f"actor\t{actor_status}\tactor_refs={actor_count}",
    f"resource\t{resource_status}\tresource_refs={resource_count}",
    f"decision\t{decision_status}\tdecision_refs={decision_count} deny_reason={deny_reason_count}",
    f"trace\t{trace_status}\trequest={request_id_count} correlation={correlation_id_count}",
    f"immutable\t{immutable_status}\tevent_hash={event_hash_count} previous_hash={previous_event_hash_count} chain_hash={chain_hash_count}",
    f"boundary\t{boundary_status}\tboundary_refs={boundary_count}",
    f"indexes\t{index_status}\tindex_count={create_index_count}",
    f"down_migration\t{down_status}\tdrop_table_count={drop_table_count}",
    f"risk\t{risk_status}\tno destructive/system token in up",
    f"current_migration_chain\t{chain_status}\tpairs={chain['pair_count']}",
    "db_mutation\tNO\tmigration pair only",
    "db_apply_executed\tNO\tapply gate is later",
    "audit_log_write_executed\tNO\taudit runtime later",
    "permission_guard_executed\tNO\tpermission guard runtime later",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"AUDIT_EVENT_MODEL_INVENTORY_LINE_COUNT={len(inventory_lines)}")
detail(f"AUDIT_EVENT_MODEL_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"AUDIT_EVENT_MODEL={final_status}")
detail(f"FAZ4B_21_3_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 21.3 - Audit Event Model Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"AUDIT_EVENT_MODEL={final_status}",
    f"FAZ4B_21_3_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/21_3_audit_event_model_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/21_3_audit_event_model_matrix.tsv",
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
    "AUDIT_LOG_WRITE_EXECUTED=NO",
    "AUDIT_INTEGRITY_CHAIN_EXECUTED=NO",
    "PERMISSION_GUARD_EXECUTED=NO",
    "RBAC_ENFORCEMENT_EXECUTED=NO",
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
print(f"AUDIT_EVENT_MODEL_TABLE_COUNT={create_table_count}")
print(f"AUDIT_EVENT_MODEL_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
print(f"AUDIT_EVENT_MODEL_INDEX_COUNT={create_index_count}")
print(f"AUDIT_EVENT_MODEL_MIGRATION_PAIR={pair_status}")
print(f"AUDIT_EVENT_MODEL_TABLE_STATUS={table_status}")
print(f"AUDIT_EVENT_MODEL_TENANT_SAFETY_STATUS={tenant_status}")
print(f"AUDIT_EVENT_MODEL_ACTOR_STATUS={actor_status}")
print(f"AUDIT_EVENT_MODEL_RESOURCE_STATUS={resource_status}")
print(f"AUDIT_EVENT_MODEL_DECISION_READY={decision_status}")
print(f"AUDIT_EVENT_MODEL_TRACE_READY={trace_status}")
print(f"AUDIT_EVENT_MODEL_IMMUTABLE_READY={immutable_status}")
print(f"AUDIT_EVENT_MODEL_BOUNDARY_READY={boundary_status}")
print(f"AUDIT_EVENT_MODEL_CHAIN_STATUS={chain_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("AUDIT_LOG_WRITE_EXECUTED=NO")
print("AUDIT_INTEGRITY_CHAIN_EXECUTED=NO")
print("PERMISSION_GUARD_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"AUDIT_EVENT_MODEL={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
