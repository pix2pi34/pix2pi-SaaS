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

standard_file = report_dir / "18_8_inventory_tests_standard.md"
report_file = report_dir / "18_8_inventory_tests_report.md"
matrix_file = report_dir / "18_8_inventory_tests_matrix.tsv"
inventory_file = report_dir / "18_8_inventory_tests_inventory.tsv"
closure_file = report_dir / "18_inventory_pilot_motor_final_closure_report.md"

reports = {
    "14": report_dir / "14_migration_lifecycle_import_final_closure_report.md",
    "15": report_dir / "15_readmodel_reporting_final_closure_report.md",
    "18.1": report_dir / "18_1_opening_stock_report.md",
    "18.2": report_dir / "18_2_stock_movement_engine_report.md",
    "18.3": report_dir / "18_3_sales_stock_decrement_report.md",
    "18.4": report_dir / "18_4_purchase_stock_increment_report.md",
    "18.5": report_dir / "18_5_stock_reservation_report.md",
    "18.6": report_dir / "18_6_negative_stock_policy_report.md",
    "18.7": report_dir / "18_7_stock_valuation_report.md",
}

migration_bases = {
    "18.1": "20260428_181001_inventory_opening_stock",
    "18.2": "20260428_182001_inventory_stock_movement_engine",
    "18.3": "20260428_183001_inventory_sales_stock_decrement",
    "18.4": "20260428_184001_inventory_purchase_stock_increment",
    "18.5": "20260428_185001_inventory_stock_reservation",
    "18.6": "20260428_186001_inventory_negative_stock_policy",
    "18.7": "20260428_187001_inventory_stock_valuation",
}

expected_table_counts = {
    "18.1": 5,
    "18.2": 7,
    "18.3": 6,
    "18.4": 6,
    "18.5": 7,
    "18.6": 6,
    "18.7": 6,
}

expected_status_keys = {
    "18.1": ("OPENING_STOCK", "OPENING_STOCK_TEST"),
    "18.2": ("STOCK_MOVEMENT_ENGINE", "STOCK_MOVEMENT_ENGINE_TEST"),
    "18.3": ("SALES_STOCK_DECREMENT", "SALES_STOCK_DECREMENT_TEST"),
    "18.4": ("PURCHASE_STOCK_INCREMENT", "PURCHASE_STOCK_INCREMENT_TEST"),
    "18.5": ("STOCK_RESERVATION", "STOCK_RESERVATION_TEST"),
    "18.6": ("NEGATIVE_STOCK_POLICY", "NEGATIVE_STOCK_POLICY_TEST"),
    "18.7": ("STOCK_VALUATION", "STOCK_VALUATION_TEST"),
}

