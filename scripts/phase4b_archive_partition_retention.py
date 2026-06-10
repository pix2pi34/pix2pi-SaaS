#!/usr/bin/env python3
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()

report_dir = root / "docs/phase4"
manifest_file = root / "config/retention/archive_partition_retention_manifest.tsv"
doc_manifest_file = report_dir / "14_5_archive_partition_retention_manifest.tsv"
standard_file = report_dir / "14_5_archive_partition_retention_standard.md"
report_file = report_dir / "14_5_archive_partition_retention_report.md"
matrix_file = report_dir / "14_5_archive_partition_retention_matrix.tsv"
candidate_plan = report_dir / "14_5_archive_partition_retention_candidate_execution.sh"

prev_14_1 = report_dir / "14_1_pilot_migration_chain_report.md"
prev_14_2 = report_dir / "14_2_reference_seed_report.md"
prev_14_3 = report_dir / "14_3_import_staging_tables_report.md"
prev_14_4 = report_dir / "14_4_backfill_rebuild_report.md"

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

def parse_tsv(path):
    if not path.exists():
        return [], []
    lines = [line.rstrip("\n") for line in path.read_text(errors="ignore").splitlines() if line.strip()]
    if not lines:
        return [], []
    header = lines[0].split("\t")
    rows = []
    for line in lines[1:]:
        parts = line.split("\t")
        row = {}
        for idx, col in enumerate(header):
            row[col] = parts[idx] if idx < len(parts) else ""
        rows.append(row)
    return header, rows

def duplicate_values(rows, key):
    seen = set()
    dup = []
    for row in rows:
        value = row.get(key, "")
        if value in seen:
            dup.append(value)
        seen.add(value)
    return dup

def to_int(value):
    try:
        return int(str(value).strip())
    except Exception:
        return None

def run_candidate_plan():
    if not candidate_plan.exists():
        return "FAIL", ""
    try:
        proc = subprocess.run(
            ["bash", str(candidate_plan)],
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=8,
            env={**os.environ, "APPLY_RETENTION": "0"},
        )
        output = proc.stdout
        if (
            proc.returncode == 0
            and "RETENTION_PLAN_BLOCKED_BY_DEFAULT=YES" in output
            and "ARCHIVE_APPLY_EXECUTED=NO" in output
            and "PARTITION_APPLY_EXECUTED=NO" in output
            and "RETENTION_PURGE_EXECUTED=NO" in output
        ):
            return "PASS", output
        return "FAIL", output
    except Exception as exc:
        return "FAIL", str(exc)

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("ARCHIVE_APPLY_EXECUTED=NO")
detail("PARTITION_APPLY_EXECUTED=NO")
detail("RETENTION_PURGE_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=ARCHIVE_PARTITION_RETENTION_STANDARD_ONLY")

tool_status("python3")
tool_status("bash")
tool_status("grep")
tool_status("wc")

prev_14_1_status = get_value(prev_14_1, "FAZ4B_14_1_FINAL_STATUS")
prev_14_1_chain = get_value(prev_14_1, "MIGRATION_CHAIN_STANDARD")
prev_14_2_status = get_value(prev_14_2, "FAZ4B_14_2_FINAL_STATUS")
prev_14_2_seed = get_value(prev_14_2, "REFERENCE_SEED_STANDARD")
prev_14_3_status = get_value(prev_14_3, "FAZ4B_14_3_FINAL_STATUS")
prev_14_3_import = get_value(prev_14_3, "IMPORT_STAGING_TABLES")
prev_14_4_status = get_value(prev_14_4, "FAZ4B_14_4_FINAL_STATUS")
prev_14_4_backfill = get_value(prev_14_4, "BACKFILL_REBUILD_STANDARD")
prev_14_4_apply = get_value(prev_14_4, "BACKFILL_APPLY_EXECUTED")
prev_14_4_rebuild = get_value(prev_14_4, "REBUILD_APPLY_EXECUTED")

