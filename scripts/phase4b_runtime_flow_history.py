#!/usr/bin/env python3
import hashlib
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
migration_base = os.environ.get("MIGRATION_BASE", "20260428_191001_panel_runtime_flow_history").strip()

report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "19_1_runtime_flow_history_standard.md"
report_file = report_dir / "19_1_runtime_flow_history_report.md"
inventory_file = report_dir / "19_1_runtime_flow_history_inventory.tsv"
matrix_file = report_dir / "19_1_runtime_flow_history_matrix.tsv"

up_file = migration_dir / f"{migration_base}.up.sql"
down_file = migration_dir / f"{migration_base}.down.sql"

prev_14 = report_dir / "14_migration_lifecycle_import_final_closure_report.md"
prev_15 = report_dir / "15_readmodel_reporting_final_closure_report.md"
prev_18 = report_dir / "18_inventory_pilot_motor_final_closure_report.md"

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
        r"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+panel_admin\.([a-z0-9_]+)\s*\(",
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
detail("PANEL_RUNTIME_HISTORY_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=RUNTIME_FLOW_HISTORY_MIGRATION_PAIR_ONLY")

tool_status("python3")
tool_status("grep")
tool_status("wc")
tool_status("sha256sum")

prev_14_status = get_value(prev_14, "FAZ4B_14_FINAL_STATUS")
prev_15_status = get_value(prev_15, "FAZ4B_15_FINAL_STATUS")
prev_18_status = get_value(prev_18, "FAZ4B_18_FINAL_STATUS")
prev_18_tests = get_value(prev_18, "INVENTORY_TEST_SET")
prev_18_apply = get_value(prev_18, "DB_APPLY_EXECUTED")

detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_15_FINAL_STATUS={prev_15_status}")
detail(f"PREVIOUS_18_FINAL_STATUS={prev_18_status}")
detail(f"PREVIOUS_18_INVENTORY_TEST_SET={prev_18_tests}")
detail(f"PREVIOUS_18_DB_APPLY_EXECUTED={prev_18_apply}")

for ok, msg in [
    (prev_14_status == "PASS", "14 final status PASS degil"),
    (prev_15_status == "PASS", "15 final status PASS degil"),
    (prev_18_status == "PASS", "18 final status PASS degil"),
    (prev_18_tests == "PASS", "18 inventory test set PASS degil"),
    (prev_18_apply == "NO", "18 DB apply NO degil"),
]:
    if not ok:
        fail(msg)

if not standard_file.exists():
    fail("19.1 standard doc yok")
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
    "runtime_flow_runs",
    "runtime_flow_steps",
    "runtime_flow_events",
    "runtime_flow_snapshots",
    "runtime_flow_error_links",
    "runtime_flow_timeline_views",
]

missing_tables = [t for t in expected_tables if t not in unique_tables]