execution_no_keys = {
    "18.1": ["DB_APPLY_EXECUTED", "MIGRATION_APPLY_EXECUTED", "STOCK_POSTING_EXECUTED"],
    "18.2": ["DB_APPLY_EXECUTED", "MIGRATION_APPLY_EXECUTED", "STOCK_MOVEMENT_EXECUTED", "STOCK_BALANCE_MUTATION"],
    "18.3": ["DB_APPLY_EXECUTED", "MIGRATION_APPLY_EXECUTED", "SALES_STOCK_DECREMENT_EXECUTED", "STOCK_MOVEMENT_EXECUTED", "STOCK_BALANCE_MUTATION"],
    "18.4": ["DB_APPLY_EXECUTED", "MIGRATION_APPLY_EXECUTED", "PURCHASE_STOCK_INCREMENT_EXECUTED", "STOCK_MOVEMENT_EXECUTED", "STOCK_BALANCE_MUTATION"],
    "18.5": ["DB_APPLY_EXECUTED", "MIGRATION_APPLY_EXECUTED", "STOCK_RESERVATION_EXECUTED", "STOCK_MOVEMENT_EXECUTED", "STOCK_BALANCE_MUTATION"],
    "18.6": ["DB_APPLY_EXECUTED", "MIGRATION_APPLY_EXECUTED", "NEGATIVE_STOCK_POLICY_EXECUTED", "STOCK_MOVEMENT_EXECUTED", "STOCK_BALANCE_MUTATION"],
    "18.7": ["DB_APPLY_EXECUTED", "MIGRATION_APPLY_EXECUTED", "STOCK_VALUATION_EXECUTED", "STOCK_MOVEMENT_EXECUTED", "STOCK_BALANCE_MUTATION"],
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

def count(pattern, text, flags=re.IGNORECASE | re.MULTILINE):
    return len(re.findall(pattern, text, flags))

def create_table_count(up_file):
    text = read(up_file)
    return len(set(re.findall(
        r"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+inventory\.([a-z0-9_]+)\s*\(",
        text,
        re.IGNORECASE,
    )))

def drop_table_count(down_file):
    return count(r"DROP\s+TABLE\s+IF\s+EXISTS\s+inventory\.", read(down_file))

def tenant_id_count(up_file):
    return count(r"\btenant_id\s+text\s+NOT\s+NULL\b", read(up_file))

def index_count(up_file):
    return count(r"CREATE\s+INDEX\s+IF\s+NOT\s+EXISTS", read(up_file))

def forbidden_token_count(up_file):
    text = read(up_file)
    return (
        count(r"\bTRUNCATE\b", text)
        + count(r"\bALTER\s+SYSTEM\b", text)
        + count(r"\bdocker\b", text)
        + count(r"\bsystemctl\b", text)
        + count(r"\bpsql\b", text)
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
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("STOCK_POSTING_EXECUTED=NO")
detail("STOCK_MOVEMENT_EXECUTED=NO")
detail("SALES_STOCK_DECREMENT_EXECUTED=NO")
detail("PURCHASE_STOCK_INCREMENT_EXECUTED=NO")
detail("STOCK_RESERVATION_EXECUTED=NO")
detail("NEGATIVE_STOCK_POLICY_EXECUTED=NO")
detail("STOCK_VALUATION_EXECUTED=NO")
detail("STOCK_BALANCE_MUTATION=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=INVENTORY_FINAL_EVIDENCE_ONLY")

tool_status("python3")
tool_status("bash")
tool_status("grep")
tool_status("wc")

if not standard_file.exists():
    fail("18.8 standard doc yok")

prev_14_status = get_value(reports["14"], "FAZ4B_14_FINAL_STATUS")
prev_14_tests = get_value(reports["14"], "MIGRATION_LIFECYCLE_IMPORT_TESTS")
prev_15_status = get_value(reports["15"], "FAZ4B_15_FINAL_STATUS")
prev_15_tests = get_value(reports["15"], "READMODEL_REPORTING_TEST_SET")

detail(f"PREVIOUS_14_FINAL_STATUS={prev_14_status}")
detail(f"PREVIOUS_14_MIGRATION_LIFECYCLE_IMPORT_TESTS={prev_14_tests}")
detail(f"PREVIOUS_15_FINAL_STATUS={prev_15_status}")
detail(f"PREVIOUS_15_READMODEL_REPORTING_TEST_SET={prev_15_tests}")

if prev_14_status != "PASS":
    fail("14 final status PASS degil")
if prev_14_tests != "PASS":
    fail("14 migration lifecycle import tests PASS degil")
if prev_15_status != "PASS":
    fail("15 final status PASS degil")
if prev_15_tests != "PASS":
    fail("15 readmodel reporting test set PASS degil")

block_results = {}
migration_results = {}
no_apply_failures = []
query_safety_failures = []

for block, path in reports.items():
    if not block.startswith("18."):
        continue

    final_key = f"FAZ4B_18_{block.split('.')[1]}_FINAL_STATUS"
    domain_key, test_name = expected_status_keys[block]
    final_status = get_value(path, final_key)
    domain_status = get_value(path, domain_key)
    query_text = get_value(path, "QUERY_TEXT_PRINTED")

    detail(f"PREVIOUS_{block.replace('.', '_')}_FINAL_STATUS={final_status}")
    detail(f"PREVIOUS_{block.replace('.', '_')}_{domain_key}={domain_status}")
    detail(f"PREVIOUS_{block.replace('.', '_')}_QUERY_TEXT_PRINTED={query_text}")

    status = "PASS" if final_status == "PASS" and domain_status == "PASS" else "FAIL"
    block_results[block] = {
        "test_name": test_name,
        "status": status,
        "final_status": final_status,
        "domain_key": domain_key,
        "domain_status": domain_status,
        "report": path,
    }

    if status != "PASS":
        fail(f"{block} {domain_key} veya final status PASS degil")

    if query_text != "NO":
        query_safety_failures.append(block)

    for key in execution_no_keys[block]:
        value = get_value(path, key)
        detail(f"PREVIOUS_{block.replace('.', '_')}_{key}={value}")
        if value != "NO":
            no_apply_failures.append(f"{block}:{key}={value}")

for block, base in migration_bases.items():
    up_file = migration_dir / f"{base}.up.sql"
    down_file = migration_dir / f"{base}.down.sql"

    up_exists = up_file.exists()
    down_exists = down_file.exists()
    table_count = create_table_count(up_file)
    drop_count = drop_table_count(down_file)
    tenant_count = tenant_id_count(up_file)
    idx_count = index_count(up_file)
    forbidden_count = forbidden_token_count(up_file)
    expected_count = expected_table_counts[block]

    detail(f"INVENTORY_{block.replace('.', '_')}_UP_EXISTS={'YES' if up_exists else 'NO'}")
    detail(f"INVENTORY_{block.replace('.', '_')}_DOWN_EXISTS={'YES' if down_exists else 'NO'}")
    detail(f"INVENTORY_{block.replace('.', '_')}_TABLE_COUNT={table_count}")
    detail(f"INVENTORY_{block.replace('.', '_')}_DOWN_DROP_COUNT={drop_count}")
    detail(f"INVENTORY_{block.replace('.', '_')}_TENANT_ID_COLUMN_COUNT={tenant_count}")
    detail(f"INVENTORY_{block.replace('.', '_')}_INDEX_COUNT={idx_count}")
    detail(f"INVENTORY_{block.replace('.', '_')}_FORBIDDEN_TOKEN_COUNT={forbidden_count}")

    migration_status = "PASS" if (
        up_exists
        and down_exists
        and table_count == expected_count
        and drop_count == expected_count
        and tenant_count == expected_count
        and forbidden_count == 0
    ) else "FAIL"

    migration_results[block] = {
        "status": migration_status,
        "up": up_file,
        "down": down_file,
        "table_count": table_count,
        "drop_count": drop_count,
        "tenant_count": tenant_count,
        "index_count": idx_count,
        "forbidden_count": forbidden_count,
    }

    if migration_status != "PASS":
        fail(f"{block} migration artifact gate PASS degil")

chain = all_current_migrations_valid()

detail(f"CURRENT_MIGRATION_SQL_FILE_COUNT={chain['sql_count']}")
detail(f"CURRENT_MIGRATION_INVALID_NAME_COUNT={chain['invalid_count']}")
detail(f"CURRENT_MIGRATION_PAIR_COUNT={chain['pair_count']}")
detail(f"CURRENT_MIGRATION_MISSING_PAIR_COUNT={chain['missing_pair_count']}")
detail(f"CURRENT_MIGRATION_DUPLICATE_PAIR_COUNT={chain['duplicate_pair_count']}")

migration_pair_test = "PASS" if (
    all(result["status"] == "PASS" for result in migration_results.values())
    and chain["invalid_count"] == 0
    and chain["missing_pair_count"] == 0
    and chain["duplicate_pair_count"] == 0
) else "FAIL"

no_apply_test = "PASS" if not no_apply_failures else "FAIL"
query_safety_test = "PASS" if not query_safety_failures else "FAIL"

if migration_pair_test != "PASS":
    fail("inventory migration pair test PASS degil")
if no_apply_test != "PASS":
    fail("inventory no-apply test PASS degil: " + ",".join(no_apply_failures))
if query_safety_test != "PASS":
    fail("inventory query safety test PASS degil: " + ",".join(query_safety_failures))

scan_files = [
    standard_file,
    *[v["report"] for v in block_results.values()],
]

secret_hits = []
query_hits = []

for path in scan_files:
    if not path.exists():
        continue
    text = read(path)
    rel = str(path.relative_to(root))
    if re.search(r"POSTGRES_PASSWORD=.*[A-Za-z0-9]", text):
        secret_hits.append(rel)
    if re.search(r"password=[^* \n]", text, re.IGNORECASE):
        secret_hits.append(rel)
    if re.search(r"Bearer\s+", text):
        secret_hits.append(rel)
    if re.search(r"\bSELECT\s+.*\bFROM\b", text, re.IGNORECASE):
        query_hits.append(rel)

detail(f"INVENTORY_SECRET_HIT_COUNT={len(secret_hits)}")
detail(f"INVENTORY_QUERY_TEXT_HIT_COUNT={len(query_hits)}")

secret_safety_test = "PASS" if not secret_hits and not query_hits and query_safety_test == "PASS" else "FAIL"

if secret_safety_test != "PASS":
    fail("inventory secret/query leak test PASS degil")

opening_stock_test = block_results["18.1"]["status"]
stock_movement_engine_test = block_results["18.2"]["status"]
sales_stock_decrement_test = block_results["18.3"]["status"]
purchase_stock_increment_test = block_results["18.4"]["status"]
stock_reservation_test = block_results["18.5"]["status"]
negative_stock_policy_test = block_results["18.6"]["status"]
stock_valuation_test = block_results["18.7"]["status"]

tenant_safety_test = "PASS" if all(
    migration_results[block]["tenant_count"] == expected_table_counts[block]
    for block in migration_results
) else "FAIL"

for label, status in [
    ("OPENING_STOCK_TEST", opening_stock_test),
    ("STOCK_MOVEMENT_ENGINE_TEST", stock_movement_engine_test),
    ("SALES_STOCK_DECREMENT_TEST", sales_stock_decrement_test),
    ("PURCHASE_STOCK_INCREMENT_TEST", purchase_stock_increment_test),
    ("STOCK_RESERVATION_TEST", stock_reservation_test),
    ("NEGATIVE_STOCK_POLICY_TEST", negative_stock_policy_test),
    ("STOCK_VALUATION_TEST", stock_valuation_test),
    ("INVENTORY_TENANT_SAFETY_TEST", tenant_safety_test),
    ("INVENTORY_MIGRATION_PAIR_TEST", migration_pair_test),
    ("INVENTORY_NO_APPLY_TEST", no_apply_test),
    ("INVENTORY_SECRET_SAFETY_TEST", secret_safety_test),
]:
    detail(f"{label}={status}")
    if status != "PASS":
        fail(f"{label} PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"opening_stock_test\t{opening_stock_test}\t18.1 opening stock evidence",
    f"stock_movement_engine_test\t{stock_movement_engine_test}\t18.2 movement engine evidence",
    f"sales_stock_decrement_test\t{sales_stock_decrement_test}\t18.3 sales decrement evidence",
    f"purchase_stock_increment_test\t{purchase_stock_increment_test}\t18.4 purchase increment evidence",
    f"stock_reservation_test\t{stock_reservation_test}\t18.5 reservation evidence",
    f"negative_stock_policy_test\t{negative_stock_policy_test}\t18.6 negative policy evidence",
    f"stock_valuation_test\t{stock_valuation_test}\t18.7 valuation evidence",
    f"inventory_tenant_safety_test\t{tenant_safety_test}\tall inventory tables have tenant_id",
    f"inventory_migration_pair_test\t{migration_pair_test}\tpairs={chain['pair_count']}",
    f"inventory_no_apply_test\t{no_apply_test}\tno runtime/apply/mutation executed",
    f"inventory_secret_safety_test\t{secret_safety_test}\tsecret_hits={len(secret_hits)} query_hits={len(query_hits)}",
    "db_mutation\tNO\tfinal evidence only",
    "db_apply_executed\tNO\tfinal evidence only",
    "stock_balance_mutation\tNO\tfinal evidence only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = ["block\tstatus\treport_file\tmigration_base\ttable_count\ttenant_id_count\tprimary_evidence"]
for block in ["18.1", "18.2", "18.3", "18.4", "18.5", "18.6", "18.7"]:
    result = block_results[block]
    mig = migration_results[block]
    inventory_lines.append(
        f"{block}\t{result['status']}\t{str(result['report'].relative_to(root))}\t{migration_bases[block]}\t{mig['table_count']}\t{mig['tenant_count']}\t{result['domain_key']}={result['domain_status']}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

detail(f"INVENTORY_TEST_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"INVENTORY_TEST_INVENTORY_LINE_COUNT={len(inventory_lines)}")

final_status = "PASS" if not failures else "FAIL"

detail(f"INVENTORY_TEST_SET={final_status}")
detail(f"INVENTORY_FINAL_CLOSURE={final_status}")
detail(f"FAZ4B_18_8_FINAL_STATUS={final_status}")
detail(f"FAZ4B_18_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 18.8 - Inventory Tests + Final Closure Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"INVENTORY_TEST_SET={final_status}",
    f"INVENTORY_FINAL_CLOSURE={final_status}",
    f"FAZ4B_18_8_FINAL_STATUS={final_status}",
    f"FAZ4B_18_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/18_8_inventory_tests_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/18_8_inventory_tests_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "STOCK_POSTING_EXECUTED=NO",
    "STOCK_MOVEMENT_EXECUTED=NO",
    "SALES_STOCK_DECREMENT_EXECUTED=NO",
    "PURCHASE_STOCK_INCREMENT_EXECUTED=NO",
    "STOCK_RESERVATION_EXECUTED=NO",
    "NEGATIVE_STOCK_POLICY_EXECUTED=NO",
    "STOCK_VALUATION_EXECUTED=NO",
    "STOCK_BALANCE_MUTATION=NO",
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
    "# FAZ 4B / 18 - ERP Stok / Inventory Pilot Motoru Final Closure",
    "",
    f"Generated at: {now()}",
    "",
    f"FAZ4B_18_FINAL_STATUS={final_status}",
    f"FAZ4B_18_8_FINAL_STATUS={final_status}",
    f"INVENTORY_TEST_SET={final_status}",
    f"INVENTORY_FINAL_CLOSURE={final_status}",
    "",
    "## Closed Items",
    f"18.1 Opening stock={block_results['18.1']['status']}",
    f"18.2 Stock movement engine={block_results['18.2']['status']}",
    f"18.3 Sales stock decrement={block_results['18.3']['status']}",
    f"18.4 Purchase stock increment={block_results['18.4']['status']}",
    f"18.5 Stock reservation={block_results['18.5']['status']}",
    f"18.6 Negative stock policy={block_results['18.6']['status']}",
    f"18.7 Stock valuation={block_results['18.7']['status']}",
    f"18.8 Inventory tests={final_status}",
    "",
    "## Final Gates",
    f"OPENING_STOCK_TEST={opening_stock_test}",
    f"STOCK_MOVEMENT_ENGINE_TEST={stock_movement_engine_test}",
    f"SALES_STOCK_DECREMENT_TEST={sales_stock_decrement_test}",
    f"PURCHASE_STOCK_INCREMENT_TEST={purchase_stock_increment_test}",
    f"STOCK_RESERVATION_TEST={stock_reservation_test}",
    f"NEGATIVE_STOCK_POLICY_TEST={negative_stock_policy_test}",
    f"STOCK_VALUATION_TEST={stock_valuation_test}",
    f"INVENTORY_TENANT_SAFETY_TEST={tenant_safety_test}",
    f"INVENTORY_MIGRATION_PAIR_TEST={migration_pair_test}",
    f"INVENTORY_NO_APPLY_TEST={no_apply_test}",
    f"INVENTORY_SECRET_SAFETY_TEST={secret_safety_test}",
    "",
    "## Safety",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "STOCK_BALANCE_MUTATION=NO",
    "QUERY_TEXT_PRINTED=NO",
]
closure_file.write_text("\n".join(closure_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"CLOSURE_FILE={closure_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"OPENING_STOCK_TEST={opening_stock_test}")
print(f"STOCK_MOVEMENT_ENGINE_TEST={stock_movement_engine_test}")
print(f"SALES_STOCK_DECREMENT_TEST={sales_stock_decrement_test}")
print(f"PURCHASE_STOCK_INCREMENT_TEST={purchase_stock_increment_test}")
print(f"STOCK_RESERVATION_TEST={stock_reservation_test}")
print(f"NEGATIVE_STOCK_POLICY_TEST={negative_stock_policy_test}")
print(f"STOCK_VALUATION_TEST={stock_valuation_test}")
print(f"INVENTORY_TENANT_SAFETY_TEST={tenant_safety_test}")
print(f"INVENTORY_MIGRATION_PAIR_TEST={migration_pair_test}")
print(f"INVENTORY_NO_APPLY_TEST={no_apply_test}")
print(f"INVENTORY_SECRET_SAFETY_TEST={secret_safety_test}")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("STOCK_BALANCE_MUTATION=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"INVENTORY_TEST_SET={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"INVENTORY_FINAL_CLOSURE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_18_8_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_18_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
