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
manifest_file = root / "config/backfill/backfill_rebuild_manifest.tsv"
doc_manifest_file = report_dir / "14_4_backfill_rebuild_manifest.tsv"
standard_file = report_dir / "14_4_backfill_rebuild_standard.md"
report_file = report_dir / "14_4_backfill_rebuild_report.md"
matrix_file = report_dir / "14_4_backfill_rebuild_matrix.tsv"
candidate_plan = report_dir / "14_4_backfill_rebuild_candidate_execution.sh"

prev_14_1 = report_dir / "14_1_pilot_migration_chain_report.md"
prev_14_2 = report_dir / "14_2_reference_seed_report.md"
prev_14_3 = report_dir / "14_3_import_staging_tables_report.md"

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
            env={**os.environ, "APPLY_BACKFILL": "0"},
        )
        output = proc.stdout
        if proc.returncode == 0 and "BACKFILL_PLAN_BLOCKED_BY_DEFAULT=YES" in output and "BACKFILL_APPLY_EXECUTED=NO" in output:
            return "PASS", output
        return "FAIL", output
    except Exception as exc:
        return "FAIL", str(exc)

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("BACKFILL_APPLY_EXECUTED=NO")
detail("REBUILD_APPLY_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=BACKFILL_REBUILD_STANDARD_ONLY")

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
prev_14_3_pair = get_value(prev_14_3, "IMPORT_STAGING_MIGRATION_PAIR")
prev_14_3_db_apply = get_value(prev_14_3, "DB_APPLY_EXECUTED")

detail(f"PREVIOUS_14_1_FINAL_STATUS={prev_14_1_status}")
detail(f"PREVIOUS_14_1_MIGRATION_CHAIN_STANDARD={prev_14_1_chain}")
detail(f"PREVIOUS_14_2_FINAL_STATUS={prev_14_2_status}")
detail(f"PREVIOUS_14_2_REFERENCE_SEED_STANDARD={prev_14_2_seed}")
detail(f"PREVIOUS_14_3_FINAL_STATUS={prev_14_3_status}")
detail(f"PREVIOUS_14_3_IMPORT_STAGING_TABLES={prev_14_3_import}")
detail(f"PREVIOUS_14_3_IMPORT_STAGING_MIGRATION_PAIR={prev_14_3_pair}")
detail(f"PREVIOUS_14_3_DB_APPLY_EXECUTED={prev_14_3_db_apply}")

for ok, msg in [
    (prev_14_1_status == "PASS", "14.1 final status PASS degil"),
    (prev_14_1_chain == "PASS", "14.1 migration chain PASS degil"),
    (prev_14_2_status == "PASS", "14.2 final status PASS degil"),
    (prev_14_2_seed == "PASS", "14.2 reference seed PASS degil"),
    (prev_14_3_status == "PASS", "14.3 final status PASS degil"),
    (prev_14_3_import == "PASS", "14.3 import staging PASS degil"),
    (prev_14_3_pair == "PASS", "14.3 migration pair PASS degil"),
    (prev_14_3_db_apply == "NO", "14.3 DB apply NO degil"),
]:
    if not ok:
        fail(msg)

if not standard_file.exists():
    fail("14.4 standard doc yok")

required_cols = [
    "job_key",
    "domain",
    "target_type",
    "source_type",
    "scope",
    "tenant_required",
    "dry_run_required",
    "apply_gate_required",
    "cursor_strategy",
    "default_batch_size",
    "max_retry",
    "idempotency_strategy",
    "resume_strategy",
    "failure_policy",
    "mutation_scope",
    "note",
]

header, rows = parse_tsv(manifest_file)
doc_header, doc_rows = parse_tsv(doc_manifest_file)

missing_cols = [col for col in required_cols if col not in header]
duplicate_job_keys = duplicate_values(rows, "job_key")

required_jobs = [
    "readmodel_operational_rebuild",
    "reporting_finance_mart_backfill",
    "reporting_export_mart_backfill",
    "reporting_payment_reconciliation_backfill",
    "inventory_balance_rebuild",
    "search_projection_rebuild",
    "materialized_cache_projection_refresh",
    "import_staging_validation_rebuild",
]

