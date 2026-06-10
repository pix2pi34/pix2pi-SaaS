#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz4r/FAZ_4_16_6_4_URUN_KARAR_DEFTERI.md"
CONFIG_FILE="configs/faz4r/faz_4_16_6_4_urun_karar_defteri.v1.json"
DECISION_FILE="configs/faz4r/product_decision_log.controlled_pilot.v1.json"
RUNTIME_SCRIPT="scripts/faz4r/validate_product_decision_log.sh"
TEST_FILE="tests/faz4r/faz_4_16_6_4_urun_karar_defteri_test.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_16_6_4_URUN_KARAR_DEFTERI_REAL_IMPLEMENTATION_AUDIT.md"

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
  local valid_file="/tmp/faz_4_16_6_4_valid_$$.json"
  local invalid_file="/tmp/faz_4_16_6_4_invalid_$$.json"
  local valid_out="/tmp/faz_4_16_6_4_valid_$$.out"
  local invalid_out="/tmp/faz_4_16_6_4_invalid_$$.out"

  extract_fixture "valid_fixture" "$valid_file"
  extract_fixture "invalid_fixture" "$invalid_file"

  if CONFIG_FILE="$CONFIG_FILE" DECISION_FILE="$DECISION_FILE" INPUT_FILE="$DECISION_FILE" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PRODUCT_DECISION_LOG_STATUS=PASS" "$valid_out"; then
      record_pass "main product decision log artifact PASS"
    else
      record_fail "main product decision log artifact PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "main product decision log artifact execution"
    cat "$valid_out" || true
  fi

  if CONFIG_FILE="$CONFIG_FILE" DECISION_FILE="$DECISION_FILE" INPUT_FILE="$valid_file" "$RUNTIME_SCRIPT" > "$valid_out" 2>&1; then
    if grep -Fq "PRODUCT_DECISION_LOG_STATUS=PASS" "$valid_out"; then
      record_pass "valid product decision log fixture PASS"
    else
      record_fail "valid product decision log fixture PASS"
      cat "$valid_out" || true
    fi
  else
    record_fail "valid product decision log fixture execution"
    cat "$valid_out" || true
  fi

  if grep -Fq "PRODUCT_DECISION_LOG_TOTAL_RULE_COUNT=16" "$valid_out"; then
    record_pass "valid decision log total rule count"
  else
    record_fail "valid decision log total rule count"
  fi

  if grep -Fq "PRODUCT_DECISION_LOG_READY_RULE_COUNT=16" "$valid_out"; then
    record_pass "valid decision log ready rule count"
  else
    record_fail "valid decision log ready rule count"
  fi

  if grep -Fq "PRODUCT_DECISION_LOG_MISSING_RULE_COUNT=0" "$valid_out"; then
    record_pass "valid decision log missing rule zero"
  else
    record_fail "valid decision log missing rule zero"
  fi

  if grep -Fq "NO_AUTO_APPLY_DECISION=true" "$valid_out"; then
    record_pass "valid no auto apply decision guard"
  else
    record_fail "valid no auto apply decision guard"
  fi

  if CONFIG_FILE="$CONFIG_FILE" DECISION_FILE="$DECISION_FILE" INPUT_FILE="$invalid_file" "$RUNTIME_SCRIPT" > "$invalid_out" 2>&1; then
    record_fail "invalid product decision log fixture must fail"
    cat "$invalid_out" || true
  else
    if grep -Fq "PRODUCT_DECISION_LOG_STATUS=FAIL" "$invalid_out"; then
      record_pass "invalid product decision log fixture FAIL guard"
    else
      record_fail "invalid product decision log fixture FAIL guard"
      cat "$invalid_out" || true
    fi
  fi

  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=DECISION_LOG_MODE_NOT_CONTROLLED_PILOT" "$invalid_out"; then record_pass "controlled pilot decision log mode guard"; else record_fail "controlled pilot decision log mode guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=CHAIN_DEPENDENCY_NOT_PASS:223_FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI" "$invalid_out"; then record_pass "quick fix lane dependency guard"; else record_fail "quick fix lane dependency guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=REQUIRED_DECISION_RULE_NOT_READY:PRODUCT_DECISION_INTAKE" "$invalid_out"; then record_pass "required decision rule ready guard"; else record_fail "required decision rule ready guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=REQUIRED_EVIDENCE_MISSING:PRODUCT_DECISION_INTAKE" "$invalid_out"; then record_pass "required evidence guard"; else record_fail "required evidence guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=REQUIRED_DECISION_RULES_MISSING" "$invalid_out"; then record_pass "missing required decision rules guard"; else record_fail "missing required decision rules guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=DUPLICATE_DECISION_RULE_CODE_FOUND" "$invalid_out"; then record_pass "duplicate decision rule guard"; else record_fail "duplicate decision rule guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=TOTAL_RULE_COUNT_RECONCILIATION_FAILED" "$invalid_out"; then record_pass "total rule count reconciliation guard"; else record_fail "total rule count reconciliation guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=MISSING_RULE_COUNT_NOT_ZERO" "$invalid_out"; then record_pass "missing rule zero guard"; else record_fail "missing rule zero guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=CRITICAL_ISSUE_COUNT_NOT_ZERO" "$invalid_out"; then record_pass "critical issue zero guard"; else record_fail "critical issue zero guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=OPEN_BLOCKER_COUNT_NOT_ZERO" "$invalid_out"; then record_pass "open blocker zero guard"; else record_fail "open blocker zero guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=DECISION_TYPE_TAXONOMY_STATUS_NOT_READY" "$invalid_out"; then record_pass "decision taxonomy ready guard"; else record_fail "decision taxonomy ready guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=OWNER_ASSIGNMENT_STATUS_NOT_READY" "$invalid_out"; then record_pass "owner assignment ready guard"; else record_fail "owner assignment ready guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=IMPACT_AREA_MAPPING_STATUS_NOT_READY" "$invalid_out"; then record_pass "impact area mapping ready guard"; else record_fail "impact area mapping ready guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=APPROVAL_RECORD_STATUS_NOT_READY" "$invalid_out"; then record_pass "approval record ready guard"; else record_fail "approval record ready guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=CLOSURE_CHECKLIST_STATUS_NOT_READY" "$invalid_out"; then record_pass "closure checklist ready guard"; else record_fail "closure checklist ready guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=AUTO_APPLY_DECISION_NOT_DISABLED" "$invalid_out"; then record_pass "auto apply decision disabled guard"; else record_fail "auto apply decision disabled guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=HOTFIX_DEPLOY_NOT_DISABLED" "$invalid_out"; then record_pass "hotfix deploy disabled guard"; else record_fail "hotfix deploy disabled guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=REAL_ROADMAP_TOOL_NOT_DISABLED" "$invalid_out"; then record_pass "real roadmap tool disabled guard"; else record_fail "real roadmap tool disabled guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=REAL_CRM_SYSTEM_NOT_DISABLED" "$invalid_out"; then record_pass "real CRM system disabled guard"; else record_fail "real CRM system disabled guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=AUTO_APPLY_DECISION_COUNT_NOT_ZERO" "$invalid_out"; then record_pass "auto apply decision count zero guard"; else record_fail "auto apply decision count zero guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=REAL_ROADMAP_TOOL_NOT_CLOSED" "$invalid_out"; then record_pass "real roadmap tool closed guard"; else record_fail "real roadmap tool closed guard"; fi
  if grep -Fq "PRODUCT_DECISION_LOG_FAIL=LIVE_EXTERNAL_PROVIDER_NOT_CLOSED" "$invalid_out"; then record_pass "live external provider closed guard"; else record_fail "live external provider closed guard"; fi

  rm -f "$valid_file" "$invalid_file" "$valid_out" "$invalid_out"
}

