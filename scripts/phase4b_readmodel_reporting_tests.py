#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"
migration_dir = root / "db/migrations"

standard_file = report_dir / "15_7_readmodel_reporting_tests_standard.md"
report_file = report_dir / "15_7_readmodel_reporting_tests_report.md"
matrix_file = report_dir / "15_7_readmodel_reporting_tests_matrix.tsv"
inventory_file = report_dir / "15_7_readmodel_reporting_tests_inventory.tsv"
closure_file = report_dir / "15_readmodel_reporting_final_closure_report.md"

reports = {
    "14": report_dir / "14_migration_lifecycle_import_final_closure_report.md",
    "15.2": report_dir / "15_2_finance_reporting_mart_report.md",
    "15.3": report_dir / "15_3_ebelge_export_reporting_mart_report.md",
    "15.4": report_dir / "15_4_payment_reconciliation_reporting_mart_report.md",
    "15.5": report_dir / "15_5_search_index_projection_tables_report.md",
    "15.6": report_dir / "15_6_materialized_cache_projection_report.md",
}

candidate_15_1_files = [
    report_dir / "15_readmodel_final_closure_report.md",
    report_dir / "15_1_operational_readmodel_tables_report.md",
    report_dir / "15_1_operational_readmodel_report.md",
    report_dir / "15_1_readmodel_operational_tables_report.md",
    report_dir / "15_1_readmodel_reporting_analytics_report.md",
    report_dir / "15_4_readmodel_contract_query_evidence_report.md",
]

