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

standard_file = report_dir / "14_7_migration_lifecycle_import_tests_standard.md"
report_file = report_dir / "14_7_migration_lifecycle_import_tests_report.md"
matrix_file = report_dir / "14_7_migration_lifecycle_import_tests_matrix.tsv"
inventory_file = report_dir / "14_7_migration_lifecycle_import_tests_inventory.tsv"
closure_file = report_dir / "14_migration_lifecycle_import_final_closure_report.md"

reports = {
    "14.1": report_dir / "14_1_pilot_migration_chain_report.md",
    "14.2": report_dir / "14_2_reference_seed_report.md",
    "14.3": report_dir / "14_3_import_staging_tables_report.md",
    "14.4": report_dir / "14_4_backfill_rebuild_report.md",
    "14.5": report_dir / "14_5_archive_partition_retention_report.md",
    "14.6": report_dir / "14_6_backup_restore_verification_report.md",
}

artifacts = {
    "14.2_seed_manifest": root / "config/reference-data/seed_manifest.tsv",
    "14.3_import_up": root / "db/migrations/20260428_143001_import_staging_tables.up.sql",
    "14.3_import_down": root / "db/migrations/20260428_143001_import_staging_tables.down.sql",
    "14.4_backfill_manifest": root / "config/backfill/backfill_rebuild_manifest.tsv",
    "14.4_backfill_plan": report_dir / "14_4_backfill_rebuild_candidate_execution.sh",
    "14.5_retention_manifest": root / "config/retention/archive_partition_retention_manifest.tsv",
    "14.5_retention_plan": report_dir / "14_5_archive_partition_retention_candidate_execution.sh",
    "14.6_backup_manifest": root / "config/backup/backup_restore_verification_manifest.tsv",
    "14.6_backup_plan": report_dir / "14_6_backup_restore_candidate_execution.sh",
}

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

def count_pattern(path, pattern, flags=re.IGNORECASE | re.MULTILINE):
    if not path.exists():
        return 0
    return len(re.findall(pattern, path.read_text(errors="ignore"), flags))

def run_plan(path, env_key):
    if not path.exists():
        return "FAIL", ""
    try:
        proc = subprocess.run(
            ["bash", str(path)],
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=8,
            env={**os.environ, env_key: "0"},
        )
        output = proc.stdout
        if proc.returncode == 0 and "PLAN_READY_APPLY_NOT_EXECUTED" in output:
            return "PASS", output
        return "FAIL", output
    except Exception as exc:
        return "FAIL", str(exc)

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("SEED_APPLY_EXECUTED=NO")
detail("IMPORT_APPLY_EXECUTED=NO")
detail("BACKFILL_APPLY_EXECUTED=NO")
detail("REBUILD_APPLY_EXECUTED=NO")
detail("ARCHIVE_APPLY_EXECUTED=NO")
detail("PARTITION_APPLY_EXECUTED=NO")
detail("RETENTION_PURGE_EXECUTED=NO")
detail("BACKUP_EXECUTED=NO")
detail("RESTORE_EXECUTED=NO")
detail("PITR_APPLY_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=FINAL_EVIDENCE_TEST_ONLY")

tool_status("python3")
tool_status("bash")
tool_status("grep")
tool_status("wc")

if not standard_file.exists():
    fail("14.7 standard doc yok")

# 14.1 checks
s14_1 = get_value(reports["14.1"], "FAZ4B_14_1_FINAL_STATUS")
chain = get_value(reports["14.1"], "MIGRATION_CHAIN_STANDARD")
pairing = get_value(reports["14.1"], "MIGRATION_PAIRING_STATUS")
naming = get_value(reports["14.1"], "MIGRATION_NAMING_STATUS")
dirty = get_value(reports["14.1"], "DB_SCHEMA_MIGRATIONS_DIRTY_STATE")

detail(f"PREVIOUS_14_1_FINAL_STATUS={s14_1}")
detail(f"PREVIOUS_14_1_MIGRATION_CHAIN_STANDARD={chain}")
detail(f"PREVIOUS_14_1_MIGRATION_PAIRING_STATUS={pairing}")
detail(f"PREVIOUS_14_1_MIGRATION_NAMING_STATUS={naming}")
detail(f"PREVIOUS_14_1_DB_SCHEMA_MIGRATIONS_DIRTY_STATE={dirty}")