existing_jobs = set(row.get("job_key", "") for row in rows)
missing_jobs = [job for job in required_jobs if job not in existing_jobs]

detail(f"BACKFILL_REBUILD_MANIFEST_FILE_EXISTS={'YES' if manifest_file.exists() else 'NO'}")
detail(f"BACKFILL_REBUILD_DOC_MANIFEST_FILE_EXISTS={'YES' if doc_manifest_file.exists() else 'NO'}")
detail(f"BACKFILL_REBUILD_MANIFEST_ROW_COUNT={len(rows)}")
detail(f"BACKFILL_REBUILD_DOC_MANIFEST_ROW_COUNT={len(doc_rows)}")
detail(f"BACKFILL_REBUILD_MISSING_COLUMN_COUNT={len(missing_cols)}")
detail(f"BACKFILL_REBUILD_DUPLICATE_JOB_KEY_COUNT={len(duplicate_job_keys)}")
detail(f"BACKFILL_REBUILD_REQUIRED_JOB_MISSING_COUNT={len(missing_jobs)}")

if missing_cols:
    fail("manifest kolonlari eksik: " + ",".join(missing_cols))
if duplicate_job_keys:
    fail("duplicate job_key var: " + ",".join(duplicate_job_keys))
if missing_jobs:
    fail("required job eksik: " + ",".join(missing_jobs))

bad_dry_run = []
bad_apply_gate = []
bad_idempotency = []
bad_resume = []
bad_tenant = []
bad_batch = []
bad_retry = []
bad_mutation_scope = []
bad_failure_policy = []
bad_scope = []

allowed_scopes = {"TENANT_SCOPED", "GLOBAL_SAFE"}

for row in rows:
    job = row.get("job_key", "")
    scope = row.get("scope", "")

    if row.get("dry_run_required", "") != "YES":
        bad_dry_run.append(job)
    if row.get("apply_gate_required", "") != "YES":
        bad_apply_gate.append(job)
    if not row.get("idempotency_strategy", ""):
        bad_idempotency.append(job)
    if not row.get("resume_strategy", ""):
        bad_resume.append(job)
    if not row.get("failure_policy", ""):
        bad_failure_policy.append(job)
    if not row.get("mutation_scope", ""):
        bad_mutation_scope.append(job)
    if scope not in allowed_scopes:
        bad_scope.append(job)
    if scope == "TENANT_SCOPED" and row.get("tenant_required", "") != "YES":
        bad_tenant.append(job)

    try:
        batch = int(row.get("default_batch_size", "0"))
        if batch <= 0 or batch > 10000:
            bad_batch.append(job)
    except Exception:
        bad_batch.append(job)

    try:
        retry = int(row.get("max_retry", "0"))
        if retry < 1 or retry > 10:
            bad_retry.append(job)
    except Exception:
        bad_retry.append(job)

tenant_scoped_count = sum(1 for row in rows if row.get("scope") == "TENANT_SCOPED")
global_safe_count = sum(1 for row in rows if row.get("scope") == "GLOBAL_SAFE")
dry_run_yes_count = sum(1 for row in rows if row.get("dry_run_required") == "YES")
apply_gate_yes_count = sum(1 for row in rows if row.get("apply_gate_required") == "YES")

detail(f"BACKFILL_REBUILD_TENANT_SCOPED_COUNT={tenant_scoped_count}")
detail(f"BACKFILL_REBUILD_GLOBAL_SAFE_COUNT={global_safe_count}")
detail(f"BACKFILL_REBUILD_DRY_RUN_YES_COUNT={dry_run_yes_count}")
detail(f"BACKFILL_REBUILD_APPLY_GATE_YES_COUNT={apply_gate_yes_count}")
detail(f"BACKFILL_REBUILD_BAD_DRY_RUN_COUNT={len(bad_dry_run)}")
detail(f"BACKFILL_REBUILD_BAD_APPLY_GATE_COUNT={len(bad_apply_gate)}")
detail(f"BACKFILL_REBUILD_BAD_IDEMPOTENCY_COUNT={len(bad_idempotency)}")
detail(f"BACKFILL_REBUILD_BAD_RESUME_COUNT={len(bad_resume)}")
detail(f"BACKFILL_REBUILD_BAD_TENANT_SAFETY_COUNT={len(bad_tenant)}")
detail(f"BACKFILL_REBUILD_BAD_BATCH_COUNT={len(bad_batch)}")
detail(f"BACKFILL_REBUILD_BAD_RETRY_COUNT={len(bad_retry)}")
detail(f"BACKFILL_REBUILD_BAD_MUTATION_SCOPE_COUNT={len(bad_mutation_scope)}")
detail(f"BACKFILL_REBUILD_BAD_FAILURE_POLICY_COUNT={len(bad_failure_policy)}")
detail(f"BACKFILL_REBUILD_BAD_SCOPE_COUNT={len(bad_scope)}")