detail(f"PREVIOUS_14_1_FINAL_STATUS={prev_14_1_status}")
detail(f"PREVIOUS_14_1_MIGRATION_CHAIN_STANDARD={prev_14_1_chain}")
detail(f"PREVIOUS_14_2_FINAL_STATUS={prev_14_2_status}")
detail(f"PREVIOUS_14_2_REFERENCE_SEED_STANDARD={prev_14_2_seed}")
detail(f"PREVIOUS_14_3_FINAL_STATUS={prev_14_3_status}")
detail(f"PREVIOUS_14_3_IMPORT_STAGING_TABLES={prev_14_3_import}")
detail(f"PREVIOUS_14_4_FINAL_STATUS={prev_14_4_status}")
detail(f"PREVIOUS_14_4_BACKFILL_REBUILD_STANDARD={prev_14_4_backfill}")
detail(f"PREVIOUS_14_4_BACKFILL_APPLY_EXECUTED={prev_14_4_apply}")
detail(f"PREVIOUS_14_4_REBUILD_APPLY_EXECUTED={prev_14_4_rebuild}")

for ok, msg in [
    (prev_14_1_status == "PASS", "14.1 final status PASS degil"),
    (prev_14_1_chain == "PASS", "14.1 migration chain PASS degil"),
    (prev_14_2_status == "PASS", "14.2 final status PASS degil"),
    (prev_14_2_seed == "PASS", "14.2 reference seed PASS degil"),
    (prev_14_3_status == "PASS", "14.3 final status PASS degil"),
    (prev_14_3_import == "PASS", "14.3 import staging PASS degil"),
    (prev_14_4_status == "PASS", "14.4 final status PASS degil"),
    (prev_14_4_backfill == "PASS", "14.4 backfill rebuild standard PASS degil"),
    (prev_14_4_apply == "NO", "14.4 backfill apply NO degil"),
    (prev_14_4_rebuild == "NO", "14.4 rebuild apply NO degil"),
]:
    if not ok:
        fail(msg)

if not standard_file.exists():
    fail("14.5 standard doc yok")

required_cols = [
    "target_key",
    "domain",
    "table_family",
    "data_classification",
    "tenant_scoped",
    "retention_days",
    "archive_after_days",
    "purge_after_days",
    "partition_candidate",
    "partition_strategy",
    "archive_strategy",
    "kvkk_relevance",
    "restore_requirement",
    "legal_hold_supported",
    "delete_request_action",
    "apply_gate_required",
    "note",
]

header, rows = parse_tsv(manifest_file)
doc_header, doc_rows = parse_tsv(doc_manifest_file)

missing_cols = [col for col in required_cols if col not in header]
duplicate_target_keys = duplicate_values(rows, "target_key")

required_targets = [
    "event_store_events",
    "audit_log_events",
    "application_logs",
    "import_batches",
    "import_files",
    "import_staging_rows",
    "import_validation_errors",
    "notification_history",
    "webhook_delivery_history",
    "jobs_queue_history",
    "reporting_marts",
    "readmodel_snapshots",
]

existing_targets = set(row.get("target_key", "") for row in rows)
missing_targets = [target for target in required_targets if target not in existing_targets]

detail(f"RETENTION_MANIFEST_FILE_EXISTS={'YES' if manifest_file.exists() else 'NO'}")
detail(f"RETENTION_DOC_MANIFEST_FILE_EXISTS={'YES' if doc_manifest_file.exists() else 'NO'}")
detail(f"RETENTION_MANIFEST_ROW_COUNT={len(rows)}")
detail(f"RETENTION_DOC_MANIFEST_ROW_COUNT={len(doc_rows)}")
detail(f"RETENTION_MISSING_COLUMN_COUNT={len(missing_cols)}")
detail(f"RETENTION_DUPLICATE_TARGET_KEY_COUNT={len(duplicate_target_keys)}")
detail(f"RETENTION_REQUIRED_TARGET_MISSING_COUNT={len(missing_targets)}")

if missing_cols:
    fail("retention manifest kolonlari eksik: " + ",".join(missing_cols))
if duplicate_target_keys:
    fail("duplicate target_key var: " + ",".join(duplicate_target_keys))
if missing_targets:
    fail("required target eksik: " + ",".join(missing_targets))