# 14.2 checks
s14_2 = get_value(reports["14.2"], "FAZ4B_14_2_FINAL_STATUS")
seed = get_value(reports["14.2"], "REFERENCE_SEED_STANDARD")
seed_manifest = get_value(reports["14.2"], "REFERENCE_SEED_MANIFEST_STATUS")
seed_scope = get_value(reports["14.2"], "REFERENCE_SEED_SCOPE_STATUS")
seed_tenant = get_value(reports["14.2"], "REFERENCE_SEED_TENANT_SAFETY_STATUS")

detail(f"PREVIOUS_14_2_FINAL_STATUS={s14_2}")
detail(f"PREVIOUS_14_2_REFERENCE_SEED_STANDARD={seed}")
detail(f"PREVIOUS_14_2_REFERENCE_SEED_MANIFEST_STATUS={seed_manifest}")
detail(f"PREVIOUS_14_2_REFERENCE_SEED_SCOPE_STATUS={seed_scope}")
detail(f"PREVIOUS_14_2_REFERENCE_SEED_TENANT_SAFETY_STATUS={seed_tenant}")

# 14.3 checks
s14_3 = get_value(reports["14.3"], "FAZ4B_14_3_FINAL_STATUS")
import_staging = get_value(reports["14.3"], "IMPORT_STAGING_TABLES")
import_pair = get_value(reports["14.3"], "IMPORT_STAGING_MIGRATION_PAIR")
import_tables = get_value(reports["14.3"], "IMPORT_STAGING_TABLE_COUNT")
import_tenant_cols = get_value(reports["14.3"], "IMPORT_STAGING_TENANT_ID_COLUMN_COUNT")
import_db_apply = get_value(reports["14.3"], "DB_APPLY_EXECUTED")

detail(f"PREVIOUS_14_3_FINAL_STATUS={s14_3}")
detail(f"PREVIOUS_14_3_IMPORT_STAGING_TABLES={import_staging}")
detail(f"PREVIOUS_14_3_IMPORT_STAGING_MIGRATION_PAIR={import_pair}")
detail(f"PREVIOUS_14_3_IMPORT_STAGING_TABLE_COUNT={import_tables}")
detail(f"PREVIOUS_14_3_IMPORT_STAGING_TENANT_ID_COLUMN_COUNT={import_tenant_cols}")
detail(f"PREVIOUS_14_3_DB_APPLY_EXECUTED={import_db_apply}")

# 14.4 checks
s14_4 = get_value(reports["14.4"], "FAZ4B_14_4_FINAL_STATUS")
backfill = get_value(reports["14.4"], "BACKFILL_REBUILD_STANDARD")
backfill_manifest = get_value(reports["14.4"], "BACKFILL_REBUILD_MANIFEST_STATUS")
backfill_candidate = get_value(reports["14.4"], "BACKFILL_REBUILD_CANDIDATE_PLAN_STATUS")
backfill_apply = get_value(reports["14.4"], "BACKFILL_APPLY_EXECUTED")
rebuild_apply = get_value(reports["14.4"], "REBUILD_APPLY_EXECUTED")

detail(f"PREVIOUS_14_4_FINAL_STATUS={s14_4}")
detail(f"PREVIOUS_14_4_BACKFILL_REBUILD_STANDARD={backfill}")
detail(f"PREVIOUS_14_4_BACKFILL_REBUILD_MANIFEST_STATUS={backfill_manifest}")
detail(f"PREVIOUS_14_4_BACKFILL_REBUILD_CANDIDATE_PLAN_STATUS={backfill_candidate}")
detail(f"PREVIOUS_14_4_BACKFILL_APPLY_EXECUTED={backfill_apply}")
detail(f"PREVIOUS_14_4_REBUILD_APPLY_EXECUTED={rebuild_apply}")

# 14.5 checks
s14_5 = get_value(reports["14.5"], "FAZ4B_14_5_FINAL_STATUS")
retention = get_value(reports["14.5"], "ARCHIVE_PARTITION_RETENTION_MODEL")
retention_manifest = get_value(reports["14.5"], "RETENTION_MANIFEST_STATUS")
retention_candidate = get_value(reports["14.5"], "RETENTION_CANDIDATE_PLAN_STATUS")
archive_apply = get_value(reports["14.5"], "ARCHIVE_APPLY_EXECUTED")
partition_apply = get_value(reports["14.5"], "PARTITION_APPLY_EXECUTED")
purge_apply = get_value(reports["14.5"], "RETENTION_PURGE_EXECUTED")

