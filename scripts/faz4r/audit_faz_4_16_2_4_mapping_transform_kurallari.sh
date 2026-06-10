#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_2_4_mapping_transform_kurallari.v1.json"
RULES_FILE="configs/faz4r/mapping_transform_rules.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_mapping_transform_rules.sh"
TEST_FILE="tests/faz4r/faz_4_16_2_4_mapping_transform_kurallari_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_REAL_IMPLEMENTATION_AUDIT.md"

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

extract_fixture() {
  local fixture_name="$1"
  local output_file="$2"

  python3 - "$TEST_FILE" "$fixture_name" "$output_file" <<'PY_EOF'
import json
import sys
from pathlib import Path

test_file = Path(sys.argv[1])
fixture_name = sys.argv[2]
output_file = Path(sys.argv[3])

payload = json.loads(test_file.read_text())
output_file.write_text(json.dumps(payload[fixture_name], ensure_ascii=False, indent=2))
PY_EOF
}

run_fixture_tests() {
  local valid_file="/tmp/faz_4_16_2_4_valid_fixture_$$.json"
  local invalid_file="/tmp/faz_4_16_2_4_invalid_fixture_$$.json"
  local duplicate_rules_file="/tmp/faz_4_16_2_4_duplicate_rules_$$.json"
  local missing_transform_rules_file="/tmp/faz_4_16_2_4_missing_transform_rules_$$.json"
  local valid_out="/tmp/faz_4_16_2_4_valid_fixture_$$.out"
  local invalid_out="/tmp/faz_4_16_2_4_invalid_fixture_$$.out"
  local duplicate_out="/tmp/faz_4_16_2_4_duplicate_rules_$$.out"
  local missing_transform_out="/tmp/faz_4_16_2_4_missing_transform_rules_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"
  extract_fixture "duplicate_target_rules_fixture" "$duplicate_rules_file"
  extract_fixture "missing_transform_rules_fixture" "$missing_transform_rules_file"

  if CONFIG_FILE="$CONFIG_FILE" RULES_FILE="$RULES_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "MAPPING_TRANSFORM_STATUS=PASS" "$valid_out"; then
      record_pass "valid mapping transform fixture PASS"
    else
      record_fail "valid mapping transform fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid mapping transform fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "MAPPING_TRANSFORM_PREVIEW_STATUS=MATCHED" "$valid_out"; then
    record_pass "mapping transform preview matched"
  else
    record_fail "mapping transform preview matched"
  fi

  if CONFIG_FILE="$CONFIG_FILE" RULES_FILE="$RULES_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid mapping transform fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "MAPPING_TRANSFORM_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid mapping transform fixture FAIL guard"
    else
      record_fail "invalid mapping transform fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "MAPPING_TRANSFORM_FAIL=TRANSFORM_MODE_NOT_DRY_RUN" "$invalid_out"; then
    record_pass "dry-run required guard"
  else
    record_fail "dry-run required guard"
  fi

  if grep -Fq "MAPPING_TRANSFORM_FAIL=COMMIT_REQUESTED_NOT_ALLOWED" "$invalid_out"; then
    record_pass "commit forbidden guard"
  else
    record_fail "commit forbidden guard"
  fi

  if grep -Fq "MAPPING_TRANSFORM_FAIL=ROW_1_UNKNOWN_SOURCE_FIELD:Bilinmeyen Alan" "$invalid_out"; then
    record_pass "unknown source field guard"
  else
    record_fail "unknown source field guard"
  fi

  if grep -Fq "MAPPING_TRANSFORM_FAIL=ROW_1_TRANSFORM_FAILED:customer_type" "$invalid_out"; then
    record_pass "enum transform failure guard"
  else
    record_fail "enum transform failure guard"
  fi

  if grep -Fq "MAPPING_TRANSFORM_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then
    record_pass "closed external provider mapping guard"
  else
    record_fail "closed external provider mapping guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" RULES_FILE="$duplicate_rules_file" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$duplicate_out" 2>&1; then
    record_fail "duplicate target rules fixture must fail"
    cat "$duplicate_out" || true
  else
    if grep -Fq "MAPPING_TRANSFORM_FAIL=DUPLICATE_TARGET_FIELD:customer_code" "$duplicate_out"; then
      record_pass "duplicate target field guard"
    else
      record_fail "duplicate target field guard"
      cat "$duplicate_out" || true
    fi
  fi

  if CONFIG_FILE="$CONFIG_FILE" RULES_FILE="$missing_transform_rules_file" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$missing_transform_out" 2>&1; then
    record_fail "missing transform rules fixture must fail"
    cat "$missing_transform_out" || true
  else
    if grep -Fq "MAPPING_TRANSFORM_FAIL=REQUIRED_TRANSFORM_MISSING:customer_code" "$missing_transform_out"; then
      record_pass "required transform missing guard"
    else
      record_fail "required transform missing guard"
      cat "$missing_transform_out" || true
    fi
  fi

  rm -f "$valid_file" "$invalid_file" "$duplicate_rules_file" "$missing_transform_rules_file" "$valid_out" "$invalid_out" "$duplicate_out" "$missing_transform_out"
}