bad_numeric = []
bad_order = []
bad_tenant = []
bad_partition = []
bad_archive = []
bad_kvkk = []
bad_legal_hold = []
bad_delete_action = []
bad_apply_gate = []
bad_restore = []

for row in rows:
    target = row.get("target_key", "")
    retention = to_int(row.get("retention_days", ""))
    archive_after = to_int(row.get("archive_after_days", ""))
    purge_after = to_int(row.get("purge_after_days", ""))

    if retention is None or archive_after is None or purge_after is None:
        bad_numeric.append(target)
    else:
        if retention <= 0 or archive_after <= 0 or purge_after <= 0:
            bad_numeric.append(target)
        if not (archive_after <= retention <= purge_after):
            bad_order.append(target)

    if row.get("tenant_scoped", "") != "YES":
        bad_tenant.append(target)

    if row.get("partition_candidate", "") == "YES" and row.get("partition_strategy", "") in ("", "not_required"):
        bad_partition.append(target)

    if not row.get("archive_strategy", ""):
        bad_archive.append(target)

    if row.get("kvkk_relevance", "") == "YES" and not row.get("delete_request_action", ""):
        bad_kvkk.append(target)

    if row.get("legal_hold_supported", "") != "YES":
        bad_legal_hold.append(target)

    if not row.get("delete_request_action", ""):
        bad_delete_action.append(target)

    if row.get("apply_gate_required", "") != "YES":
        bad_apply_gate.append(target)

    if not row.get("restore_requirement", ""):
        bad_restore.append(target)

partition_candidate_count = sum(1 for row in rows if row.get("partition_candidate") == "YES")
kvkk_relevance_count = sum(1 for row in rows if row.get("kvkk_relevance") == "YES")
tenant_scoped_count = sum(1 for row in rows if row.get("tenant_scoped") == "YES")
legal_hold_count = sum(1 for row in rows if row.get("legal_hold_supported") == "YES")
apply_gate_yes_count = sum(1 for row in rows if row.get("apply_gate_required") == "YES")
personal_data_count = sum(1 for row in rows if row.get("data_classification") == "personal_data")
legal_audit_count = sum(1 for row in rows if row.get("data_classification") == "legal_audit")

detail(f"RETENTION_PARTITION_CANDIDATE_COUNT={partition_candidate_count}")
detail(f"RETENTION_KVKK_RELEVANCE_COUNT={kvkk_relevance_count}")
detail(f"RETENTION_TENANT_SCOPED_COUNT={tenant_scoped_count}")
detail(f"RETENTION_LEGAL_HOLD_SUPPORTED_COUNT={legal_hold_count}")
detail(f"RETENTION_APPLY_GATE_YES_COUNT={apply_gate_yes_count}")
detail(f"RETENTION_PERSONAL_DATA_COUNT={personal_data_count}")
detail(f"RETENTION_LEGAL_AUDIT_COUNT={legal_audit_count}")
detail(f"RETENTION_BAD_NUMERIC_COUNT={len(bad_numeric)}")
detail(f"RETENTION_BAD_ORDER_COUNT={len(bad_order)}")
detail(f"RETENTION_BAD_TENANT_COUNT={len(bad_tenant)}")
detail(f"RETENTION_BAD_PARTITION_COUNT={len(bad_partition)}")
detail(f"RETENTION_BAD_ARCHIVE_COUNT={len(bad_archive)}")
detail(f"RETENTION_BAD_KVKK_COUNT={len(bad_kvkk)}")
detail(f"RETENTION_BAD_LEGAL_HOLD_COUNT={len(bad_legal_hold)}")
detail(f"RETENTION_BAD_DELETE_ACTION_COUNT={len(bad_delete_action)}")
detail(f"RETENTION_BAD_APPLY_GATE_COUNT={len(bad_apply_gate)}")
detail(f"RETENTION_BAD_RESTORE_COUNT={len(bad_restore)}")