detail(f"PREVIOUS_14_5_FINAL_STATUS={s14_5}")
detail(f"PREVIOUS_14_5_ARCHIVE_PARTITION_RETENTION_MODEL={retention}")
detail(f"PREVIOUS_14_5_RETENTION_MANIFEST_STATUS={retention_manifest}")
detail(f"PREVIOUS_14_5_RETENTION_CANDIDATE_PLAN_STATUS={retention_candidate}")
detail(f"PREVIOUS_14_5_ARCHIVE_APPLY_EXECUTED={archive_apply}")
detail(f"PREVIOUS_14_5_PARTITION_APPLY_EXECUTED={partition_apply}")
detail(f"PREVIOUS_14_5_RETENTION_PURGE_EXECUTED={purge_apply}")

# 14.6 checks
s14_6 = get_value(reports["14.6"], "FAZ4B_14_6_FINAL_STATUS")
backup = get_value(reports["14.6"], "BACKUP_RESTORE_VERIFICATION_SET")
backup_manifest = get_value(reports["14.6"], "BACKUP_RESTORE_MANIFEST_STATUS")
backup_candidate = get_value(reports["14.6"], "BACKUP_RESTORE_CANDIDATE_PLAN_STATUS")
pitr_deferred = get_value(reports["14.6"], "BACKUP_RESTORE_PITR_DEFERRED_STATUS")
backup_exec = get_value(reports["14.6"], "BACKUP_EXECUTED")
restore_exec = get_value(reports["14.6"], "RESTORE_EXECUTED")
pitr_exec = get_value(reports["14.6"], "PITR_APPLY_EXECUTED")

detail(f"PREVIOUS_14_6_FINAL_STATUS={s14_6}")
detail(f"PREVIOUS_14_6_BACKUP_RESTORE_VERIFICATION_SET={backup}")
detail(f"PREVIOUS_14_6_BACKUP_RESTORE_MANIFEST_STATUS={backup_manifest}")
detail(f"PREVIOUS_14_6_BACKUP_RESTORE_CANDIDATE_PLAN_STATUS={backup_candidate}")
detail(f"PREVIOUS_14_6_BACKUP_RESTORE_PITR_DEFERRED_STATUS={pitr_deferred}")
detail(f"PREVIOUS_14_6_BACKUP_EXECUTED={backup_exec}")
detail(f"PREVIOUS_14_6_RESTORE_EXECUTED={restore_exec}")
detail(f"PREVIOUS_14_6_PITR_APPLY_EXECUTED={pitr_exec}")

checks = [
    ("14.1 final", s14_1 == "PASS"),
    ("14.1 chain", chain == "PASS"),
    ("14.1 pairing", pairing == "PASS"),
    ("14.1 naming", naming == "PASS"),
    ("14.2 final", s14_2 == "PASS"),
    ("14.2 seed", seed == "PASS"),
    ("14.2 manifest", seed_manifest == "PASS"),
    ("14.2 tenant safety", seed_tenant == "PASS"),
    ("14.3 final", s14_3 == "PASS"),
    ("14.3 import staging", import_staging == "PASS"),
    ("14.3 migration pair", import_pair == "PASS"),
    ("14.3 no db apply", import_db_apply == "NO"),
    ("14.4 final", s14_4 == "PASS"),
    ("14.4 standard", backfill == "PASS"),
    ("14.4 candidate", backfill_candidate == "PASS"),
    ("14.4 no apply", backfill_apply == "NO" and rebuild_apply == "NO"),
    ("14.5 final", s14_5 == "PASS"),
    ("14.5 retention", retention == "PASS"),
    ("14.5 candidate", retention_candidate == "PASS"),
    ("14.5 no apply", archive_apply == "NO" and partition_apply == "NO" and purge_apply == "NO"),
    ("14.6 final", s14_6 == "PASS"),
    ("14.6 backup restore", backup == "PASS"),
    ("14.6 pitr deferred", pitr_deferred == "PASS"),
    ("14.6 no apply", backup_exec == "NO" and restore_exec == "NO" and pitr_exec == "NO"),
]

for name, ok in checks:
    if not ok:
        fail(f"{name} check PASS degil")

# Artifact existence and row count checks
seed_header, seed_rows = parse_tsv(artifacts["14.2_seed_manifest"])
backfill_header, backfill_rows = parse_tsv(artifacts["14.4_backfill_manifest"])
retention_header, retention_rows = parse_tsv(artifacts["14.5_retention_manifest"])
backup_header, backup_rows = parse_tsv(artifacts["14.6_backup_manifest"])