for label, bad in [
    ("dry run", bad_dry_run),
    ("apply gate", bad_apply_gate),
    ("idempotency", bad_idempotency),
    ("resume", bad_resume),
    ("tenant safety", bad_tenant),
    ("batch", bad_batch),
    ("retry", bad_retry),
    ("mutation scope", bad_mutation_scope),
    ("failure policy", bad_failure_policy),
    ("scope", bad_scope),
]:
    if bad:
        fail(f"{label} ihlali var: " + ",".join(bad))

plan_text = candidate_plan.read_text(errors="ignore") if candidate_plan.exists() else ""
candidate_plan_status, candidate_output = run_candidate_plan()

candidate_contains_guard = "APPLY_BACKFILL" in plan_text
candidate_contains_block = "BACKFILL_PLAN_BLOCKED_BY_DEFAULT=YES" in plan_text
candidate_contains_no_apply = "BACKFILL_APPLY_EXECUTED=NO" in plan_text and "REBUILD_APPLY_EXECUTED=NO" in plan_text

detail(f"BACKFILL_REBUILD_CANDIDATE_PLAN_FILE_EXISTS={'YES' if candidate_plan.exists() else 'NO'}")
detail(f"BACKFILL_REBUILD_CANDIDATE_PLAN_GUARD_EXISTS={'YES' if candidate_contains_guard else 'NO'}")
detail(f"BACKFILL_REBUILD_CANDIDATE_PLAN_BLOCKED_BY_DEFAULT={'YES' if candidate_contains_block else 'NO'}")
detail(f"BACKFILL_REBUILD_CANDIDATE_PLAN_NO_APPLY_MARKERS={'YES' if candidate_contains_no_apply else 'NO'}")
detail(f"BACKFILL_REBUILD_CANDIDATE_PLAN_DRY_RUN_STATUS={candidate_plan_status}")

if candidate_plan_status != "PASS":
    fail("candidate execution plan default blocked PASS degil")
if not candidate_contains_guard:
    fail("candidate plan APPLY_BACKFILL guard icermiyor")
if not candidate_contains_block:
    fail("candidate plan blocked by default icermiyor")
if not candidate_contains_no_apply:
    fail("candidate plan no apply markers icermiyor")

manifest_status = "PASS" if manifest_file.exists() and not missing_cols and len(rows) >= 8 and not missing_jobs else "FAIL"
dry_run_status = "PASS" if not bad_dry_run else "FAIL"
apply_gate_status = "PASS" if not bad_apply_gate else "FAIL"
idempotency_status = "PASS" if not bad_idempotency else "FAIL"
resume_status = "PASS" if not bad_resume else "FAIL"
tenant_status = "PASS" if not bad_tenant and tenant_scoped_count >= 7 else "FAIL"
batch_status = "PASS" if not bad_batch and not bad_retry else "FAIL"
mutation_scope_status = "PASS" if not bad_mutation_scope else "FAIL"

detail(f"BACKFILL_REBUILD_MANIFEST_STATUS={manifest_status}")
detail(f"BACKFILL_REBUILD_DRY_RUN_STATUS={dry_run_status}")
detail(f"BACKFILL_REBUILD_APPLY_GATE_STATUS={apply_gate_status}")
detail(f"BACKFILL_REBUILD_IDEMPOTENCY_STATUS={idempotency_status}")
detail(f"BACKFILL_REBUILD_RESUME_STATUS={resume_status}")
detail(f"BACKFILL_REBUILD_TENANT_SAFETY_STATUS={tenant_status}")
detail(f"BACKFILL_REBUILD_BATCH_STATUS={batch_status}")
detail(f"BACKFILL_REBUILD_MUTATION_SCOPE_STATUS={mutation_scope_status}")
detail(f"BACKFILL_REBUILD_CANDIDATE_PLAN_STATUS={candidate_plan_status}")

