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
manifest_file = root / "config/projection/materialized_cache_projection_manifest.tsv"
doc_manifest_file = report_dir / "15_6_materialized_cache_projection_manifest.tsv"
standard_file = report_dir / "15_6_materialized_cache_projection_standard.md"
report_file = report_dir / "15_6_materialized_cache_projection_report.md"
matrix_file = report_dir / "15_6_materialized_cache_projection_matrix.tsv"
candidate_plan = report_dir / "15_6_materialized_cache_projection_candidate_execution.sh"

prev_14 = report_dir / "14_migration_lifecycle_import_final_closure_report.md"
prev_15_2 = report_dir / "15_2_finance_reporting_mart_report.md"
prev_15_3 = report_dir / "15_3_ebelge_export_reporting_mart_report.md"
prev_15_4 = report_dir / "15_4_payment_reconciliation_reporting_mart_report.md"
prev_15_5 = report_dir / "15_5_search_index_projection_tables_report.md"

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
            env={**os.environ, "APPLY_MATERIALIZED_CACHE": "0"},
        )
        output = proc.stdout
        if (
            proc.returncode == 0
            and "MATERIALIZED_CACHE_PLAN_BLOCKED_BY_DEFAULT=YES" in output
            and "MATERIALIZED_VIEW_REFRESH_EXECUTED=NO" in output
            and "CACHE_WRITE_EXECUTED=NO" in output
            and "REDIS_MUTATION=NO" in output
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
detail("REDIS_MUTATION=NO")
detail("MATERIALIZED_VIEW_REFRESH_EXECUTED=NO")
detail("CACHE_WRITE_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=MATERIALIZED_CACHE_PROJECTION_STANDARD_ONLY")

tool_status("python3")
tool_status("bash")
tool_status("grep")
tool_status("wc")

prev_14_status = get_value(prev_14, "FAZ4B_14_FINAL_STATUS")
prev_14_tests = get_value(prev_14, "MIGRATION_LIFECYCLE_IMPORT_TESTS")

prev_15_2_status = get_value(prev_15_2, "FAZ4B_15_2_FINAL_STATUS")
prev_15_2_mart = get_value(prev_15_2, "FINANCE_REPORTING_MART")

prev_15_3_status = get_value(prev_15_3, "FAZ4B_15_3_FINAL_STATUS")
prev_15_3_mart = get_value(prev_15_3, "EBELGE_EXPORT_REPORTING_MART")

prev_15_4_status = get_value(prev_15_4, "FAZ4B_15_4_FINAL_STATUS")
prev_15_4_mart = get_value(prev_15_4, "PAYMENT_RECONCILIATION_REPORTING_MART")

prev_15_5_status = get_value(prev_15_5, "FAZ4B_15_5_FINAL_STATUS")
prev_15_5_search = get_value(prev_15_5, "SEARCH_INDEX_PROJECTION_TABLES")
prev_15_5_db_apply = get_value(prev_15_5, "DB_APPLY_EXECUTED")

detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_14_MIGRATION_LIFECYCLE_IMPORT_TESTS={prev_14_tests}")
detail(f"PREVIOUS_15_2_FINAL_STATUS={prev_15_2_status}")
detail(f"PREVIOUS_15_2_FINANCE_REPORTING_MART={prev_15_2_mart}")
detail(f"PREVIOUS_15_3_FINAL_STATUS={prev_15_3_status}")
detail(f"PREVIOUS_15_3_EBELGE_EXPORT_REPORTING_MART={prev_15_3_mart}")
detail(f"PREVIOUS_15_4_FINAL_STATUS={prev_15_4_status}")
detail(f"PREVIOUS_15_4_PAYMENT_RECONCILIATION_REPORTING_MART={prev_15_4_mart}")
detail(f"PREVIOUS_15_5_FINAL_STATUS={prev_15_5_status}")
detail(f"PREVIOUS_15_5_SEARCH_INDEX_PROJECTION_TABLES={prev_15_5_search}")
detail(f"PREVIOUS_15_5_DB_APPLY_EXECUTED={prev_15_5_db_apply}")

for ok, msg in [
    (prev_14_status == "PASS", "14 final status PASS degil"),
    (prev_14_tests == "PASS", "14 migration lifecycle import tests PASS degil"),
    (prev_15_2_status == "PASS", "15.2 final status PASS degil"),
    (prev_15_2_mart == "PASS", "15.2 finance reporting mart PASS degil"),
    (prev_15_3_status == "PASS", "15.3 final status PASS degil"),
    (prev_15_3_mart == "PASS", "15.3 ebelge export reporting mart PASS degil"),
    (prev_15_4_status == "PASS", "15.4 final status PASS degil"),
    (prev_15_4_mart == "PASS", "15.4 payment reconciliation reporting mart PASS degil"),
    (prev_15_5_status == "PASS", "15.5 final status PASS degil"),
    (prev_15_5_search == "PASS", "15.5 search index projection PASS degil"),
    (prev_15_5_db_apply == "NO", "15.5 DB apply NO degil"),
]:
    if not ok:
        fail(msg)

if not standard_file.exists():
    fail("15.6 standard doc yok")

required_cols = [
    "projection_key",
    "domain",
    "source_scope",
    "target_projection",
    "projection_type",
    "tenant_scoped",
    "cache_key_pattern",
    "ttl_seconds",
    "refresh_strategy",
    "refresh_trigger",
    "rebuild_strategy",
    "invalidation_strategy",
    "dry_run_required",
    "apply_gate_required",
    "mutation_scope",
    "note",
]

header, rows = parse_tsv(manifest_file)
doc_header, doc_rows = parse_tsv(doc_manifest_file)

missing_cols = [col for col in required_cols if col not in header]
duplicate_projection_keys = duplicate_values(rows, "projection_key")

required_projections = [
    "finance_daily_dashboard",
    "finance_period_kpi_cache",
    "ebelge_status_dashboard",
    "payment_reconciliation_dashboard",
    "party_search_cache",
    "product_search_cache",
    "inventory_balance_cache",
    "global_search_cache",
    "reporting_home_snapshot",
    "pilot_ops_health_cache",
]

existing_projections = set(row.get("projection_key", "") for row in rows)
missing_projections = [p for p in required_projections if p not in existing_projections]

detail(f"MATERIALIZED_CACHE_MANIFEST_FILE_EXISTS={'YES' if manifest_file.exists() else 'NO'}")
detail(f"MATERIALIZED_CACHE_DOC_MANIFEST_FILE_EXISTS={'YES' if doc_manifest_file.exists() else 'NO'}")
detail(f"MATERIALIZED_CACHE_MANIFEST_ROW_COUNT={len(rows)}")
detail(f"MATERIALIZED_CACHE_DOC_MANIFEST_ROW_COUNT={len(doc_rows)}")
detail(f"MATERIALIZED_CACHE_MISSING_COLUMN_COUNT={len(missing_cols)}")
detail(f"MATERIALIZED_CACHE_DUPLICATE_PROJECTION_KEY_COUNT={len(duplicate_projection_keys)}")
detail(f"MATERIALIZED_CACHE_REQUIRED_PROJECTION_MISSING_COUNT={len(missing_projections)}")

if missing_cols:
    fail("manifest kolonlari eksik: " + ",".join(missing_cols))
if duplicate_projection_keys:
    fail("duplicate projection_key var: " + ",".join(duplicate_projection_keys))
if missing_projections:
    fail("required projection eksik: " + ",".join(missing_projections))

bad_tenant = []
bad_cache_key = []
bad_ttl = []
bad_refresh = []
bad_rebuild = []
bad_invalidation = []
bad_dry_run = []
bad_apply_gate = []
bad_mutation_scope = []
bad_projection_type = []

allowed_projection_types = {"MATERIALIZED_VIEW", "CACHE_PROJECTION", "HYBRID"}

for row in rows:
    key = row.get("projection_key", "")
    projection_type = row.get("projection_type", "")
    cache_key = row.get("cache_key_pattern", "")

    if row.get("tenant_scoped", "") != "YES":
        bad_tenant.append(key)

    if "tenant:{tenant_id}:" not in cache_key:
        bad_cache_key.append(key)

    ttl = to_int(row.get("ttl_seconds", ""))
    if ttl is None or ttl <= 0 or ttl > 86400:
        bad_ttl.append(key)

    if not row.get("refresh_strategy", "") or not row.get("refresh_trigger", ""):
        bad_refresh.append(key)

    if not row.get("rebuild_strategy", ""):
        bad_rebuild.append(key)

    if not row.get("invalidation_strategy", ""):
        bad_invalidation.append(key)

    if row.get("dry_run_required", "") != "YES":
        bad_dry_run.append(key)

    if row.get("apply_gate_required", "") != "YES":
        bad_apply_gate.append(key)

    if not row.get("mutation_scope", ""):
        bad_mutation_scope.append(key)

    if projection_type not in allowed_projection_types:
        bad_projection_type.append(key)

tenant_scoped_count = sum(1 for row in rows if row.get("tenant_scoped") == "YES")
cache_projection_count = sum(1 for row in rows if row.get("projection_type") == "CACHE_PROJECTION")
materialized_view_count = sum(1 for row in rows if row.get("projection_type") == "MATERIALIZED_VIEW")
hybrid_count = sum(1 for row in rows if row.get("projection_type") == "HYBRID")
dry_run_yes_count = sum(1 for row in rows if row.get("dry_run_required") == "YES")
apply_gate_yes_count = sum(1 for row in rows if row.get("apply_gate_required") == "YES")

detail(f"MATERIALIZED_CACHE_TENANT_SCOPED_COUNT={tenant_scoped_count}")
detail(f"MATERIALIZED_CACHE_CACHE_PROJECTION_COUNT={cache_projection_count}")
detail(f"MATERIALIZED_CACHE_MATERIALIZED_VIEW_COUNT={materialized_view_count}")
detail(f"MATERIALIZED_CACHE_HYBRID_COUNT={hybrid_count}")
detail(f"MATERIALIZED_CACHE_DRY_RUN_YES_COUNT={dry_run_yes_count}")
detail(f"MATERIALIZED_CACHE_APPLY_GATE_YES_COUNT={apply_gate_yes_count}")
detail(f"MATERIALIZED_CACHE_BAD_TENANT_COUNT={len(bad_tenant)}")
detail(f"MATERIALIZED_CACHE_BAD_CACHE_KEY_COUNT={len(bad_cache_key)}")
detail(f"MATERIALIZED_CACHE_BAD_TTL_COUNT={len(bad_ttl)}")
detail(f"MATERIALIZED_CACHE_BAD_REFRESH_COUNT={len(bad_refresh)}")
detail(f"MATERIALIZED_CACHE_BAD_REBUILD_COUNT={len(bad_rebuild)}")
detail(f"MATERIALIZED_CACHE_BAD_INVALIDATION_COUNT={len(bad_invalidation)}")
detail(f"MATERIALIZED_CACHE_BAD_DRY_RUN_COUNT={len(bad_dry_run)}")
detail(f"MATERIALIZED_CACHE_BAD_APPLY_GATE_COUNT={len(bad_apply_gate)}")
detail(f"MATERIALIZED_CACHE_BAD_MUTATION_SCOPE_COUNT={len(bad_mutation_scope)}")
detail(f"MATERIALIZED_CACHE_BAD_PROJECTION_TYPE_COUNT={len(bad_projection_type)}")

for label, bad in [
    ("tenant", bad_tenant),
    ("cache key", bad_cache_key),
    ("ttl", bad_ttl),
    ("refresh", bad_refresh),
    ("rebuild", bad_rebuild),
    ("invalidation", bad_invalidation),
    ("dry run", bad_dry_run),
    ("apply gate", bad_apply_gate),
    ("mutation scope", bad_mutation_scope),
    ("projection type", bad_projection_type),
]:
    if bad:
        fail(f"{label} ihlali var: " + ",".join(bad))

if len(rows) < 10:
    fail("materialized/cache projection manifest row count 10 altinda")
if tenant_scoped_count != len(rows):
    fail("tenant scoped count row count ile esit degil")
if dry_run_yes_count != len(rows):
    fail("dry run YES count row count ile esit degil")
if apply_gate_yes_count != len(rows):
    fail("apply gate YES count row count ile esit degil")
if cache_projection_count < 5:
    fail("cache projection count 5 altinda")
if materialized_view_count < 1:
    fail("materialized view count 1 altinda")
if hybrid_count < 2:
    fail("hybrid projection count 2 altinda")

plan_text = candidate_plan.read_text(errors="ignore") if candidate_plan.exists() else ""
candidate_plan_status, candidate_output = run_candidate_plan()

candidate_contains_guard = "APPLY_MATERIALIZED_CACHE" in plan_text
candidate_contains_block = "MATERIALIZED_CACHE_PLAN_BLOCKED_BY_DEFAULT=YES" in plan_text
candidate_contains_no_apply = (
    "DB_MUTATION=NO" in plan_text
    and "REDIS_MUTATION=NO" in plan_text
    and "MATERIALIZED_VIEW_REFRESH_EXECUTED=NO" in plan_text
    and "CACHE_WRITE_EXECUTED=NO" in plan_text
)

detail(f"MATERIALIZED_CACHE_CANDIDATE_PLAN_FILE_EXISTS={'YES' if candidate_plan.exists() else 'NO'}")
detail(f"MATERIALIZED_CACHE_CANDIDATE_PLAN_GUARD_EXISTS={'YES' if candidate_contains_guard else 'NO'}")
detail(f"MATERIALIZED_CACHE_CANDIDATE_PLAN_BLOCKED_BY_DEFAULT={'YES' if candidate_contains_block else 'NO'}")
detail(f"MATERIALIZED_CACHE_CANDIDATE_PLAN_NO_APPLY_MARKERS={'YES' if candidate_contains_no_apply else 'NO'}")
detail(f"MATERIALIZED_CACHE_CANDIDATE_PLAN_DRY_RUN_STATUS={candidate_plan_status}")

if candidate_plan_status != "PASS":
    fail("candidate execution plan default blocked PASS degil")
if not candidate_contains_guard:
    fail("candidate plan APPLY_MATERIALIZED_CACHE guard icermiyor")
if not candidate_contains_block:
    fail("candidate plan blocked by default icermiyor")
if not candidate_contains_no_apply:
    fail("candidate plan no apply markers icermiyor")

manifest_status = "PASS" if manifest_file.exists() and not missing_cols and len(rows) >= 10 and not missing_projections else "FAIL"
tenant_key_status = "PASS" if not bad_tenant and not bad_cache_key and tenant_scoped_count == len(rows) else "FAIL"
refresh_status = "PASS" if not bad_refresh and not bad_ttl else "FAIL"
rebuild_status = "PASS" if not bad_rebuild else "FAIL"
invalidation_status = "PASS" if not bad_invalidation else "FAIL"
projection_type_status = "PASS" if not bad_projection_type and cache_projection_count >= 5 and materialized_view_count >= 1 and hybrid_count >= 2 else "FAIL"
apply_gate_status = "PASS" if not bad_dry_run and not bad_apply_gate and dry_run_yes_count == len(rows) and apply_gate_yes_count == len(rows) else "FAIL"

detail(f"MATERIALIZED_CACHE_MANIFEST_STATUS={manifest_status}")
detail(f"MATERIALIZED_CACHE_TENANT_KEY_STATUS={tenant_key_status}")
detail(f"MATERIALIZED_CACHE_REFRESH_STATUS={refresh_status}")
detail(f"MATERIALIZED_CACHE_REBUILD_STATUS={rebuild_status}")
detail(f"MATERIALIZED_CACHE_INVALIDATION_STATUS={invalidation_status}")
detail(f"MATERIALIZED_CACHE_PROJECTION_TYPE_STATUS={projection_type_status}")
detail(f"MATERIALIZED_CACHE_APPLY_GATE_STATUS={apply_gate_status}")
detail(f"MATERIALIZED_CACHE_CANDIDATE_PLAN_STATUS={candidate_plan_status}")

for name, status in [
    ("manifest", manifest_status),
    ("tenant_key", tenant_key_status),
    ("refresh", refresh_status),
    ("rebuild", rebuild_status),
    ("invalidation", invalidation_status),
    ("projection_type", projection_type_status),
    ("apply_gate", apply_gate_status),
    ("candidate_plan", candidate_plan_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_14\t{prev_14_status}\tmigration lifecycle prerequisite",
    f"previous_15_2\t{prev_15_2_status}\tfinance reporting prerequisite",
    f"previous_15_3\t{prev_15_3_status}\tebelge/export prerequisite",
    f"previous_15_4\t{prev_15_4_status}\tpayment/reconciliation prerequisite",
    f"previous_15_5\t{prev_15_5_status}\tsearch/index prerequisite",
    f"manifest\t{manifest_status}\trows={len(rows)}",
    f"tenant_cache_key\t{tenant_key_status}\ttenant_scoped={tenant_scoped_count}",
    f"refresh\t{refresh_status}\tbad_refresh={len(bad_refresh)} bad_ttl={len(bad_ttl)}",
    f"rebuild\t{rebuild_status}\tbad_rebuild={len(bad_rebuild)}",
    f"invalidation\t{invalidation_status}\tbad_invalidation={len(bad_invalidation)}",
    f"projection_type\t{projection_type_status}\tcache={cache_projection_count} materialized={materialized_view_count} hybrid={hybrid_count}",
    f"apply_gate\t{apply_gate_status}\tdry_run={dry_run_yes_count} apply_gate={apply_gate_yes_count}",
    f"candidate_plan\t{candidate_plan_status}\tblocked_by_default={'YES' if candidate_contains_block else 'NO'}",
    "db_mutation\tNO\tstandard only",
    "redis_mutation\tNO\tstandard only",
    "materialized_view_refresh_executed\tNO\tstandard only",
    "cache_write_executed\tNO\tstandard only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"MATERIALIZED_CACHE_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"MATERIALIZED_CACHE_PROJECTION_STANDARD={final_status}")
detail(f"FAZ4B_15_6_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 15.6 - Materialized View / Cache Projection Standardı Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"MATERIALIZED_CACHE_PROJECTION_STANDARD={final_status}",
    f"FAZ4B_15_6_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/15_6_materialized_cache_projection_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Manifest",
    "MANIFEST_FILE=config/projection/materialized_cache_projection_manifest.tsv",
    manifest_file.read_text(errors="ignore").rstrip(),
    "",
    "## Candidate Execution Plan Output",
    "\n".join(candidate_output.splitlines()[:60]) if candidate_output else "candidate output yok",
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "REDIS_MUTATION=NO",
    "MATERIALIZED_VIEW_REFRESH_EXECUTED=NO",
    "CACHE_WRITE_EXECUTED=NO",
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
print(f"MATERIALIZED_CACHE_MANIFEST_ROW_COUNT={len(rows)}")
print(f"MATERIALIZED_CACHE_TENANT_SCOPED_COUNT={tenant_scoped_count}")
print(f"MATERIALIZED_CACHE_CACHE_PROJECTION_COUNT={cache_projection_count}")
print(f"MATERIALIZED_CACHE_MATERIALIZED_VIEW_COUNT={materialized_view_count}")
print(f"MATERIALIZED_CACHE_HYBRID_COUNT={hybrid_count}")
print(f"MATERIALIZED_CACHE_MANIFEST_STATUS={manifest_status}")
print(f"MATERIALIZED_CACHE_TENANT_KEY_STATUS={tenant_key_status}")
print(f"MATERIALIZED_CACHE_REFRESH_STATUS={refresh_status}")
print(f"MATERIALIZED_CACHE_REBUILD_STATUS={rebuild_status}")
print(f"MATERIALIZED_CACHE_INVALIDATION_STATUS={invalidation_status}")
print(f"MATERIALIZED_CACHE_CANDIDATE_PLAN_STATUS={candidate_plan_status}")
print("DB_MUTATION=NO")
print("REDIS_MUTATION=NO")
print("MATERIALIZED_VIEW_REFRESH_EXECUTED=NO")
print("CACHE_WRITE_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"MATERIALIZED_CACHE_PROJECTION_STANDARD={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