detail(f"ARTIFACT_14_2_SEED_MANIFEST_EXISTS={'YES' if artifacts['14.2_seed_manifest'].exists() else 'NO'}")
detail(f"ARTIFACT_14_2_SEED_MANIFEST_ROW_COUNT={len(seed_rows)}")
detail(f"ARTIFACT_14_3_IMPORT_UP_EXISTS={'YES' if artifacts['14.3_import_up'].exists() else 'NO'}")
detail(f"ARTIFACT_14_3_IMPORT_DOWN_EXISTS={'YES' if artifacts['14.3_import_down'].exists() else 'NO'}")
detail(f"ARTIFACT_14_4_BACKFILL_MANIFEST_EXISTS={'YES' if artifacts['14.4_backfill_manifest'].exists() else 'NO'}")
detail(f"ARTIFACT_14_4_BACKFILL_MANIFEST_ROW_COUNT={len(backfill_rows)}")
detail(f"ARTIFACT_14_5_RETENTION_MANIFEST_EXISTS={'YES' if artifacts['14.5_retention_manifest'].exists() else 'NO'}")
detail(f"ARTIFACT_14_5_RETENTION_MANIFEST_ROW_COUNT={len(retention_rows)}")
detail(f"ARTIFACT_14_6_BACKUP_MANIFEST_EXISTS={'YES' if artifacts['14.6_backup_manifest'].exists() else 'NO'}")
detail(f"ARTIFACT_14_6_BACKUP_MANIFEST_ROW_COUNT={len(backup_rows)}")

if len(seed_rows) < 12:
    fail("seed manifest row count 12 altinda")
if not artifacts["14.3_import_up"].exists() or not artifacts["14.3_import_down"].exists():
    fail("14.3 import migration pair eksik")
if len(backfill_rows) < 8:
    fail("backfill manifest row count 8 altinda")
if len(retention_rows) < 12:
    fail("retention manifest row count 12 altinda")
if len(backup_rows) < 12:
    fail("backup manifest row count 12 altinda")

# Import migration file structure
import_create_table_count = count_pattern(artifacts["14.3_import_up"], r"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+import_pipeline\.")
import_tenant_count = count_pattern(artifacts["14.3_import_up"], r"\btenant_id\s+text\s+NOT\s+NULL\b")
import_down_drop_count = count_pattern(artifacts["14.3_import_down"], r"DROP\s+TABLE\s+IF\s+EXISTS\s+import_pipeline\.")

detail(f"FINAL_IMPORT_CREATE_TABLE_COUNT={import_create_table_count}")
detail(f"FINAL_IMPORT_TENANT_ID_COLUMN_COUNT={import_tenant_count}")
detail(f"FINAL_IMPORT_DOWN_DROP_TABLE_COUNT={import_down_drop_count}")

if import_create_table_count != 9:
    fail("final import create table count 9 degil")
if import_tenant_count != 9:
    fail("final import tenant_id column count 9 degil")
if import_down_drop_count != 9:
    fail("final import down drop table count 9 degil")

# Candidate plans default blocked
backfill_plan_status, backfill_plan_out = run_plan(artifacts["14.4_backfill_plan"], "APPLY_BACKFILL")
retention_plan_status, retention_plan_out = run_plan(artifacts["14.5_retention_plan"], "APPLY_RETENTION")
backup_plan_status, backup_plan_out = run_plan(artifacts["14.6_backup_plan"], "APPLY_BACKUP_RESTORE")

detail(f"FINAL_BACKFILL_CANDIDATE_PLAN_DEFAULT_STATUS={backfill_plan_status}")
detail(f"FINAL_RETENTION_CANDIDATE_PLAN_DEFAULT_STATUS={retention_plan_status}")
detail(f"FINAL_BACKUP_RESTORE_CANDIDATE_PLAN_DEFAULT_STATUS={backup_plan_status}")

if backfill_plan_status != "PASS":
    fail("backfill candidate plan default blocked PASS degil")
if retention_plan_status != "PASS":
    fail("retention candidate plan default blocked PASS degil")
if backup_plan_status != "PASS":
    fail("backup/restore candidate plan default blocked PASS degil")

