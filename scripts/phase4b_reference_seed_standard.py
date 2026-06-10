#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()

report_dir = root / "docs/phase4"
manifest_file = root / "config/reference-data/seed_manifest.tsv"
doc_manifest_file = report_dir / "14_2_reference_seed_manifest.tsv"
scope_file = report_dir / "14_2_reference_seed_scope_rules.tsv"

standard_file = report_dir / "14_2_reference_seed_standard.md"
report_file = report_dir / "14_2_reference_seed_report.md"
matrix_file = report_dir / "14_2_reference_seed_matrix.tsv"

prev_14_1 = report_dir / "14_1_pilot_migration_chain_report.md"

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

def count_scope(rows, scope):
    return sum(1 for row in rows if row.get("scope") == scope)

def unique_values(rows, key):
    return sorted(set(row.get(key, "") for row in rows if row.get(key, "")))

def has_duplicate(rows, key):
    seen = set()
    duplicates = []
    for row in rows:
        value = row.get(key, "")
        if value in seen:
            duplicates.append(value)
        seen.add(value)
    return duplicates

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("SEED_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("VALIDATION_MODE=REFERENCE_SEED_STANDARD_ONLY")

tool_status("python3")
tool_status("grep")
tool_status("wc")

prev_status = get_value(prev_14_1, "FAZ4B_14_1_FINAL_STATUS")
prev_chain = get_value(prev_14_1, "MIGRATION_CHAIN_STANDARD")
prev_pairing = get_value(prev_14_1, "MIGRATION_PAIRING_STATUS")
prev_naming = get_value(prev_14_1, "MIGRATION_NAMING_STATUS")

detail(f"PREVIOUS_14_1_FINAL_STATUS={prev_status}")
detail(f"PREVIOUS_14_1_MIGRATION_CHAIN_STANDARD={prev_chain}")
detail(f"PREVIOUS_14_1_MIGRATION_PAIRING_STATUS={prev_pairing}")
detail(f"PREVIOUS_14_1_MIGRATION_NAMING_STATUS={prev_naming}")

if prev_status != "PASS":
    fail("14.1 final status PASS degil")
if prev_chain != "PASS":
    fail("14.1 migration chain standard PASS degil")
if prev_pairing != "PASS":
    fail("14.1 migration pairing PASS degil")
if prev_naming != "PASS":
    fail("14.1 migration naming PASS degil")

if not standard_file.exists():
    fail("14.2 standard doc yok")

required_manifest_cols = [
    "seed_key",
    "domain",
    "scope",
    "required_for_pilot",
    "idempotency_strategy",
    "rollback_strategy",
    "tenant_safety",
    "apply_gate_required",
    "note",
]

manifest_header, manifest_rows = parse_tsv(manifest_file)
doc_manifest_header, doc_manifest_rows = parse_tsv(doc_manifest_file)
scope_header, scope_rows = parse_tsv(scope_file)

detail(f"REFERENCE_SEED_MANIFEST_FILE_EXISTS={'YES' if manifest_file.exists() else 'NO'}")
detail(f"REFERENCE_SEED_DOC_MANIFEST_FILE_EXISTS={'YES' if doc_manifest_file.exists() else 'NO'}")
detail(f"REFERENCE_SEED_SCOPE_RULES_FILE_EXISTS={'YES' if scope_file.exists() else 'NO'}")
detail(f"REFERENCE_SEED_MANIFEST_ROW_COUNT={len(manifest_rows)}")
detail(f"REFERENCE_SEED_DOC_MANIFEST_ROW_COUNT={len(doc_manifest_rows)}")
detail(f"REFERENCE_SEED_SCOPE_RULE_ROW_COUNT={len(scope_rows)}")

missing_cols = [col for col in required_manifest_cols if col not in manifest_header]
detail(f"REFERENCE_SEED_MANIFEST_MISSING_COLUMN_COUNT={len(missing_cols)}")

if missing_cols:
    fail("seed manifest kolonlari eksik: " + ",".join(missing_cols))

required_scopes = ["GLOBAL_REFERENCE", "TENANT_DEFAULT", "TENANT_SPECIFIC"]
scope_counts = {scope: count_scope(manifest_rows, scope) for scope in required_scopes}

detail(f"REFERENCE_SEED_GLOBAL_REFERENCE_COUNT={scope_counts['GLOBAL_REFERENCE']}")
detail(f"REFERENCE_SEED_TENANT_DEFAULT_COUNT={scope_counts['TENANT_DEFAULT']}")
detail(f"REFERENCE_SEED_TENANT_SPECIFIC_COUNT={scope_counts['TENANT_SPECIFIC']}")

for scope in required_scopes:
    if scope_counts[scope] < 1:
        fail(f"{scope} seed kaydi yok")

duplicate_seed_keys = has_duplicate(manifest_rows, "seed_key")
detail(f"REFERENCE_SEED_DUPLICATE_KEY_COUNT={len(duplicate_seed_keys)}")
if duplicate_seed_keys:
    fail("duplicate seed key var: " + ",".join(duplicate_seed_keys))

required_seed_keys = [
    "tdhp_chart_of_accounts",
    "tax_vat_rates",
    "document_types",
    "currency_codes",
    "unit_definitions",
    "product_categories",
    "stock_locations",
    "payment_methods",
    "customer_import_seed",
    "product_import_seed",
    "opening_stock_seed",
]

existing_keys = set(row.get("seed_key", "") for row in manifest_rows)
missing_required_keys = [key for key in required_seed_keys if key not in existing_keys]
detail(f"REFERENCE_SEED_REQUIRED_KEY_MISSING_COUNT={len(missing_required_keys)}")
if missing_required_keys:
    fail("zorunlu seed key eksik: " + ",".join(missing_required_keys))

bad_idempotency = [row.get("seed_key", "") for row in manifest_rows if not row.get("idempotency_strategy", "")]
bad_rollback = [row.get("seed_key", "") for row in manifest_rows if not row.get("rollback_strategy", "")]
bad_gate = [row.get("seed_key", "") for row in manifest_rows if row.get("apply_gate_required", "") != "YES"]

detail(f"REFERENCE_SEED_IDEMPOTENCY_MISSING_COUNT={len(bad_idempotency)}")
detail(f"REFERENCE_SEED_ROLLBACK_MISSING_COUNT={len(bad_rollback)}")
detail(f"REFERENCE_SEED_APPLY_GATE_NOT_REQUIRED_COUNT={len(bad_gate)}")

if bad_idempotency:
    fail("idempotency strategy eksik seed var")
if bad_rollback:
    fail("rollback strategy eksik seed var")
if bad_gate:
    fail("apply gate required YES olmayan seed var")

tenant_safety_fail = []
for row in manifest_rows:
    scope = row.get("scope", "")
    safety = row.get("tenant_safety", "")
    key = row.get("seed_key", "")
    if scope == "GLOBAL_REFERENCE" and safety != "no_tenant_id_allowed":
        tenant_safety_fail.append(key)
    if scope in ("TENANT_DEFAULT", "TENANT_SPECIFIC") and safety != "tenant_id_required":
        tenant_safety_fail.append(key)

detail(f"REFERENCE_SEED_TENANT_SAFETY_FAIL_COUNT={len(tenant_safety_fail)}")
if tenant_safety_fail:
    fail("tenant safety kural ihlali var: " + ",".join(tenant_safety_fail))

pilot_required_count = sum(1 for row in manifest_rows if row.get("required_for_pilot") == "YES")
detail(f"REFERENCE_SEED_REQUIRED_FOR_PILOT_COUNT={pilot_required_count}")
if pilot_required_count < 8:
    fail("pilot icin zorunlu seed count 8 altinda")

manifest_status = "PASS" if manifest_file.exists() and not missing_cols and len(manifest_rows) >= 10 else "FAIL"
scope_status = "PASS" if not tenant_safety_fail and all(scope_counts[s] >= 1 for s in required_scopes) else "FAIL"
idempotency_status = "PASS" if not bad_idempotency else "FAIL"
rollback_status = "PASS" if not bad_rollback else "FAIL"
tenant_safety_status = "PASS" if not tenant_safety_fail else "FAIL"
apply_gate_status = "PASS" if not bad_gate else "FAIL"

detail(f"REFERENCE_SEED_MANIFEST_STATUS={manifest_status}")
detail(f"REFERENCE_SEED_SCOPE_STATUS={scope_status}")
detail(f"REFERENCE_SEED_IDEMPOTENCY_STATUS={idempotency_status}")
detail(f"REFERENCE_SEED_ROLLBACK_STATUS={rollback_status}")
detail(f"REFERENCE_SEED_TENANT_SAFETY_STATUS={tenant_safety_status}")
detail(f"REFERENCE_SEED_APPLY_GATE_STATUS={apply_gate_status}")

for name, status in [
    ("manifest", manifest_status),
    ("scope", scope_status),
    ("idempotency", idempotency_status),
    ("rollback", rollback_status),
    ("tenant_safety", tenant_safety_status),
    ("apply_gate", apply_gate_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_14_1\t{prev_status}\tmigration chain prerequisite",
    f"manifest_file\t{manifest_status}\trows={len(manifest_rows)}",
    f"scope_coverage\t{scope_status}\tglobal={scope_counts['GLOBAL_REFERENCE']} tenant_default={scope_counts['TENANT_DEFAULT']} tenant_specific={scope_counts['TENANT_SPECIFIC']}",
    f"required_seed_keys\t{'PASS' if not missing_required_keys else 'FAIL'}\tmissing={len(missing_required_keys)}",
    f"idempotency\t{idempotency_status}\tmissing={len(bad_idempotency)}",
    f"rollback\t{rollback_status}\tmissing={len(bad_rollback)}",
    f"tenant_safety\t{tenant_safety_status}\tfail={len(tenant_safety_fail)}",
    f"apply_gate_required\t{apply_gate_status}\tnot_required={len(bad_gate)}",
    "db_mutation\tNO\tstandard only",
    "seed_apply_executed\tNO\tstandard only",
    "query_text_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"REFERENCE_SEED_MATRIX_LINE_COUNT={len(matrix_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"REFERENCE_SEED_STANDARD={final_status}")
detail(f"FAZ4B_14_2_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 14.2 - Reference Data / Seed Standardı Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"REFERENCE_SEED_STANDARD={final_status}",
    f"FAZ4B_14_2_FINAL_STATUS={final_status}",
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/14_2_reference_seed_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Manifest",
    "MANIFEST_FILE=config/reference-data/seed_manifest.tsv",
    manifest_file.read_text(errors="ignore").rstrip(),
    "",
    "## Scope Rules",
    "SCOPE_RULES_FILE=docs/phase4/14_2_reference_seed_scope_rules.tsv",
    scope_file.read_text(errors="ignore").rstrip(),
    "",
    "## Safety Decision",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "SEED_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
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
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"REFERENCE_SEED_MANIFEST_ROW_COUNT={len(manifest_rows)}")
print(f"REFERENCE_SEED_GLOBAL_REFERENCE_COUNT={scope_counts['GLOBAL_REFERENCE']}")
print(f"REFERENCE_SEED_TENANT_DEFAULT_COUNT={scope_counts['TENANT_DEFAULT']}")
print(f"REFERENCE_SEED_TENANT_SPECIFIC_COUNT={scope_counts['TENANT_SPECIFIC']}")
print(f"REFERENCE_SEED_MANIFEST_STATUS={manifest_status}")
print(f"REFERENCE_SEED_SCOPE_STATUS={scope_status}")
print(f"REFERENCE_SEED_IDEMPOTENCY_STATUS={idempotency_status}")
print(f"REFERENCE_SEED_ROLLBACK_STATUS={rollback_status}")
print(f"REFERENCE_SEED_TENANT_SAFETY_STATUS={tenant_safety_status}")
print("DB_MUTATION=NO")
print("SEED_APPLY_EXECUTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print(f"REFERENCE_SEED_STANDARD={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