{
  echo "===== 201 — FAZ 4-16.2.4 MAPPING / TRANSFORM KURALLARI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "rules file exists" "$RULES_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.2.4 Mapping / Transform Kuralları"
  check_contains "doc supported customer marker" "$DOC_FILE" "CUSTOMER"
  check_contains "doc dry-run marker" "$DOC_FILE" "transform_mode = DRY_RUN"
  check_contains "doc unknown field marker" "$DOC_FILE" "unknown source field"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 201"
  check_contains "config priority group marker" "$CONFIG_FILE" "LVL17 Pilot / UAT / Onboarding"
  check_contains "config dependency 198 marker" "$CONFIG_FILE" "198_FAZ_4_16_2_1_CARI_IMPORT"
  check_contains "config dependency 199 marker" "$CONFIG_FILE" "199_FAZ_4_16_2_2_URUN_STOK_IMPORT"
  check_contains "config dependency 200 marker" "$CONFIG_FILE" "200_FAZ_4_16_2_3_FIS_HAREKET_IMPORT"
  check_contains "config dry-run marker" "$CONFIG_FILE" "\"transform_mode_required\": \"DRY_RUN\""
  check_contains "config commit forbidden marker" "$CONFIG_FILE" "\"commit_allowed\": false"
  check_contains "config unknown source guard marker" "$CONFIG_FILE" "\"unknown_source_field_forbidden\": true"
  check_contains "config duplicate target guard marker" "$CONFIG_FILE" "\"duplicate_target_field_forbidden\": true"
  check_contains "config required transform guard marker" "$CONFIG_FILE" "\"required_transform_missing_forbidden\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config status policy marker" "$CONFIG_FILE" "\"status_policy\": \"COUNTER_BASED_FINAL_STATUS_ONLY\""
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "rules status ready marker" "$RULES_FILE" "\"rule_set_status\": \"READY\""
  check_contains "rules dry-run marker" "$RULES_FILE" "\"transform_mode\": \"DRY_RUN\""
  check_contains "rules customer marker" "$RULES_FILE" "\"CUSTOMER\""
  check_contains "rules product stock marker" "$RULES_FILE" "\"PRODUCT_STOCK\""
  check_contains "rules receipt movement marker" "$RULES_FILE" "\"RECEIPT_MOVEMENT\""
  check_contains "rules trim transform marker" "$RULES_FILE" "trim_string"
  check_contains "rules uppercase transform marker" "$RULES_FILE" "uppercase_code"
  check_contains "rules enum transform marker" "$RULES_FILE" "normalize_enum"
  check_contains "rules date transform marker" "$RULES_FILE" "normalize_date"
  check_contains "rules decimal transform marker" "$RULES_FILE" "parse_decimal"
  check_contains "rules closed policy marker" "$RULES_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime rules guard marker" "$RUNTIME_SCRIPT" "RULES_FILE_NOT_FOUND"
  check_contains "runtime dry-run guard marker" "$RUNTIME_SCRIPT" "TRANSFORM_MODE_NOT_DRY_RUN"
  check_contains "runtime commit guard marker" "$RUNTIME_SCRIPT" "COMMIT_REQUESTED_NOT_ALLOWED"
  check_contains "runtime unknown source guard marker" "$RUNTIME_SCRIPT" "UNKNOWN_SOURCE_FIELD"
  check_contains "runtime duplicate target guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_TARGET_FIELD"
  check_contains "runtime required transform guard marker" "$RUNTIME_SCRIPT" "REQUIRED_TRANSFORM_MISSING"
  check_contains "runtime preview mismatch marker" "$RUNTIME_SCRIPT" "TRANSFORM_PREVIEW_MISMATCH"
  check_contains "runtime closed external marker" "$RUNTIME_SCRIPT" "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "MAPPING_TRANSFORM_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "MAPPING_TRANSFORM_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test duplicate target fixture marker" "$TEST_FILE" "\"duplicate_target_rules_fixture\""
  check_contains "test missing transform fixture marker" "$TEST_FILE" "\"missing_transform_rules_fixture\""
  check_contains "test expected preview marker" "$TEST_FILE" "\"expected_preview\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 201 — FAZ 4-16.2.4 MAPPING / TRANSFORM KURALLARI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_DOC_STATUS=READY"
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_RULES_STATUS=READY"
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_TEST_STATUS=PASS"
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_2_5_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_2_4_MAPPING_TRANSFORM_KURALLARI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_2_5_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