for label, bad in [
    ("numeric", bad_numeric),
    ("retention_order", bad_order),
    ("tenant", bad_tenant),
    ("partition", bad_partition),
    ("archive", bad_archive),
    ("kvkk", bad_kvkk),
    ("legal_hold", bad_legal_hold),
    ("delete_action", bad_delete_action),
    ("apply_gate", bad_apply_gate),
    ("restore", bad_restore),
]:
    if bad:
        fail(f"{label} ihlali var: " + ",".join(bad))

if partition_candidate_count < 6:
    fail("partition candidate count 6 altinda")
if kvkk_relevance_count < 6:
    fail("KVKK relevance count 6 altinda")
if tenant_scoped_count != len(rows):
    fail("tenant scoped count row count ile esit degil")
if apply_gate_yes_count != len(rows):
    fail("apply gate YES count row count ile esit degil")
if legal_hold_count != len(rows):
    fail("legal hold supported count row count ile esit degil")

plan_text = candidate_plan.read_text(errors="ignore") if candidate_plan.exists() else ""
candidate_plan_status, candidate_output = run_candidate_plan()

candidate_contains_guard = "APPLY_RETENTION" in plan_text
candidate_contains_block = "RETENTION_PLAN_BLOCKED_BY_DEFAULT=YES" in plan_text
candidate_contains_no_apply = (
    "ARCHIVE_APPLY_EXECUTED=NO" in plan_text
    and "PARTITION_APPLY_EXECUTED=NO" in plan_text
    and "RETENTION_PURGE_EXECUTED=NO" in plan_text
)

detail(f"RETENTION_CANDIDATE_PLAN_FILE_EXISTS={'YES' if candidate_plan.exists() else 'NO'}")
detail(f"RETENTION_CANDIDATE_PLAN_GUARD_EXISTS={'YES' if candidate_contains_guard else 'NO'}")
detail(f"RETENTION_CANDIDATE_PLAN_BLOCKED_BY_DEFAULT={'YES' if candidate_contains_block else 'NO'}")
detail(f"RETENTION_CANDIDATE_PLAN_NO_APPLY_MARKERS={'YES' if candidate_contains_no_apply else 'NO'}")
detail(f"RETENTION_CANDIDATE_PLAN_DRY_RUN_STATUS={candidate_plan_status}")

if candidate_plan_status != "PASS":
    fail("candidate execution plan default blocked PASS degil")
if not candidate_contains_guard:
    fail("candidate plan APPLY_RETENTION guard icermiyor")
if not candidate_contains_block:
    fail("candidate plan blocked by default icermiyor")
if not candidate_contains_no_apply:
    fail("candidate plan no apply markers icermiyor")

manifest_status = "PASS" if manifest_file.exists() and not missing_cols and len(rows) >= 12 and not missing_targets else "FAIL"
partition_status = "PASS" if partition_candidate_count >= 6 and not bad_partition else "FAIL"
tenant_status = "PASS" if not bad_tenant and tenant_scoped_count == len(rows) else "FAIL"
kvkk_status = "PASS" if kvkk_relevance_count >= 6 and not bad_kvkk and not bad_delete_action else "FAIL"
legal_hold_status = "PASS" if not bad_legal_hold and legal_hold_count == len(rows) else "FAIL"
retention_order_status = "PASS" if not bad_numeric and not bad_order else "FAIL"
archive_status = "PASS" if not bad_archive else "FAIL"
apply_gate_status = "PASS" if not bad_apply_gate and apply_gate_yes_count == len(rows) else "FAIL"

detail(f"RETENTION_MANIFEST_STATUS={manifest_status}")
detail(f"RETENTION_PARTITION_CANDIDATE_STATUS={partition_status}")
detail(f"RETENTION_TENANT_SAFETY_STATUS={tenant_status}")
detail(f"RETENTION_KVKK_STATUS={kvkk_status}")
detail(f"RETENTION_LEGAL_HOLD_STATUS={legal_hold_status}")
detail(f"RETENTION_ORDER_STATUS={retention_order_status}")
detail(f"RETENTION_ARCHIVE_STATUS={archive_status}")
detail(f"RETENTION_APPLY_GATE_STATUS={apply_gate_status}")
detail(f"RETENTION_CANDIDATE_PLAN_STATUS={candidate_plan_status}")