# Secret safety scan over 14 docs generated in this set
scan_files = [
    *reports.values(),
    standard_file,
    artifacts["14.2_seed_manifest"],
    artifacts["14.4_backfill_manifest"],
    artifacts["14.5_retention_manifest"],
    artifacts["14.6_backup_manifest"],
]
secret_hits = []
query_hits = []
for path in scan_files:
    if not path.exists():
        continue
    text = path.read_text(errors="ignore")
    if re.search(r"POSTGRES_PASSWORD=.*[A-Za-z0-9]", text):
        secret_hits.append(str(path.relative_to(root)))
    if re.search(r"password=[^* \n]", text, re.IGNORECASE):
        secret_hits.append(str(path.relative_to(root)))
    if re.search(r"Bearer\s+", text):
        secret_hits.append(str(path.relative_to(root)))
    if re.search(r"\bSELECT\s+.*\bFROM\b", text, re.IGNORECASE):
        query_hits.append(str(path.relative_to(root)))

detail(f"FINAL_SECRET_HIT_COUNT={len(secret_hits)}")
detail(f"FINAL_QUERY_TEXT_HIT_COUNT={len(query_hits)}")

if secret_hits:
    fail("secret/token leak bulundu: " + ",".join(secret_hits[:10]))
if query_hits:
    fail("query text leak bulundu: " + ",".join(query_hits[:10]))

migration_chain_test = "PASS" if s14_1 == "PASS" and chain == "PASS" and pairing == "PASS" and naming == "PASS" else "FAIL"
reference_seed_test = "PASS" if s14_2 == "PASS" and seed == "PASS" and len(seed_rows) >= 12 else "FAIL"
import_staging_test = "PASS" if s14_3 == "PASS" and import_staging == "PASS" and import_create_table_count == 9 else "FAIL"
backfill_rebuild_test = "PASS" if s14_4 == "PASS" and backfill == "PASS" and backfill_plan_status == "PASS" else "FAIL"
retention_model_test = "PASS" if s14_5 == "PASS" and retention == "PASS" and retention_plan_status == "PASS" else "FAIL"
backup_restore_test = "PASS" if s14_6 == "PASS" and backup == "PASS" and backup_plan_status == "PASS" and pitr_deferred == "PASS" else "FAIL"
secret_safety_test = "PASS" if not secret_hits and not query_hits else "FAIL"

for label, status in [
    ("migration_chain_test", migration_chain_test),
    ("reference_seed_test", reference_seed_test),
    ("import_staging_test", import_staging_test),
    ("backfill_rebuild_test", backfill_rebuild_test),
    ("retention_model_test", retention_model_test),
    ("backup_restore_test", backup_restore_test),
    ("secret_safety_test", secret_safety_test),
]:
    if status != "PASS":
        fail(f"{label} PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"migration_chain_test\t{migration_chain_test}\t14.1 chain/pairing/naming",
    f"reference_seed_test\t{reference_seed_test}\t14.2 manifest/scope/tenant safety",
    f"import_staging_test\t{import_staging_test}\t14.3 migration pair/table safety",
    f"backfill_rebuild_test\t{backfill_rebuild_test}\t14.4 manifest/candidate plan",
    f"retention_model_test\t{retention_model_test}\t14.5 manifest/candidate plan",
    f"backup_restore_test\t{backup_restore_test}\t14.6 gates/PITR deferred",
    f"secret_safety_test\t{secret_safety_test}\tsecret_hits={len(secret_hits)} query_hits={len(query_hits)}",
    "db_mutation\tNO\tfinal evidence only",
    "db_apply_executed\tNO\tfinal evidence only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = [
    "block\tstatus\treport_file\tprimary_evidence",
    f"14.1\t{s14_1}\tdocs/phase4/14_1_pilot_migration_chain_report.md\tMIGRATION_CHAIN_STANDARD={chain}",
    f"14.2\t{s14_2}\tdocs/phase4/14_2_reference_seed_report.md\tREFERENCE_SEED_STANDARD={seed}",
    f"14.3\t{s14_3}\tdocs/phase4/14_3_import_staging_tables_report.md\tIMPORT_STAGING_TABLES={import_staging}",
    f"14.4\t{s14_4}\tdocs/phase4/14_4_backfill_rebuild_report.md\tBACKFILL_REBUILD_STANDARD={backfill}",
    f"14.5\t{s14_5}\tdocs/phase4/14_5_archive_partition_retention_report.md\tARCHIVE_PARTITION_RETENTION_MODEL={retention}",
    f"14.6\t{s14_6}\tdocs/phase4/14_6_backup_restore_verification_report.md\tBACKUP_RESTORE_VERIFICATION_SET={backup}",
]
inventory_file.write_text("\n".join(inventory_lines) + "\n")

