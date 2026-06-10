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
manifest_file = root / "config/backup/backup_restore_verification_manifest.tsv"
doc_manifest_file = report_dir / "14_6_backup_restore_verification_manifest.tsv"
standard_file = report_dir / "14_6_backup_restore_verification_standard.md"
report_file = report_dir / "14_6_backup_restore_verification_report.md"
matrix_file = report_dir / "14_6_backup_restore_verification_matrix.tsv"
candidate_plan = report_dir / "14_6_backup_restore_candidate_execution.sh"

prev_14_1 = report_dir / "14_1_pilot_migration_chain_report.md"
prev_14_2 = report_dir / "14_2_reference_seed_report.md"
prev_14_3 = report_dir / "14_3_import_staging_tables_report.md"
prev_14_4 = report_dir / "14_4_backfill_rebuild_report.md"
prev_14_5 = report_dir / "14_5_archive_partition_retention_report.md"
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
            env={**os.environ, "APPLY_BACKUP_RESTORE": "0"},
        )
        output = proc.stdout
        if (
            proc.returncode == 0
            and "BACKUP_RESTORE_PLAN_BLOCKED_BY_DEFAULT=YES" in output
            and "BACKUP_EXECUTED=NO" in output
            and "RESTORE_EXECUTED=NO" in output
            and "PITR_APPLY_EXECUTED=NO" in output
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
detail("BACKUP_EXECUTED=NO")
detail("RESTORE_EXECUTED=NO")
detail("PITR_APPLY_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=BACKUP_RESTORE_VERIFICATION_STANDARD_ONLY")

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
prev_14_3_db_apply = get_value(prev_14_3, "DB_APPLY_EXECUTED")
prev_14_4_status = get_value(prev_14_4, "FAZ4B_14_4_FINAL_STATUS")
prev_14_4_backfill = get_value(prev_14_4, "BACKFILL_REBUILD_STANDARD")
prev_14_4_apply = get_value(prev_14_4, "BACKFILL_APPLY_EXECUTED")
prev_14_4_rebuild = get_value(prev_14_4, "REBUILD_APPLY_EXECUTED")
prev_14_5_status = get_value(prev_14_5, "FAZ4B_14_5_FINAL_STATUS")
prev_14_5_retention = get_value(prev_14_5, "ARCHIVE_PARTITION_RETENTION_MODEL")
prev_14_5_archive = get_value(prev_14_5, "ARCHIVE_APPLY_EXECUTED")
prev_14_5_partition = get_value(prev_14_5, "PARTITION_APPLY_EXECUTED")
prev_14_5_purge = get_value(prev_14_5, "RETENTION_PURGE_EXECUTED")

scorecard_status = get_value(db_scorecard, "DB_PRODUCTION_READINESS_SCORECARD")
db_readiness_status = get_value(db_scorecard, "DB_PRODUCTION_READINESS_STATUS")
db_readiness_score = get_value(db_scorecard, "DB_PRODUCTION_READINESS_SCORE")
deferred_count = get_value(db_scorecard, "DEFERRED_ACTION_COUNT")

detail(f"PREVIOUS_14_1_FINAL_STATUS={prev_14_1_status}")
detail(f"PREVIOUS_14_1_MIGRATION_CHAIN_STANDARD={prev_14_1_chain}")
detail(f"PREVIOUS_14_2_FINAL_STATUS={prev_14_2_status}")
detail(f"PREVIOUS_14_2_REFERENCE_SEED_STANDARD={prev_14_2_seed}")
detail(f"PREVIOUS_14_3_FINAL_STATUS={prev_14_3_status}")
detail(f"PREVIOUS_14_3_IMPORT_STAGING_TABLES={prev_14_3_import}")
detail(f"PREVIOUS_14_3_DB_APPLY_EXECUTED={prev_14_3_db_apply}")
detail(f"PREVIOUS_14_4_FINAL_STATUS={prev_14_4_status}")
detail(f"PREVIOUS_14_4_BACKFILL_REBUILD_STANDARD={prev_14_4_backfill}")
detail(f"PREVIOUS_14_4_BACKFILL_APPLY_EXECUTED={prev_14_4_apply}")
detail(f"PREVIOUS_14_4_REBUILD_APPLY_EXECUTED={prev_14_4_rebuild}")
detail(f"PREVIOUS_14_5_FINAL_STATUS={prev_14_5_status}")
detail(f"PREVIOUS_14_5_ARCHIVE_PARTITION_RETENTION_MODEL={prev_14_5_retention}")
detail(f"PREVIOUS_14_5_ARCHIVE_APPLY_EXECUTED={prev_14_5_archive}")
detail(f"PREVIOUS_14_5_PARTITION_APPLY_EXECUTED={prev_14_5_partition}")
detail(f"PREVIOUS_14_5_RETENTION_PURGE_EXECUTED={prev_14_5_purge}")

detail(f"PREVIOUS_DB_SCORECARD_FILE_EXISTS={'YES' if db_scorecard.exists() else 'NO'}")
detail(f"PREVIOUS_DB_PRODUCTION_READINESS_SCORECARD={scorecard_status if scorecard_status else 'UNKNOWN'}")
detail(f"PREVIOUS_DB_PRODUCTION_READINESS_STATUS={db_readiness_status if db_readiness_status else 'UNKNOWN'}")
detail(f"PREVIOUS_DB_PRODUCTION_READINESS_SCORE={db_readiness_score if db_readiness_score else 'UNKNOWN'}")
detail(f"PREVIOUS_DB_DEFERRED_ACTION_COUNT={deferred_count if deferred_count else 'UNKNOWN'}")

for ok, msg in [
    (prev_14_1_status == "PASS", "14.1 final status PASS degil"),
    (prev_14_1_chain == "PASS", "14.1 migration chain PASS degil"),
    (prev_14_2_status == "PASS", "14.2 final status PASS degil"),
    (prev_14_2_seed == "PASS", "14.2 reference seed PASS degil"),
    (prev_14_3_status == "PASS", "14.3 final status PASS degil"),
    (prev_14_3_import == "PASS", "14.3 import staging PASS degil"),
    (prev_14_3_db_apply == "NO", "14.3 DB apply NO degil"),
    (prev_14_4_status == "PASS", "14.4 final status PASS degil"),
    (prev_14_4_backfill == "PASS", "14.4 backfill rebuild standard PASS degil"),
    (prev_14_4_apply == "NO", "14.4 backfill apply NO degil"),
    (prev_14_4_rebuild == "NO", "14.4 rebuild apply NO degil"),
    (prev_14_5_status == "PASS", "14.5 final status PASS degil"),
    (prev_14_5_retention == "PASS", "14.5 retention model PASS degil"),
    (prev_14_5_archive == "NO", "14.5 archive apply NO degil"),
    (prev_14_5_partition == "NO", "14.5 partition apply NO degil"),
    (prev_14_5_purge == "NO", "14.5 retention purge NO degil"),
]:
    if not ok:
        fail(msg)

if db_scorecard.exists() and scorecard_status and scorecard_status != "PASS":
    fail("DB production readiness scorecard PASS degil")
elif not db_scorecard.exists():
    warn("14_5_2 DB production readiness scorecard file bulunamadi; 14.6 kendi manifest kaniti ile ilerliyor")

if not standard_file.exists():
    fail("14.6 standard doc yok")

required_cols = [
    "gate_key",
    "domain",
    "required",
    "current_status",
    "gate_type",
    "mutates_db",
    "evidence_source",
    "apply_gate_required",
    "deferred_allowed",
    "note",
]

header, rows = parse_tsv(manifest_file)
doc_header, doc_rows = parse_tsv(doc_manifest_file)

missing_cols = [col for col in required_cols if col not in header]
duplicate_gate_keys = duplicate_values(rows, "gate_key")

required_gates = [
    "pre_import_backup_gate",
    "pre_import_backup_evidence",
    "post_import_restore_safety",
    "logical_backup_evidence",
    "restore_drill_evidence",
    "pitr_design_ready",
    "pitr_enable_gate_ready",
    "pitr_active_apply",
    "import_staging_backup_alignment",
    "retention_backup_alignment",
    "restore_runbook_safety",
    "secret_safety",
]

existing_gates = set(row.get("gate_key", "") for row in rows)
missing_gates = [gate for gate in required_gates if gate not in existing_gates]

detail(f"BACKUP_RESTORE_MANIFEST_FILE_EXISTS={'YES' if manifest_file.exists() else 'NO'}")
detail(f"BACKUP_RESTORE_DOC_MANIFEST_FILE_EXISTS={'YES' if doc_manifest_file.exists() else 'NO'}")
detail(f"BACKUP_RESTORE_MANIFEST_ROW_COUNT={len(rows)}")
detail(f"BACKUP_RESTORE_DOC_MANIFEST_ROW_COUNT={len(doc_rows)}")
detail(f"BACKUP_RESTORE_MISSING_COLUMN_COUNT={len(missing_cols)}")
detail(f"BACKUP_RESTORE_DUPLICATE_GATE_KEY_COUNT={len(duplicate_gate_keys)}")
detail(f"BACKUP_RESTORE_REQUIRED_GATE_MISSING_COUNT={len(missing_gates)}")

if missing_cols:
    fail("backup/restore manifest kolonlari eksik: " + ",".join(missing_cols))
if duplicate_gate_keys:
    fail("duplicate gate_key var: " + ",".join(duplicate_gate_keys))
if missing_gates:
    fail("required gate eksik: " + ",".join(missing_gates))

bad_required = []
bad_status = []
bad_apply_gate = []
bad_deferred = []
bad_evidence = []
bad_mutation = []

for row in rows:
    gate = row.get("gate_key", "")
    status = row.get("current_status", "")
    deferred_allowed = row.get("deferred_allowed", "")
    mutates_db = row.get("mutates_db", "")

    if row.get("required", "") != "YES":
        bad_required.append(gate)
    if status not in ("PASS", "DEFERRED"):
        bad_status.append(gate)
    if row.get("apply_gate_required", "") != "YES":
        bad_apply_gate.append(gate)
    if not row.get("evidence_source", ""):
        bad_evidence.append(gate)
    if status == "DEFERRED" and deferred_allowed != "YES":
        bad_deferred.append(gate)
    if status == "PASS" and mutates_db != "NO":
        bad_mutation.append(gate)

pass_count = sum(1 for row in rows if row.get("current_status") == "PASS")
deferred_manifest_count = sum(1 for row in rows if row.get("current_status") == "DEFERRED")
apply_gate_yes_count = sum(1 for row in rows if row.get("apply_gate_required") == "YES")
required_yes_count = sum(1 for row in rows if row.get("required") == "YES")

pitr_active = next((row for row in rows if row.get("gate_key") == "pitr_active_apply"), {})
pitr_active_status = pitr_active.get("current_status", "")
pitr_active_deferred_allowed = pitr_active.get("deferred_allowed", "")

detail(f"BACKUP_RESTORE_PASS_GATE_COUNT={pass_count}")
detail(f"BACKUP_RESTORE_DEFERRED_GATE_COUNT={deferred_manifest_count}")
detail(f"BACKUP_RESTORE_APPLY_GATE_YES_COUNT={apply_gate_yes_count}")
detail(f"BACKUP_RESTORE_REQUIRED_YES_COUNT={required_yes_count}")
detail(f"BACKUP_RESTORE_BAD_REQUIRED_COUNT={len(bad_required)}")
detail(f"BACKUP_RESTORE_BAD_STATUS_COUNT={len(bad_status)}")
detail(f"BACKUP_RESTORE_BAD_APPLY_GATE_COUNT={len(bad_apply_gate)}")
detail(f"BACKUP_RESTORE_BAD_DEFERRED_COUNT={len(bad_deferred)}")
detail(f"BACKUP_RESTORE_BAD_EVIDENCE_COUNT={len(bad_evidence)}")
detail(f"BACKUP_RESTORE_BAD_MUTATION_COUNT={len(bad_mutation)}")
detail(f"BACKUP_RESTORE_PITR_ACTIVE_STATUS={pitr_active_status}")
detail(f"BACKUP_RESTORE_PITR_ACTIVE_DEFERRED_ALLOWED={pitr_active_deferred_allowed}")

for label, bad in [
    ("required", bad_required),
    ("status", bad_status),
    ("apply_gate", bad_apply_gate),
    ("deferred", bad_deferred),
    ("evidence", bad_evidence),
    ("mutation", bad_mutation),
]:
    if bad:
        fail(f"{label} ihlali var: " + ",".join(bad))

if len(rows) < 12:
    fail("backup/restore manifest row count 12 altinda")
if pass_count < 11:
    fail("PASS gate count 11 altinda")
if deferred_manifest_count != 1:
    fail("deferred gate count 1 degil")
if apply_gate_yes_count != len(rows):
    fail("apply gate YES count row count ile esit degil")
if required_yes_count != len(rows):
    fail("required YES count row count ile esit degil")
if pitr_active_status != "DEFERRED" or pitr_active_deferred_allowed != "YES":
    fail("PITR active apply DEFERRED ve deferred_allowed YES degil")

plan_text = candidate_plan.read_text(errors="ignore") if candidate_plan.exists() else ""
candidate_plan_status, candidate_output = run_candidate_plan()

candidate_contains_guard = "APPLY_BACKUP_RESTORE" in plan_text
candidate_contains_block = "BACKUP_RESTORE_PLAN_BLOCKED_BY_DEFAULT=YES" in plan_text
candidate_contains_no_apply = (
    "BACKUP_EXECUTED=NO" in plan_text
    and "RESTORE_EXECUTED=NO" in plan_text
    and "PITR_APPLY_EXECUTED=NO" in plan_text
)

detail(f"BACKUP_RESTORE_CANDIDATE_PLAN_FILE_EXISTS={'YES' if candidate_plan.exists() else 'NO'}")
detail(f"BACKUP_RESTORE_CANDIDATE_PLAN_GUARD_EXISTS={'YES' if candidate_contains_guard else 'NO'}")
detail(f"BACKUP_RESTORE_CANDIDATE_PLAN_BLOCKED_BY_DEFAULT={'YES' if candidate_contains_block else 'NO'}")
detail(f"BACKUP_RESTORE_CANDIDATE_PLAN_NO_APPLY_MARKERS={'YES' if candidate_contains_no_apply else 'NO'}")
detail(f"BACKUP_RESTORE_CANDIDATE_PLAN_DRY_RUN_STATUS={candidate_plan_status}")

if candidate_plan_status != "PASS":
    fail("candidate execution plan default blocked PASS degil")
if not candidate_contains_guard:
    fail("candidate plan APPLY_BACKUP_RESTORE guard icermiyor")
if not candidate_contains_block:
    fail("candidate plan blocked by default icermiyor")
if not candidate_contains_no_apply:
    fail("candidate plan no apply markers icermiyor")

manifest_status = "PASS" if manifest_file.exists() and not missing_cols and len(rows) >= 12 and not missing_gates else "FAIL"
pre_import_status = "PASS" if "pre_import_backup_gate" in existing_gates and "pre_import_backup_evidence" in existing_gates else "FAIL"
post_import_status = "PASS" if "post_import_restore_safety" in existing_gates and "restore_drill_evidence" in existing_gates else "FAIL"
pitr_deferred_status = "PASS" if pitr_active_status == "DEFERRED" and pitr_active_deferred_allowed == "YES" else "FAIL"
secret_status = "PASS" if "secret_safety" in existing_gates else "FAIL"

detail(f"BACKUP_RESTORE_MANIFEST_STATUS={manifest_status}")
detail(f"BACKUP_RESTORE_PRE_IMPORT_GATE_STATUS={pre_import_status}")
detail(f"BACKUP_RESTORE_POST_IMPORT_RESTORE_STATUS={post_import_status}")
detail(f"BACKUP_RESTORE_PITR_DEFERRED_STATUS={pitr_deferred_status}")
detail(f"BACKUP_RESTORE_SECRET_STATUS={secret_status}")
detail(f"BACKUP_RESTORE_CANDIDATE_PLAN_STATUS={candidate_plan_status}")

for name, status in [
    ("manifest", manifest_status),
    ("pre_import_gate", pre_import_status),
    ("post_import_restore", post_import_status),
    ("pitr_deferred", pitr_deferred_status),
    ("secret", secret_status),
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
    f"previous_14_5\t{prev_14_5_status}\tretention prerequisite",
    f"manifest\t{manifest_status}\trows={len(rows)}",
    f"required_gates\t{'PASS' if not missing_gates else 'FAIL'}\tmissing={len(missing_gates)}",
    f"pre_import_backup_gate\t{pre_import_status}\tbackup gate exists",
    f"post_import_restore_safety\t{post_import_status}\trestore safety exists",
    f"pitr_deferred\t{pitr_deferred_status}\tpitr_active_apply={pitr_active_status}",
    f"pass_deferred_balance\t{'PASS' if pass_count >= 11 and deferred_manifest_count == 1 else 'FAIL'}\tpass={pass_count} deferred={deferred_manifest_count}",
    f"candidate_plan\t{candidate_plan_status}\tblocked_by_default={'YES' if candidate_contains_block else 'NO'}",
    "db_mutation\tNO\tstandard only",
    "backup_executed\tNO\tstandard only",
    "restore_executed\tNO\tstandard only",
    "pitr_apply_executed\tNO\tstandard only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"BACKUP_RESTORE_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"BACKUP_RESTORE_VERIFICATION_SET={final_status}")
detail(f"FAZ4B_14_6_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 14.6 - Backup / Restore Verification Seti Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"BACKUP_RESTORE_VERIFICATION_SET={final_status}",
    f"FAZ4B_14_6_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/14_6_backup_restore_verification_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Manifest",
    "MANIFEST_FILE=config/backup/backup_restore_verification_manifest.tsv",
    manifest_file.read_text(errors="ignore").rstrip(),
    "",
    "## Candidate Execution Plan Output",
    "\n".join(candidate_output.splitlines()[:60]) if candidate_output else "candidate output yok",
    "",
    "## Deferred Actions",
    "PITR_ACTIVE_APPLY=DEFERRED",
    "PITR_REASON=Bakim penceresinde controlled apply ile etkinlestirilecek",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "BACKUP_EXECUTED=NO",
    "RESTORE_EXECUTED=NO",
    "PITR_APPLY_EXECUTED=NO",
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
print(f"BACKUP_RESTORE_MANIFEST_ROW_COUNT={len(rows)}")
print(f"BACKUP_RESTORE_PASS_GATE_COUNT={pass_count}")
print(f"BACKUP_RESTORE_DEFERRED_GATE_COUNT={deferred_manifest_count}")
print(f"BACKUP_RESTORE_MANIFEST_STATUS={manifest_status}")
print(f"BACKUP_RESTORE_PRE_IMPORT_GATE_STATUS={pre_import_status}")
print(f"BACKUP_RESTORE_POST_IMPORT_RESTORE_STATUS={post_import_status}")
print(f"BACKUP_RESTORE_PITR_DEFERRED_STATUS={pitr_deferred_status}")
print(f"BACKUP_RESTORE_CANDIDATE_PLAN_STATUS={candidate_plan_status}")
print("DB_MUTATION=NO")
print("BACKUP_EXECUTED=NO")
print("RESTORE_EXECUTED=NO")
print("PITR_APPLY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"BACKUP_RESTORE_VERIFICATION_SET={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
