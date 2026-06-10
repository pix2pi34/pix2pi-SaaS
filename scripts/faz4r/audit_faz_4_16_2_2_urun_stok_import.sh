#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_2_2_URUN_STOK_IMPORT.md"
CONFIG_FILE="configs/faz4r/faz_4_16_2_2_urun_stok_import.v1.json"
MAPPING_FILE="configs/faz4r/product_stock_import_mapping.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_product_stock_import.sh"
TEST_FILE="tests/faz4r/faz_4_16_2_2_urun_stok_import_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_2_2_URUN_STOK_IMPORT_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p "docs/faz4r/evidence"

record_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

record_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "$1 REQUIRED_FAIL / FAIL ❌"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_executable() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

run_fixture_tests() {
  local valid_file="/tmp/faz_4_16_2_2_valid_fixture_$$.json"
  local invalid_file="/tmp/faz_4_16_2_2_invalid_fixture_$$.json"
  local valid_out="/tmp/faz_4_16_2_2_valid_fixture_$$.out"
  local invalid_out="/tmp/faz_4_16_2_2_invalid_fixture_$$.out"

  python3 - "$TEST_FILE" "$valid_file" "$invalid_file" <<'PY_EOF'
import json
import sys
from pathlib import Path

test_file = Path(sys.argv[1])
valid_file = Path(sys.argv[2])
invalid_file = Path(sys.argv[3])

payload = json.loads(test_file.read_text())
valid_file.write_text(json.dumps(payload["valid_fixture"], ensure_ascii=False, indent=2))
invalid_file.write_text(json.dumps(payload["invalid_fixture"], ensure_ascii=False, indent=2))
PY_EOF

  if CONFIG_FILE="$CONFIG_FILE" MAPPING_FILE="$MAPPING_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PRODUCT_STOCK_IMPORT_STATUS=PASS" "$valid_out"; then
      record_pass "valid product stock import fixture PASS"
    else
      record_fail "valid product stock import fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid product stock import fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "PRODUCT_IMPORT_TOTAL_ROWS=3" "$valid_out"; then
    record_pass "valid product import row count"
  else
    record_fail "valid product import row count"
  fi

  if grep -Fq "STOCK_IMPORT_TOTAL_ROWS=2" "$valid_out"; then
    record_pass "valid stock import row count"
  else
    record_fail "valid stock import row count"
  fi

  if grep -Fq "PRODUCT_STOCK_IMPORT_TARGET_PRODUCT_STAGING_TABLE=import_staging_products" "$valid_out"; then
    record_pass "product import target staging marker"
  else
    record_fail "product import target staging marker"
  fi

  if grep -Fq "PRODUCT_STOCK_IMPORT_TARGET_STOCK_STAGING_TABLE=import_staging_stock_entries" "$valid_out"; then
    record_pass "stock import target staging marker"
  else
    record_fail "stock import target staging marker"
  fi

  if CONFIG_FILE="$CONFIG_FILE" MAPPING_FILE="$MAPPING_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid product stock import fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "PRODUCT_STOCK_IMPORT_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid product stock import fixture FAIL guard"
    else
      record_fail "invalid product stock import fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "PRODUCT_STOCK_IMPORT_FAIL=IMPORT_MODE_NOT_DRY_RUN" "$invalid_out"; then
    record_pass "dry-run required guard"
  else
    record_fail "dry-run required guard"
  fi

  if grep -Fq "PRODUCT_STOCK_IMPORT_FAIL=COMMIT_REQUESTED_NOT_ALLOWED" "$invalid_out"; then
    record_pass "commit forbidden guard"
  else
    record_fail "commit forbidden guard"
  fi

  if grep -Fq "PRODUCT_STOCK_IMPORT_FAIL=PRODUCT_ROW_2_DUPLICATE_PRODUCT_CODE" "$invalid_out"; then
    record_pass "duplicate product code guard"
  else
    record_fail "duplicate product code guard"
  fi

  if grep -Fq "PRODUCT_STOCK_IMPORT_FAIL=PRODUCT_ROW_2_DUPLICATE_BARCODE" "$invalid_out"; then
    record_pass "duplicate barcode guard"
  else
    record_fail "duplicate barcode guard"
  fi

  if grep -Fq "PRODUCT_STOCK_IMPORT_FAIL=STOCK_ROW_1_UNKNOWN_PRODUCT_CODE" "$invalid_out"; then
    record_pass "unknown stock product guard"
  else
    record_fail "unknown stock product guard"
  fi

  if grep -Fq "PRODUCT_STOCK_IMPORT_FAIL=STOCK_ROW_1_NEGATIVE_STOCK_QUANTITY" "$invalid_out"; then
    record_pass "negative stock quantity guard"
  else
    record_fail "negative stock quantity guard"
  fi

  if grep -Fq "PRODUCT_STOCK_IMPORT_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "closed external provider product stock import guard"
  else
    record_fail "closed external provider product stock import guard"
  fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 199 — FAZ 4-16.2.2 URUN / STOK IMPORT REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "mapping file exists" "$MAPPING_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.2.2 Ürün / Stok Import"
  check_contains "doc product code marker" "$DOC_FILE" "product_code"
  check_contains "doc warehouse marker" "$DOC_FILE" "warehouse_code"
  check_contains "doc dry-run marker" "$DOC_FILE" "import_mode = DRY_RUN"
  check_contains "doc negative stock marker" "$DOC_FILE" "Stok miktarları negatif olmamalıdır"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 199"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 180 marker" "$CONFIG_FILE" "180_FAZ_4_14_3_IMPORT_STAGING_TABLES"
  check_contains "config dependency 198 marker" "$CONFIG_FILE" "198_FAZ_4_16_2_1_CARI_IMPORT"
  check_contains "config dry-run marker" "$CONFIG_FILE" "\"import_mode_required\": \"DRY_RUN\""
  check_contains "config commit forbidden marker" "$CONFIG_FILE" "\"commit_allowed\": false"
  check_contains "config max product count marker" "$CONFIG_FILE" "\"max_product_count\": 5000"
  check_contains "config max stock count marker" "$CONFIG_FILE" "\"max_stock_entry_count\": 20000"
  check_contains "config product staging table marker" "$CONFIG_FILE" "import_staging_products"
  check_contains "config stock staging table marker" "$CONFIG_FILE" "import_staging_stock_entries"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""

  check_contains "mapping status ready marker" "$MAPPING_FILE" "\"mapping_status\": \"READY\""
  check_contains "mapping product staging marker" "$MAPPING_FILE" "import_staging_products"
  check_contains "mapping stock staging marker" "$MAPPING_FILE" "import_staging_stock_entries"
  check_contains "mapping product code marker" "$MAPPING_FILE" "\"source\": \"product_code\""
  check_contains "mapping product name marker" "$MAPPING_FILE" "\"source\": \"product_name\""
  check_contains "mapping barcode marker" "$MAPPING_FILE" "\"source\": \"barcode\""
  check_contains "mapping warehouse marker" "$MAPPING_FILE" "\"source\": \"warehouse_code\""
  check_contains "mapping closed policy marker" "$MAPPING_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime mapping guard marker" "$RUNTIME_SCRIPT" "MAPPING_FILE_NOT_FOUND"
  check_contains "runtime tenant guard marker" "$RUNTIME_SCRIPT" "TENANT_ID_REQUIRED"
  check_contains "runtime dry-run guard marker" "$RUNTIME_SCRIPT" "IMPORT_MODE_NOT_DRY_RUN"
  check_contains "runtime commit guard marker" "$RUNTIME_SCRIPT" "COMMIT_REQUESTED_NOT_ALLOWED"
  check_contains "runtime duplicate product code guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_PRODUCT_CODE"
  check_contains "runtime duplicate barcode guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_BARCODE"
  check_contains "runtime unknown product guard marker" "$RUNTIME_SCRIPT" "UNKNOWN_PRODUCT_CODE"
  check_contains "runtime negative stock guard marker" "$RUNTIME_SCRIPT" "NEGATIVE_STOCK_QUANTITY"
  check_contains "runtime closed external marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "PRODUCT_STOCK_IMPORT_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "PRODUCT_STOCK_IMPORT_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test products marker" "$TEST_FILE" "\"products\""
  check_contains "test stock entries marker" "$TEST_FILE" "\"stock_entries\""
  check_contains "test physical product marker" "$TEST_FILE" "\"product_type\": \"PHYSICAL\""
  check_contains "test service product marker" "$TEST_FILE" "\"product_type\": \"SERVICE\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 199 — FAZ 4-16.2.2 URUN / STOK IMPORT COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_DOC_STATUS=READY"
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_CONFIG_STATUS=READY"
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_MAPPING_STATUS=READY"
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_TEST_STATUS=PASS"
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_FINAL_STATUS=PASS"
    echo "FAZ_4_16_2_3_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_TEST_STATUS=FAIL"
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_2_2_URUN_STOK_IMPORT_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_2_3_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