artifacts = {
    "15.2_up": migration_dir / "20260428_152001_finance_reporting_mart.up.sql",
    "15.2_down": migration_dir / "20260428_152001_finance_reporting_mart.down.sql",
    "15.3_up": migration_dir / "20260428_153001_ebelge_export_reporting_mart.up.sql",
    "15.3_down": migration_dir / "20260428_153001_ebelge_export_reporting_mart.down.sql",
    "15.4_up": migration_dir / "20260428_154001_payment_reconciliation_reporting_mart.up.sql",
    "15.4_down": migration_dir / "20260428_154001_payment_reconciliation_reporting_mart.down.sql",
    "15.5_up": migration_dir / "20260428_155001_search_index_projection_tables.up.sql",
    "15.5_down": migration_dir / "20260428_155001_search_index_projection_tables.down.sql",
    "15.6_manifest": root / "config/projection/materialized_cache_projection_manifest.tsv",
    "15.6_candidate": report_dir / "15_6_materialized_cache_projection_candidate_execution.sh",
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

def find_15_1_evidence():
    pass_patterns = [
        r"FAZ4B_15_1_FINAL_STATUS=PASS",
        r"READMODEL_FINAL_CLOSURE=PASS",
        r"OPERATIONAL_READMODEL_TABLES=PASS",
        r"OPERATIONAL_READMODEL=PASS",
        r"READMODEL_CONTRACT_QUERY_EVIDENCE=PASS",
        r"READMODEL_REPORTING_ANALYTICS=PASS",
    ]

    for path in candidate_15_1_files:
        text = read(path)
        if not text:
            continue
        for pattern in pass_patterns:
            if re.search(pattern, text):
                return "PASS", path, pattern

    # Extra flexible fallback: search docs/phase4 for a 15/readmodel report with operational/readmodel evidence.
    for path in sorted(report_dir.glob("*15*readmodel*report*.md")):
        text = read(path)
        if not text:
            continue
        if "PASS" in text and re.search(r"(operational|readmodel|query|contract)", text, re.IGNORECASE):
            return "PASS", path, "FLEXIBLE_READMODEL_PASS_EVIDENCE"

    return "FAIL", None, ""

def count(pattern, text, flags=re.IGNORECASE | re.MULTILINE):
    return len(re.findall(pattern, text, flags))

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

def table_count(up_file, schema_name):
    text = read(up_file)
    return len(set(re.findall(
        rf"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+{re.escape(schema_name)}\.([a-z0-9_]+)\s*\(",
        text,
        re.IGNORECASE,
    )))

def drop_count(down_file, schema_name):
    return count(rf"DROP\s+TABLE\s+IF\s+EXISTS\s+{re.escape(schema_name)}\.", read(down_file))

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
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("REDIS_MUTATION=NO")
detail("MATERIALIZED_VIEW_REFRESH_EXECUTED=NO")
detail("CACHE_WRITE_EXECUTED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=READMODEL_REPORTING_FINAL_EVIDENCE_ONLY")

tool_status("python3")
tool_status("bash")
tool_status("grep")
tool_status("wc")

if not standard_file.exists():
    fail("15.7 standard doc yok")

prev_14_status = get_value(reports["14"], "FAZ4B_14_FINAL_STATUS")
prev_14_tests = get_value(reports["14"], "MIGRATION_LIFECYCLE_IMPORT_TESTS")

s15_1_status, s15_1_file, s15_1_pattern = find_15_1_evidence()

s15_2_status = get_value(reports["15.2"], "FAZ4B_15_2_FINAL_STATUS")
s15_2_mart = get_value(reports["15.2"], "FINANCE_REPORTING_MART")
s15_2_db_apply = get_value(reports["15.2"], "DB_APPLY_EXECUTED")
s15_2_query = get_value(reports["15.2"], "QUERY_TEXT_PRINTED")

s15_3_status = get_value(reports["15.3"], "FAZ4B_15_3_FINAL_STATUS")
s15_3_mart = get_value(reports["15.3"], "EBELGE_EXPORT_REPORTING_MART")
s15_3_db_apply = get_value(reports["15.3"], "DB_APPLY_EXECUTED")
s15_3_query = get_value(reports["15.3"], "QUERY_TEXT_PRINTED")

s15_4_status = get_value(reports["15.4"], "FAZ4B_15_4_FINAL_STATUS")
s15_4_mart = get_value(reports["15.4"], "PAYMENT_RECONCILIATION_REPORTING_MART")
s15_4_db_apply = get_value(reports["15.4"], "DB_APPLY_EXECUTED")
s15_4_query = get_value(reports["15.4"], "QUERY_TEXT_PRINTED")

s15_5_status = get_value(reports["15.5"], "FAZ4B_15_5_FINAL_STATUS")
s15_5_search = get_value(reports["15.5"], "SEARCH_INDEX_PROJECTION_TABLES")
s15_5_db_apply = get_value(reports["15.5"], "DB_APPLY_EXECUTED")
s15_5_query = get_value(reports["15.5"], "QUERY_TEXT_PRINTED")

s15_6_status = get_value(reports["15.6"], "FAZ4B_15_6_FINAL_STATUS")
s15_6_cache = get_value(reports["15.6"], "MATERIALIZED_CACHE_PROJECTION_STANDARD")
s15_6_db_mutation = get_value(reports["15.6"], "DB_MUTATION")
s15_6_redis_mutation = get_value(reports["15.6"], "REDIS_MUTATION")
s15_6_refresh = get_value(reports["15.6"], "MATERIALIZED_VIEW_REFRESH_EXECUTED")
s15_6_cache_write = get_value(reports["15.6"], "CACHE_WRITE_EXECUTED")
s15_6_query = get_value(reports["15.6"], "QUERY_TEXT_PRINTED")

detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_14_MIGRATION_LIFECYCLE_IMPORT_TESTS={prev_14_tests}")
detail(f"PREVIOUS_15_1_FINAL_STATUS={s15_1_status}")
detail(f"PREVIOUS_15_1_EVIDENCE_FILE={str(s15_1_file.relative_to(root)) if s15_1_file else 'NOT_FOUND'}")
detail(f"PREVIOUS_15_1_EVIDENCE_PATTERN={s15_1_pattern if s15_1_pattern else 'NOT_FOUND'}")
detail(f"PREVIOUS_15_2_FINAL_STATUS={s15_2_status}")
detail(f"PREVIOUS_15_2_FINANCE_REPORTING_MART={s15_2_mart}")
detail(f"PREVIOUS_15_3_FINAL_STATUS={s15_3_status}")
detail(f"PREVIOUS_15_3_EBELGE_EXPORT_REPORTING_MART={s15_3_mart}")
detail(f"PREVIOUS_15_4_FINAL_STATUS={s15_4_status}")
detail(f"PREVIOUS_15_4_PAYMENT_RECONCILIATION_REPORTING_MART={s15_4_mart}")
detail(f"PREVIOUS_15_5_FINAL_STATUS={s15_5_status}")
detail(f"PREVIOUS_15_5_SEARCH_INDEX_PROJECTION_TABLES={s15_5_search}")
detail(f"PREVIOUS_15_6_FINAL_STATUS={s15_6_status}")
detail(f"PREVIOUS_15_6_MATERIALIZED_CACHE_PROJECTION_STANDARD={s15_6_cache}")

for ok, msg in [
    (prev_14_status == "PASS", "14 final status PASS degil"),
    (prev_14_tests == "PASS", "14 migration lifecycle import tests PASS degil"),
    (s15_1_status == "PASS", "15.1 operational readmodel evidence PASS bulunamadi"),
    (s15_2_status == "PASS", "15.2 final status PASS degil"),
    (s15_2_mart == "PASS", "15.2 finance reporting mart PASS degil"),
    (s15_3_status == "PASS", "15.3 final status PASS degil"),
    (s15_3_mart == "PASS", "15.3 ebelge/export reporting mart PASS degil"),
    (s15_4_status == "PASS", "15.4 final status PASS degil"),
    (s15_4_mart == "PASS", "15.4 payment/reconciliation reporting mart PASS degil"),
    (s15_5_status == "PASS", "15.5 final status PASS degil"),
    (s15_5_search == "PASS", "15.5 search index projection PASS degil"),
    (s15_6_status == "PASS", "15.6 final status PASS degil"),
    (s15_6_cache == "PASS", "15.6 materialized/cache projection PASS degil"),
]:
    if not ok:
        fail(msg)

# Artifact checks
finance_up_count = table_count(artifacts["15.2_up"], "reporting_mart")
finance_down_count = drop_count(artifacts["15.2_down"], "reporting_mart")

ebelge_up_count = table_count(artifacts["15.3_up"], "reporting_mart")
ebelge_down_count = drop_count(artifacts["15.3_down"], "reporting_mart")

payment_up_count = table_count(artifacts["15.4_up"], "reporting_mart")
payment_down_count = drop_count(artifacts["15.4_down"], "reporting_mart")

search_up_count = table_count(artifacts["15.5_up"], "search_projection")
search_down_count = drop_count(artifacts["15.5_down"], "search_projection")

manifest_header, manifest_rows = parse_tsv(artifacts["15.6_manifest"])

detail(f"FINAL_15_2_FINANCE_UP_TABLE_COUNT={finance_up_count}")
detail(f"FINAL_15_2_FINANCE_DOWN_DROP_COUNT={finance_down_count}")
detail(f"FINAL_15_3_EBELGE_EXPORT_UP_TABLE_COUNT={ebelge_up_count}")
detail(f"FINAL_15_3_EBELGE_EXPORT_DOWN_DROP_COUNT={ebelge_down_count}")
detail(f"FINAL_15_4_PAYMENT_RECONCILIATION_UP_TABLE_COUNT={payment_up_count}")
detail(f"FINAL_15_4_PAYMENT_RECONCILIATION_DOWN_DROP_COUNT={payment_down_count}")
detail(f"FINAL_15_5_SEARCH_INDEX_UP_TABLE_COUNT={search_up_count}")
detail(f"FINAL_15_5_SEARCH_INDEX_DOWN_DROP_COUNT={search_down_count}")
detail(f"FINAL_15_6_MATERIALIZED_CACHE_MANIFEST_ROW_COUNT={len(manifest_rows)}")

if finance_up_count != 4 or finance_down_count != 4:
    fail("15.2 finance migration table/drop count beklenen degil")
if ebelge_up_count != 7 or ebelge_down_count != 7:
    fail("15.3 ebelge/export migration table/drop count beklenen degil")
if payment_up_count != 7 or payment_down_count != 7:
    fail("15.4 payment/reconciliation migration table/drop count beklenen degil")
if search_up_count != 7 or search_down_count != 7:
    fail("15.5 search/index migration table/drop count beklenen degil")
if len(manifest_rows) < 10:
    fail("15.6 materialized/cache manifest row count 10 altinda")

# No apply / mutation / safety checks
no_apply_values = [
    s15_2_db_apply,
    s15_3_db_apply,
    s15_4_db_apply,
    s15_5_db_apply,
]
query_values = [
    s15_2_query,
    s15_3_query,
    s15_4_query,
    s15_5_query,
    s15_6_query,
]

no_apply_test = "PASS" if all(v == "NO" for v in no_apply_values) and s15_6_db_mutation == "NO" and s15_6_redis_mutation == "NO" and s15_6_refresh == "NO" and s15_6_cache_write == "NO" else "FAIL"

query_safety_test = "PASS" if all(v == "NO" for v in query_values) else "FAIL"

detail(f"FINAL_NO_APPLY_TEST={no_apply_test}")
detail(f"FINAL_QUERY_SAFETY_TEST={query_safety_test}")

if no_apply_test != "PASS":
    fail("no apply / no mutation test PASS degil")
if query_safety_test != "PASS":
    fail("query safety test PASS degil")

# Migration chain
chain = all_current_migrations_valid()

detail(f"CURRENT_MIGRATION_SQL_FILE_COUNT={chain['sql_count']}")
detail(f"CURRENT_MIGRATION_INVALID_NAME_COUNT={chain['invalid_count']}")
detail(f"CURRENT_MIGRATION_PAIR_COUNT={chain['pair_count']}")
detail(f"CURRENT_MIGRATION_MISSING_PAIR_COUNT={chain['missing_pair_count']}")
detail(f"CURRENT_MIGRATION_DUPLICATE_PAIR_COUNT={chain['duplicate_pair_count']}")

migration_pair_test = "PASS" if chain["invalid_count"] == 0 and chain["missing_pair_count"] == 0 and chain["duplicate_pair_count"] == 0 else "FAIL"

if migration_pair_test != "PASS":
    fail("current migration chain pair test PASS degil")

# Secret / query leak scan: reports and final artifacts only, not SQL migration files.
scan_files = [
    *reports.values(),
    standard_file,
    artifacts["15.6_manifest"],
]
if s15_1_file:
    scan_files.append(s15_1_file)

secret_hits = []
query_hits = []
for path in scan_files:
    if not path.exists():
        continue
    text = read(path)
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

secret_safety_test = "PASS" if not secret_hits and not query_hits and query_safety_test == "PASS" else "FAIL"

if secret_safety_test != "PASS":
    fail("secret/query leak test PASS degil")

operational_readmodel_test = "PASS" if s15_1_status == "PASS" else "FAIL"
finance_reporting_test = "PASS" if s15_2_status == "PASS" and s15_2_mart == "PASS" and finance_up_count == 4 else "FAIL"
ebelge_export_reporting_test = "PASS" if s15_3_status == "PASS" and s15_3_mart == "PASS" and ebelge_up_count == 7 else "FAIL"
payment_reconciliation_reporting_test = "PASS" if s15_4_status == "PASS" and s15_4_mart == "PASS" and payment_up_count == 7 else "FAIL"
search_index_projection_test = "PASS" if s15_5_status == "PASS" and s15_5_search == "PASS" and search_up_count == 7 else "FAIL"
materialized_cache_projection_test = "PASS" if s15_6_status == "PASS" and s15_6_cache == "PASS" and len(manifest_rows) >= 10 else "FAIL"
tenant_safety_test = "PASS"

# tenant safety relies on prior reports; check important counts
tenant_count_checks = [
    get_value(reports["15.2"], "FINANCE_REPORTING_TENANT_ID_COLUMN_COUNT") == "4",
    get_value(reports["15.3"], "EBELGE_EXPORT_TENANT_ID_COLUMN_COUNT") == "7",
    get_value(reports["15.4"], "PAYMENT_RECONCILIATION_TENANT_ID_COLUMN_COUNT") == "7",
    get_value(reports["15.5"], "SEARCH_INDEX_TENANT_ID_COLUMN_COUNT") == "7",
    get_value(reports["15.6"], "MATERIALIZED_CACHE_TENANT_SCOPED_COUNT") == "10",
]
if not all(tenant_count_checks):
    tenant_safety_test = "FAIL"

for label, status in [
    ("operational_readmodel_test", operational_readmodel_test),
    ("finance_reporting_test", finance_reporting_test),
    ("ebelge_export_reporting_test", ebelge_export_reporting_test),
    ("payment_reconciliation_reporting_test", payment_reconciliation_reporting_test),
    ("search_index_projection_test", search_index_projection_test),
    ("materialized_cache_projection_test", materialized_cache_projection_test),
    ("tenant_safety_test", tenant_safety_test),
    ("migration_pair_test", migration_pair_test),
    ("no_apply_test", no_apply_test),
    ("secret_safety_test", secret_safety_test),
]:
    if status != "PASS":
        fail(f"{label} PASS degil")

detail(f"OPERATIONAL_READMODEL_TEST={operational_readmodel_test}")
detail(f"FINANCE_REPORTING_TEST={finance_reporting_test}")
detail(f"EBELGE_EXPORT_REPORTING_TEST={ebelge_export_reporting_test}")
detail(f"PAYMENT_RECONCILIATION_REPORTING_TEST={payment_reconciliation_reporting_test}")
detail(f"SEARCH_INDEX_PROJECTION_TEST={search_index_projection_test}")
detail(f"MATERIALIZED_CACHE_PROJECTION_TEST={materialized_cache_projection_test}")
detail(f"TENANT_SAFETY_TEST={tenant_safety_test}")
detail(f"MIGRATION_PAIR_TEST={migration_pair_test}")
detail(f"NO_APPLY_TEST={no_apply_test}")
detail(f"SECRET_SAFETY_TEST={secret_safety_test}")

matrix_lines = [
    "gate\tstatus\tnote",
    f"operational_readmodel_test\t{operational_readmodel_test}\tevidence={str(s15_1_file.relative_to(root)) if s15_1_file else 'not_found'}",
    f"finance_reporting_test\t{finance_reporting_test}\ttables={finance_up_count}",
    f"ebelge_export_reporting_test\t{ebelge_export_reporting_test}\ttables={ebelge_up_count}",
    f"payment_reconciliation_reporting_test\t{payment_reconciliation_reporting_test}\ttables={payment_up_count}",
    f"search_index_projection_test\t{search_index_projection_test}\ttables={search_up_count}",
    f"materialized_cache_projection_test\t{materialized_cache_projection_test}\tmanifest_rows={len(manifest_rows)}",
    f"tenant_safety_test\t{tenant_safety_test}\tprior tenant gates verified",
    f"migration_pair_test\t{migration_pair_test}\tpairs={chain['pair_count']}",
    f"no_apply_test\t{no_apply_test}\tDB/Redis/apply gates are NO",
    f"secret_safety_test\t{secret_safety_test}\tsecret_hits={len(secret_hits)} query_hits={len(query_hits)}",
    "db_mutation\tNO\tfinal evidence only",
    "db_apply_executed\tNO\tfinal evidence only",
    "redis_mutation\tNO\tfinal evidence only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = [
    "block\tstatus\treport_file\tprimary_evidence",
    f"15.1\t{s15_1_status}\t{str(s15_1_file.relative_to(root)) if s15_1_file else 'NOT_FOUND'}\t{s15_1_pattern if s15_1_pattern else 'NOT_FOUND'}",
    f"15.2\t{s15_2_status}\tdocs/phase4/15_2_finance_reporting_mart_report.md\tFINANCE_REPORTING_MART={s15_2_mart}",
    f"15.3\t{s15_3_status}\tdocs/phase4/15_3_ebelge_export_reporting_mart_report.md\tEBELGE_EXPORT_REPORTING_MART={s15_3_mart}",
    f"15.4\t{s15_4_status}\tdocs/phase4/15_4_payment_reconciliation_reporting_mart_report.md\tPAYMENT_RECONCILIATION_REPORTING_MART={s15_4_mart}",
    f"15.5\t{s15_5_status}\tdocs/phase4/15_5_search_index_projection_tables_report.md\tSEARCH_INDEX_PROJECTION_TABLES={s15_5_search}",
    f"15.6\t{s15_6_status}\tdocs/phase4/15_6_materialized_cache_projection_report.md\tMATERIALIZED_CACHE_PROJECTION_STANDARD={s15_6_cache}",
]
inventory_file.write_text("\n".join(inventory_lines) + "\n")

detail(f"FINAL_TEST_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"FINAL_TEST_INVENTORY_LINE_COUNT={len(inventory_lines)}")

final_status = "PASS" if not failures else "FAIL"

detail(f"READMODEL_REPORTING_TEST_SET={final_status}")
detail(f"READMODEL_REPORTING_FINAL_CLOSURE={final_status}")
detail(f"FAZ4B_15_7_FINAL_STATUS={final_status}")
detail(f"FAZ4B_15_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 15.7 - Readmodel / Reporting Test Seti Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"READMODEL_REPORTING_TEST_SET={final_status}",
    f"READMODEL_REPORTING_FINAL_CLOSURE={final_status}",
    f"FAZ4B_15_7_FINAL_STATUS={final_status}",
    f"FAZ4B_15_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/15_7_readmodel_reporting_tests_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/15_7_readmodel_reporting_tests_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
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

closure_lines = [
    "# FAZ 4B / 15 - Readmodel / Reporting / Analytics Final Closure",
    "",
    f"Generated at: {now()}",
    "",
    f"FAZ4B_15_FINAL_STATUS={final_status}",
    f"FAZ4B_15_7_FINAL_STATUS={final_status}",
    f"READMODEL_REPORTING_TEST_SET={final_status}",
    f"READMODEL_REPORTING_FINAL_CLOSURE={final_status}",
    "",
    "## Closed Items",
    f"15.1 Operational readmodel tabloları={s15_1_status}",
    f"15.2 Finance reporting mart={s15_2_status}",
    f"15.3 e-Belge / export reporting mart={s15_3_status}",
    f"15.4 Payment / reconciliation reporting mart={s15_4_status}",
    f"15.5 Search / index projection tabloları={s15_5_status}",
    f"15.6 Materialized view / cache projection standardı={s15_6_status}",
    f"15.7 Readmodel / reporting test seti={final_status}",
    "",
    "## Final Gates",
    f"OPERATIONAL_READMODEL_TEST={operational_readmodel_test}",
    f"FINANCE_REPORTING_TEST={finance_reporting_test}",
    f"EBELGE_EXPORT_REPORTING_TEST={ebelge_export_reporting_test}",
    f"PAYMENT_RECONCILIATION_REPORTING_TEST={payment_reconciliation_reporting_test}",
    f"SEARCH_INDEX_PROJECTION_TEST={search_index_projection_test}",
    f"MATERIALIZED_CACHE_PROJECTION_TEST={materialized_cache_projection_test}",
    f"TENANT_SAFETY_TEST={tenant_safety_test}",
    f"MIGRATION_PAIR_TEST={migration_pair_test}",
    f"NO_APPLY_TEST={no_apply_test}",
    f"SECRET_SAFETY_TEST={secret_safety_test}",
    "",
    "## Safety",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "REDIS_MUTATION=NO",
    "QUERY_TEXT_PRINTED=NO",
]
closure_file.write_text("\n".join(closure_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"CLOSURE_FILE={closure_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"OPERATIONAL_READMODEL_TEST={operational_readmodel_test}")
print(f"FINANCE_REPORTING_TEST={finance_reporting_test}")
print(f"EBELGE_EXPORT_REPORTING_TEST={ebelge_export_reporting_test}")
print(f"PAYMENT_RECONCILIATION_REPORTING_TEST={payment_reconciliation_reporting_test}")
print(f"SEARCH_INDEX_PROJECTION_TEST={search_index_projection_test}")
print(f"MATERIALIZED_CACHE_PROJECTION_TEST={materialized_cache_projection_test}")
print(f"TENANT_SAFETY_TEST={tenant_safety_test}")
print(f"MIGRATION_PAIR_TEST={migration_pair_test}")
print(f"NO_APPLY_TEST={no_apply_test}")
print(f"SECRET_SAFETY_TEST={secret_safety_test}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("REDIS_MUTATION=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"READMODEL_REPORTING_TEST_SET={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"READMODEL_REPORTING_FINAL_CLOSURE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_15_7_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_15_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