for name, status in [
    ("manifest", manifest_status),
    ("partition_candidate", partition_status),
    ("tenant_safety", tenant_status),
    ("kvkk", kvkk_status),
    ("legal_hold", legal_hold_status),
    ("retention_order", retention_order_status),
    ("archive", archive_status),
    ("apply_gate", apply_gate_status),
    ("candidate_plan", candidate_plan_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_14_1\t{prev_14_1_status}\tmigration chain prerequisite",
    f"previous_14_2\t{prev_14_2_status}\treference seed prerequisite",
    f"previous_14_3\t{prev_14_3_status}\timport staging prerequisite",
    f"previous_14_4\t{prev_14_4_status}\tbackfill rebuild prerequisite",
    f"manifest\t{manifest_status}\trows={len(rows)}",
    f"required_targets\t{'PASS' if not missing_targets else 'FAIL'}\tmissing={len(missing_targets)}",
    f"partition_candidate\t{partition_status}\tcandidate_count={partition_candidate_count}",
    f"tenant_safety\t{tenant_status}\ttenant_scoped={tenant_scoped_count}",
    f"kvkk\t{kvkk_status}\tkvkk_count={kvkk_relevance_count}",
    f"legal_hold\t{legal_hold_status}\tlegal_hold_count={legal_hold_count}",
    f"retention_order\t{retention_order_status}\tbad_order={len(bad_order)}",
    f"archive_strategy\t{archive_status}\tbad_archive={len(bad_archive)}",
    f"apply_gate\t{apply_gate_status}\tapply_gate_yes={apply_gate_yes_count}",
    f"candidate_plan\t{candidate_plan_status}\tblocked_by_default={'YES' if candidate_contains_block else 'NO'}",
    "db_mutation\tNO\tstandard only",
    "archive_apply_executed\tNO\tstandard only",
    "partition_apply_executed\tNO\tstandard only",
    "retention_purge_executed\tNO\tstandard only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"RETENTION_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"ARCHIVE_PARTITION_RETENTION_MODEL={final_status}")
detail(f"FAZ4B_14_5_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 14.5 - Archive / Partition / Retention Modeli Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"ARCHIVE_PARTITION_RETENTION_MODEL={final_status}",
    f"FAZ4B_14_5_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/14_5_archive_partition_retention_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Manifest",
    "MANIFEST_FILE=config/retention/archive_partition_retention_manifest.tsv",
    manifest_file.read_text(errors="ignore").rstrip(),
    "",
    "## Candidate Execution Plan Output",
    "\n".join(candidate_output.splitlines()[:60]) if candidate_output else "candidate output yok",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "ARCHIVE_APPLY_EXECUTED=NO",
    "PARTITION_APPLY_EXECUTED=NO",
    "RETENTION_PURGE_EXECUTED=NO",
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
print(f"MANIFEST_FILE={manifest_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"CANDIDATE_PLAN={candidate_plan}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"RETENTION_MANIFEST_ROW_COUNT={len(rows)}")
print(f"RETENTION_PARTITION_CANDIDATE_COUNT={partition_candidate_count}")
print(f"RETENTION_KVKK_RELEVANCE_COUNT={kvkk_relevance_count}")
print(f"RETENTION_TENANT_SCOPED_COUNT={tenant_scoped_count}")
print(f"RETENTION_LEGAL_HOLD_SUPPORTED_COUNT={legal_hold_count}")
print(f"RETENTION_MANIFEST_STATUS={manifest_status}")
print(f"RETENTION_PARTITION_CANDIDATE_STATUS={partition_status}")
print(f"RETENTION_TENANT_SAFETY_STATUS={tenant_status}")
print(f"RETENTION_KVKK_STATUS={kvkk_status}")
print(f"RETENTION_LEGAL_HOLD_STATUS={legal_hold_status}")
print(f"RETENTION_CANDIDATE_PLAN_STATUS={candidate_plan_status}")
print("DB_MUTATION=NO")
print("ARCHIVE_APPLY_EXECUTED=NO")
print("PARTITION_APPLY_EXECUTED=NO")
print("RETENTION_PURGE_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"ARCHIVE_PARTITION_RETENTION_MODEL={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