detail(f"MIGRATION_CHAIN_TEST={migration_chain_test}")
detail(f"REFERENCE_SEED_TEST={reference_seed_test}")
detail(f"IMPORT_STAGING_TEST={import_staging_test}")
detail(f"BACKFILL_REBUILD_TEST={backfill_rebuild_test}")
detail(f"RETENTION_MODEL_TEST={retention_model_test}")
detail(f"BACKUP_RESTORE_TEST={backup_restore_test}")
detail(f"SECRET_SAFETY_TEST={secret_safety_test}")
detail(f"FINAL_TEST_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"FINAL_TEST_INVENTORY_LINE_COUNT={len(inventory_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"MIGRATION_LIFECYCLE_IMPORT_TESTS={final_status}")
detail(f"FAZ4B_14_7_FINAL_STATUS={final_status}")
detail(f"FAZ4B_14_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 14.7 - Migration / Lifecycle / Import Testleri Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"MIGRATION_LIFECYCLE_IMPORT_TESTS={final_status}",
    f"FAZ4B_14_7_FINAL_STATUS={final_status}",
    f"FAZ4B_14_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/14_7_migration_lifecycle_import_tests_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/14_7_migration_lifecycle_import_tests_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Candidate Plan Outputs",
    "### 14.4 Backfill Plan",
    "\n".join(backfill_plan_out.splitlines()[:40]) if backfill_plan_out else "backfill candidate output yok",
    "### 14.5 Retention Plan",
    "\n".join(retention_plan_out.splitlines()[:40]) if retention_plan_out else "retention candidate output yok",
    "### 14.6 Backup Restore Plan",
    "\n".join(backup_plan_out.splitlines()[:40]) if backup_plan_out else "backup restore candidate output yok",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "SEED_APPLY_EXECUTED=NO",
    "IMPORT_APPLY_EXECUTED=NO",
    "BACKFILL_APPLY_EXECUTED=NO",
    "REBUILD_APPLY_EXECUTED=NO",
    "ARCHIVE_APPLY_EXECUTED=NO",
    "PARTITION_APPLY_EXECUTED=NO",
    "RETENTION_PURGE_EXECUTED=NO",
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

closure_lines = [
    "# FAZ 4B / 14 - Migration / Lifecycle / Import Final Closure",
    "",
    f"Generated at: {now()}",
    "",
    f"FAZ4B_14_FINAL_STATUS={final_status}",
    f"FAZ4B_14_7_FINAL_STATUS={final_status}",
    f"MIGRATION_LIFECYCLE_IMPORT_TESTS={final_status}",
    "",
    "## Closed Items",
    f"14.1 Migration chain standardı={s14_1}",
    f"14.2 Reference data / seed standardı={s14_2}",
    f"14.3 Import / staging tabloları={s14_3}",
    f"14.4 Backfill / rebuild script standardı={s14_4}",
    f"14.5 Archive / partition / retention modeli={s14_5}",
    f"14.6 Backup / restore verification seti={s14_6}",
    f"14.7 Migration / lifecycle / import testleri={final_status}",
    "",
    "## Final Gates",
    f"MIGRATION_CHAIN_TEST={migration_chain_test}",
    f"REFERENCE_SEED_TEST={reference_seed_test}",
    f"IMPORT_STAGING_TEST={import_staging_test}",
    f"BACKFILL_REBUILD_TEST={backfill_rebuild_test}",
    f"RETENTION_MODEL_TEST={retention_model_test}",
    f"BACKUP_RESTORE_TEST={backup_restore_test}",
    f"SECRET_SAFETY_TEST={secret_safety_test}",
    "",
    "## Deferred",
    "PITR_ACTIVE_APPLY=DEFERRED",
    "PITR_REASON=Bakım penceresinde controlled apply ile etkinleştirilecek",
    "",
    "## Safety",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "QUERY_TEXT_PRINTED=NO",
]
closure_file.write_text("\n".join(closure_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"CLOSURE_FILE={closure_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"MIGRATION_CHAIN_TEST={migration_chain_test}")
print(f"REFERENCE_SEED_TEST={reference_seed_test}")
print(f"IMPORT_STAGING_TEST={import_staging_test}")
print(f"BACKFILL_REBUILD_TEST={backfill_rebuild_test}")
print(f"RETENTION_MODEL_TEST={retention_model_test}")
print(f"BACKUP_RESTORE_TEST={backup_restore_test}")
print(f"SECRET_SAFETY_TEST={secret_safety_test}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"MIGRATION_LIFECYCLE_IMPORT_TESTS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_14_7_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_14_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