create_schema_count = count(r"CREATE\s+SCHEMA\s+IF\s+NOT\s+EXISTS\s+panel_admin", up_text)
create_table_count = len(unique_tables)
tenant_id_column_count = count(r"\btenant_id\s+text\s+NOT\s+NULL\b", up_text)
runtime_flow_run_id_count = count(r"\bruntime_flow_run_id\s+text", up_text)
runtime_flow_step_id_count = count(r"\bruntime_flow_step_id\s+text", up_text)
request_id_count = count(r"\brequest_id\s+text", up_text)
correlation_id_count = count(r"\bcorrelation_id\s+text", up_text)
source_event_id_count = count(r"\bsource_event_id\s+text", up_text)
status_code_count = count(r"\bstatus_code\s+text\s+NOT\s+NULL", up_text)
severity_count = count(r"\bseverity\s+text\s+NOT\s+NULL", up_text)
duration_ms_count = count(r"\bduration_ms\s+integer\s+NOT\s+NULL", up_text)
error_code_count = count(r"\berror_code\s+text", up_text)
panel_visibility_count = count(r"\bpanel_visibility\s+text\s+NOT\s+NULL", up_text)
timeline_count = count(r"\btimeline_", up_text)
unique_constraint_count = count(r"\bUNIQUE\s*\(", up_text)
create_index_count = count(r"CREATE\s+INDEX\s+IF\s+NOT\s+EXISTS", up_text)
drop_table_count = count(r"DROP\s+TABLE\s+IF\s+EXISTS\s+panel_admin\.", down_text)

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
detail(f"RUNTIME_FLOW_HISTORY_TABLE_COUNT={create_table_count}")
detail(f"RUNTIME_FLOW_HISTORY_EXPECTED_TABLE_MISSING_COUNT={len(missing_tables)}")
detail(f"RUNTIME_FLOW_HISTORY_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
detail(f"RUNTIME_FLOW_HISTORY_RUN_ID_COUNT={runtime_flow_run_id_count}")
detail(f"RUNTIME_FLOW_HISTORY_STEP_ID_COUNT={runtime_flow_step_id_count}")
detail(f"RUNTIME_FLOW_HISTORY_REQUEST_ID_COUNT={request_id_count}")
detail(f"RUNTIME_FLOW_HISTORY_CORRELATION_ID_COUNT={correlation_id_count}")
detail(f"RUNTIME_FLOW_HISTORY_SOURCE_EVENT_ID_COUNT={source_event_id_count}")
detail(f"RUNTIME_FLOW_HISTORY_STATUS_CODE_COUNT={status_code_count}")
detail(f"RUNTIME_FLOW_HISTORY_SEVERITY_COUNT={severity_count}")
detail(f"RUNTIME_FLOW_HISTORY_DURATION_MS_COUNT={duration_ms_count}")
detail(f"RUNTIME_FLOW_HISTORY_ERROR_CODE_COUNT={error_code_count}")
detail(f"RUNTIME_FLOW_HISTORY_PANEL_VISIBILITY_COUNT={panel_visibility_count}")
detail(f"RUNTIME_FLOW_HISTORY_TIMELINE_COUNT={timeline_count}")
detail(f"RUNTIME_FLOW_HISTORY_UNIQUE_CONSTRAINT_COUNT={unique_constraint_count}")
detail(f"RUNTIME_FLOW_HISTORY_INDEX_COUNT={create_index_count}")
detail(f"RUNTIME_FLOW_HISTORY_DOWN_DROP_TABLE_COUNT={drop_table_count}")

for key, value in forbidden_up_tokens.items():
    detail(f"{key.upper()}={value}")

if create_schema_count != 1:
    fail("panel_admin create schema count 1 degil")
if create_table_count != len(expected_tables):
    fail("expected runtime flow history table count 6 degil")
if missing_tables:
    fail("expected runtime flow history table eksik: " + ",".join(missing_tables))
if tenant_id_column_count != len(expected_tables):
    fail("tenant_id not null column count 6 degil")
if runtime_flow_run_id_count < 6:
    fail("runtime_flow_run_id count 6 altinda")
if runtime_flow_step_id_count < 3:
    fail("runtime_flow_step_id count 3 altinda")
if request_id_count < 5:
    fail("request_id count 5 altinda")
if correlation_id_count < 5:
    fail("correlation_id count 5 altinda")
if source_event_id_count < 3:
    fail("source_event_id count 3 altinda")
if status_code_count < 4:
    fail("status_code count 4 altinda")
if severity_count < 4:
    fail("severity count 4 altinda")
if duration_ms_count < 3:
    fail("duration_ms count 3 altinda")
if error_code_count < 3:
    fail("error_code count 3 altinda")
if panel_visibility_count < 2:
    fail("panel_visibility count 2 altinda")
if timeline_count < 5:
    fail("timeline trace count 5 altinda")
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
trace_status = "PASS" if request_id_count >= 5 and correlation_id_count >= 5 and source_event_id_count >= 3 else "FAIL"
runtime_status = "PASS" if runtime_flow_run_id_count >= 6 and runtime_flow_step_id_count >= 3 and duration_ms_count >= 3 else "FAIL"
error_status = "PASS" if error_code_count >= 3 and severity_count >= 4 else "FAIL"
panel_status = "PASS" if panel_visibility_count >= 2 and timeline_count >= 5 else "FAIL"
index_status = "PASS" if create_index_count >= 12 else "FAIL"
down_status = "PASS" if drop_table_count == 6 else "FAIL"
risk_status = "PASS" if not any(forbidden_up_tokens.values()) else "FAIL"
chain_status = "PASS" if chain["invalid_count"] == 0 and chain["missing_pair_count"] == 0 and chain["duplicate_pair_count"] == 0 else "FAIL"

detail(f"RUNTIME_FLOW_HISTORY_MIGRATION_PAIR={pair_status}")
detail(f"RUNTIME_FLOW_HISTORY_SCHEMA_STATUS={schema_status}")
detail(f"RUNTIME_FLOW_HISTORY_TABLE_STATUS={table_status}")
detail(f"RUNTIME_FLOW_HISTORY_TENANT_SAFETY_STATUS={tenant_status}")
detail(f"RUNTIME_FLOW_HISTORY_TRACE_STATUS={trace_status}")
detail(f"RUNTIME_FLOW_HISTORY_RUNTIME_STATUS={runtime_status}")
detail(f"RUNTIME_FLOW_HISTORY_ERROR_STATUS={error_status}")
detail(f"RUNTIME_FLOW_HISTORY_PANEL_STATUS={panel_status}")
detail(f"RUNTIME_FLOW_HISTORY_INDEX_STATUS={index_status}")
detail(f"RUNTIME_FLOW_HISTORY_DOWN_STATUS={down_status}")
detail(f"RUNTIME_FLOW_HISTORY_RISK_STATUS={risk_status}")
detail(f"RUNTIME_FLOW_HISTORY_CHAIN_STATUS={chain_status}")

for name, status in [
    ("migration_pair", pair_status),
    ("schema", schema_status),
    ("table", table_status),
    ("tenant_safety", tenant_status),
    ("trace", trace_status),
    ("runtime", runtime_status),
    ("error", error_status),
    ("panel", panel_status),
    ("index", index_status),
    ("down", down_status),
    ("risk", risk_status),
    ("chain", chain_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

inventory_lines = ["table\tstatus\ttenant_id_required\tpurpose\tnote"]
purpose = {
    "runtime_flow_runs": "flow_run_header",
    "runtime_flow_steps": "flow_step_history",
    "runtime_flow_events": "flow_event_timeline",
    "runtime_flow_snapshots": "flow_progress_snapshot",
    "runtime_flow_error_links": "flow_error_trace_links",
    "runtime_flow_timeline_views": "panel_timeline_projection",
}
for table in expected_tables:
    table_present = "YES" if table in unique_tables else "NO"
    inventory_lines.append(
        f"{table}\t{table_present}\tYES\t{purpose[table]}\tpanel_admin.{table}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_14\t{prev_14_status}\tmigration lifecycle prerequisite",
    f"previous_15\t{prev_15_status}\treadmodel/reporting prerequisite",
    f"previous_18\t{prev_18_status}\tinventory prerequisite",
    f"migration_pair\t{pair_status}\tup/down files exist",
    f"schema\t{schema_status}\tcreate_schema_count={create_schema_count}",
    f"tables\t{table_status}\ttable_count={create_table_count}",
    f"tenant_safety\t{tenant_status}\ttenant_id={tenant_id_column_count}",
    f"trace\t{trace_status}\trequest={request_id_count} correlation={correlation_id_count} source_event={source_event_id_count}",
    f"runtime\t{runtime_status}\trun_ref={runtime_flow_run_id_count} step_ref={runtime_flow_step_id_count} duration={duration_ms_count}",
    f"error\t{error_status}\terror_code={error_code_count} severity={severity_count}",
    f"panel\t{panel_status}\tvisibility={panel_visibility_count} timeline={timeline_count}",
    f"indexes\t{index_status}\tindex_count={create_index_count}",
    f"down_migration\t{down_status}\tdrop_table_count={drop_table_count}",
    f"risk\t{risk_status}\tno destructive/system token in up",
    f"current_migration_chain\t{chain_status}\tpairs={chain['pair_count']}",
    "db_mutation\tNO\tmigration pair only",
    "db_apply_executed\tNO\tapply gate is later",
    "panel_runtime_history_executed\tNO\truntime later",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"RUNTIME_FLOW_HISTORY_INVENTORY_LINE_COUNT={len(inventory_lines)}")
detail(f"RUNTIME_FLOW_HISTORY_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"RUNTIME_FLOW_HISTORY={final_status}")
detail(f"FAZ4B_19_1_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 19.1 - Runtime Flow History Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"RUNTIME_FLOW_HISTORY={final_status}",
    f"FAZ4B_19_1_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/19_1_runtime_flow_history_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/19_1_runtime_flow_history_matrix.tsv",
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
    "PANEL_RUNTIME_HISTORY_EXECUTED=NO",
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
print(f"RUNTIME_FLOW_HISTORY_TABLE_COUNT={create_table_count}")
print(f"RUNTIME_FLOW_HISTORY_TENANT_ID_COLUMN_COUNT={tenant_id_column_count}")
print(f"RUNTIME_FLOW_HISTORY_INDEX_COUNT={create_index_count}")
print(f"RUNTIME_FLOW_HISTORY_MIGRATION_PAIR={pair_status}")
print(f"RUNTIME_FLOW_HISTORY_TABLE_STATUS={table_status}")
print(f"RUNTIME_FLOW_HISTORY_TENANT_SAFETY_STATUS={tenant_status}")
print(f"RUNTIME_FLOW_HISTORY_TRACE_STATUS={trace_status}")
print(f"RUNTIME_FLOW_HISTORY_PANEL_STATUS={panel_status}")
print(f"RUNTIME_FLOW_HISTORY_CHAIN_STATUS={chain_status}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("PANEL_RUNTIME_HISTORY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"RUNTIME_FLOW_HISTORY={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