for name, status in [
    ("manifest", manifest_status),
    ("dry_run", dry_run_status),
    ("apply_gate", apply_gate_status),
    ("idempotency", idempotency_status),
    ("resume", resume_status),
    ("tenant_safety", tenant_status),
    ("batch", batch_status),
    ("mutation_scope", mutation_scope_status),
    ("candidate_plan", candidate_plan_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_14_1\t{prev_14_1_status}\tmigration chain prerequisite",
    f"previous_14_2\t{prev_14_2_status}\treference seed prerequisite",
    f"previous_14_3\t{prev_14_3_status}\timport staging prerequisite",
    f"manifest\t{manifest_status}\trows={len(rows)}",
    f"required_jobs\t{'PASS' if not missing_jobs else 'FAIL'}\tmissing={len(missing_jobs)}",
    f"dry_run\t{dry_run_status}\tbad={len(bad_dry_run)}",
    f"apply_gate\t{apply_gate_status}\tbad={len(bad_apply_gate)}",
    f"idempotency\t{idempotency_status}\tbad={len(bad_idempotency)}",
    f"resume_retry\t{resume_status}\tbad_resume={len(bad_resume)} bad_retry={len(bad_retry)}",
    f"tenant_safety\t{tenant_status}\ttenant_scoped={tenant_scoped_count}",
    f"batch_cursor\t{batch_status}\tbad_batch={len(bad_batch)}",
    f"mutation_scope\t{mutation_scope_status}\tbad={len(bad_mutation_scope)}",
    f"candidate_plan\t{candidate_plan_status}\tblocked_by_default={'YES' if candidate_contains_block else 'NO'}",
    "db_mutation\tNO\tstandard only",
    "backfill_apply_executed\tNO\tstandard only",
    "rebuild_apply_executed\tNO\tstandard only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"BACKFILL_REBUILD_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"BACKFILL_REBUILD_STANDARD={final_status}")
detail(f"FAZ4B_14_4_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 14.4 - Backfill / Rebuild Script Standardı Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"BACKFILL_REBUILD_STANDARD={final_status}",
    f"FAZ4B_14_4_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/14_4_backfill_rebuild_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Manifest",
    "MANIFEST_FILE=config/backfill/backfill_rebuild_manifest.tsv",
    manifest_file.read_text(errors="ignore").rstrip(),
    "",
    "## Candidate Execution Plan Output",
    "\n".join(candidate_output.splitlines()[:60]) if candidate_output else "candidate output yok",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "BACKFILL_APPLY_EXECUTED=NO",
    "REBUILD_APPLY_EXECUTED=NO",
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
print(f"BACKFILL_REBUILD_MANIFEST_ROW_COUNT={len(rows)}")
print(f"BACKFILL_REBUILD_TENANT_SCOPED_COUNT={tenant_scoped_count}")
print(f"BACKFILL_REBUILD_DRY_RUN_YES_COUNT={dry_run_yes_count}")
print(f"BACKFILL_REBUILD_APPLY_GATE_YES_COUNT={apply_gate_yes_count}")
print(f"BACKFILL_REBUILD_MANIFEST_STATUS={manifest_status}")
print(f"BACKFILL_REBUILD_DRY_RUN_STATUS={dry_run_status}")
print(f"BACKFILL_REBUILD_APPLY_GATE_STATUS={apply_gate_status}")
print(f"BACKFILL_REBUILD_IDEMPOTENCY_STATUS={idempotency_status}")
print(f"BACKFILL_REBUILD_RESUME_STATUS={resume_status}")
print(f"BACKFILL_REBUILD_TENANT_SAFETY_STATUS={tenant_status}")
print(f"BACKFILL_REBUILD_CANDIDATE_PLAN_STATUS={candidate_plan_status}")
print("DB_MUTATION=NO")
print("BACKFILL_APPLY_EXECUTED=NO")
print("REBUILD_APPLY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"BACKFILL_REBUILD_STANDARD={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