{
  echo "===== 224 — FAZ 4-16.6.4 URUN KARAR DEFTERI REAL IMPLEMENTATION AUDIT START ====="

  check_file "doc file exists" "$DOC_FILE"
  check_file "config file exists" "$CONFIG_FILE"
  check_file "product decision log file exists" "$DECISION_FILE"
  check_file "runtime validation script exists" "$RUNTIME_SCRIPT"
  check_executable "runtime validation script executable" "$RUNTIME_SCRIPT"
  check_file "test fixture file exists" "$TEST_FILE"

  check_file "product decision intake doc exists" "docs/faz4r/product_decision_log/product_decision_intake.md"
  check_file "decision taxonomy doc exists" "docs/faz4r/product_decision_log/decision_type_taxonomy.md"
  check_file "approval record doc exists" "docs/faz4r/product_decision_log/approval_record.md"
  check_file "closure checklist doc exists" "docs/faz4r/product_decision_log/closure_checklist.md"

  check_contains "doc phase title marker" "$DOC_FILE" "FAZ 4-16.6.4 Ürün Karar Defteri"
  check_contains "doc decision intake marker" "$DOC_FILE" "Product decision intake"
  check_contains "doc no auto apply marker" "$DOC_FILE" "no_auto_apply_decision = true"
  check_contains "doc no hotfix marker" "$DOC_FILE" "no_hotfix_deploy = true"
  check_contains "doc closed policy marker" "$DOC_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "config phase marker" "$CONFIG_FILE" "\"phase\": \"FAZ_4_R\""
  check_contains "config phase no marker" "$CONFIG_FILE" "\"phase_no\": 224"
  check_contains "config dependency 223 marker" "$CONFIG_FILE" "223_FAZ_4_16_6_3_HIZLI_DUZELTME_HATTI"
  check_contains "config controlled pilot marker" "$CONFIG_FILE" "\"decision_log_mode_required\": \"CONTROLLED_PILOT\""
  check_contains "config required rule marker" "$CONFIG_FILE" "\"required_rule_status_required\": \"READY\""
  check_contains "config missing rule zero marker" "$CONFIG_FILE" "\"missing_rule_count_required\": 0"
  check_contains "config taxonomy ready marker" "$CONFIG_FILE" "\"decision_type_taxonomy_status_required\": \"READY\""
  check_contains "config no auto apply marker" "$CONFIG_FILE" "\"no_auto_apply_decision_required\": true"
  check_contains "config no roadmap marker" "$CONFIG_FILE" "\"no_real_roadmap_tool_required\": true"
  check_contains "config clear before audit marker" "$CONFIG_FILE" "\"clear_before_test_or_audit\": true"
  check_contains "config closed policy marker" "$CONFIG_FILE" "\"live_external_policy_status_required\": \"CLOSED\""

  check_contains "decision log status ready marker" "$DECISION_FILE" "\"decision_log_status\": \"READY\""
  check_contains "decision log controlled pilot marker" "$DECISION_FILE" "\"decision_log_mode\": \"CONTROLLED_PILOT\""
  check_contains "decision intake marker" "$DECISION_FILE" "PRODUCT_DECISION_INTAKE"
  check_contains "decision taxonomy marker" "$DECISION_FILE" "DECISION_TYPE_TAXONOMY"
  check_contains "decision owner marker" "$DECISION_FILE" "DECISION_OWNER_ASSIGNMENT"
  check_contains "decision impact marker" "$DECISION_FILE" "IMPACT_AREA_MAPPING"
  check_contains "decision accepted marker" "$DECISION_FILE" "ACCEPTED_DECISION_MARKER"
  check_contains "decision rejected marker" "$DECISION_FILE" "REJECTED_DECISION_MARKER"
  check_contains "decision deferred marker" "$DECISION_FILE" "DEFERRED_DECISION_MARKER"
  check_contains "decision quick fix marker" "$DECISION_FILE" "QUICK_FIX_LINK"
  check_contains "decision approval marker" "$DECISION_FILE" "APPROVAL_RECORD"
  check_contains "decision no auto apply marker" "$DECISION_FILE" "\"no_auto_apply_decision\": true"
  check_contains "decision closed policy reference marker" "$DECISION_FILE" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "runtime config guard marker" "$RUNTIME_SCRIPT" "CONFIG_FILE_NOT_FOUND"
  check_contains "runtime decision file guard marker" "$RUNTIME_SCRIPT" "DECISION_FILE_NOT_FOUND"
  check_contains "runtime controlled pilot guard marker" "$RUNTIME_SCRIPT" "DECISION_LOG_MODE_NOT_CONTROLLED_PILOT"
  check_contains "runtime dependency guard marker" "$RUNTIME_SCRIPT" "CHAIN_DEPENDENCY_NOT_PASS"
  check_contains "runtime required rule guard marker" "$RUNTIME_SCRIPT" "REQUIRED_DECISION_RULE_NOT_READY"
  check_contains "runtime evidence guard marker" "$RUNTIME_SCRIPT" "REQUIRED_EVIDENCE_MISSING"
  check_contains "runtime duplicate guard marker" "$RUNTIME_SCRIPT" "DUPLICATE_DECISION_RULE_CODE_FOUND"
  check_contains "runtime reconciliation guard marker" "$RUNTIME_SCRIPT" "TOTAL_RULE_COUNT_RECONCILIATION_FAILED"
  check_contains "runtime taxonomy guard marker" "$RUNTIME_SCRIPT" "DECISION_TYPE_TAXONOMY_STATUS_NOT_READY"
  check_contains "runtime no auto apply guard marker" "$RUNTIME_SCRIPT" "AUTO_APPLY_DECISION_NOT_DISABLED"
  check_contains "runtime roadmap disabled guard marker" "$RUNTIME_SCRIPT" "REAL_ROADMAP_TOOL_NOT_DISABLED"
  check_contains "runtime pass marker" "$RUNTIME_SCRIPT" "PRODUCT_DECISION_LOG_STATUS=PASS"
  check_contains "runtime fail marker" "$RUNTIME_SCRIPT" "PRODUCT_DECISION_LOG_STATUS=FAIL"

  check_contains "test valid fixture marker" "$TEST_FILE" "\"valid_fixture\""
  check_contains "test invalid fixture marker" "$TEST_FILE" "\"invalid_fixture\""
  check_contains "test decision rules marker" "$TEST_FILE" "\"decision_rules\""
  check_contains "test decision controls marker" "$TEST_FILE" "\"decision_controls\""
  check_contains "test decision metrics marker" "$TEST_FILE" "\"decision_metrics\""
  check_contains "test summary marker" "$TEST_FILE" "\"summary\""
  check_contains "test external policy marker" "$TEST_FILE" "\"external_policy\""

  run_fixture_tests

  echo "===== 224 — FAZ 4-16.6.4 URUN KARAR DEFTERI COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_DOC_STATUS=READY"
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_CONFIG_STATUS=READY"
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_ARTIFACT_STATUS=READY"
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_RUNTIME_STATUS=READY"
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_TEST_STATUS=PASS"
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_REAL_IMPLEMENTATION_STATUS=PASS"
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_FINAL_STATUS=PASS"
    echo "FAZ_4_16_6_5_READY=YES"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_TEST_STATUS=FAIL"
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_REAL_IMPLEMENTATION_STATUS=FAIL"
    echo "FAZ_4_16_6_4_URUN_KARAR_DEFTERI_FINAL_STATUS=FAIL"
    echo "FAZ_4_16_6_5_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
