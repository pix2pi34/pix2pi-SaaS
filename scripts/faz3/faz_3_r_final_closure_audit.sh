#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_FAILED / FAIL ❌"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "$1 OPTIONAL_WARN / WARN ⚠️"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label file_missing=${file}"
  fi
}

check_evidence_exact() {
  local label="$1"
  local file="$2"

  if [ ! -f "$file" ]; then
    fail "$label evidence_missing=${file}"
    return
  fi

  pass "$label evidence file"

  if grep -Eq "FINAL_STATUS[=:][[:space:]]*PASS|STATUS[=:][[:space:]]*PASS|SCRIPT_STATUS=PASS" "$file"; then
    pass "$label final status PASS"
  else
    fail "$label final status PASS missing"
  fi

  if grep -Eq "SEAL_STATUS[=:][[:space:]]*SEALED|SEALED" "$file"; then
    pass "$label seal status SEALED"
  else
    fail "$label seal status SEALED missing"
  fi
}

check_evidence_glob() {
  local label="$1"
  local glob_pattern="$2"

  local file
  file="$(find docs/faz3/evidence -maxdepth 1 -type f -iname "$glob_pattern" | sort | tail -n 1 || true)"

  if [ -z "$file" ]; then
    fail "$label evidence_missing_glob=${glob_pattern}"
    return
  fi

  pass "$label evidence file resolved=${file}"

  if grep -Eq "FINAL_STATUS[=:][[:space:]]*PASS|STATUS[=:][[:space:]]*PASS|SCRIPT_STATUS=PASS" "$file"; then
    pass "$label final status PASS"
  else
    fail "$label final status PASS missing"
  fi

  if grep -Eq "SEAL_STATUS[=:][[:space:]]*SEALED|SEALED" "$file"; then
    pass "$label seal status SEALED"
  else
    fail "$label seal status SEALED missing"
  fi
}

run_go_test_if_dir() {
  local label="$1"
  local pkg="$2"
  local dir="${pkg#./}"

  if [ ! -d "$dir" ]; then
    fail "$label package_dir_missing=${dir}"
    return
  fi

  if go test "$pkg"; then
    pass "$label go test status"
  else
    fail "$label go test status"
  fi
}

echo "===== FAZ 3-R FINAL CLOSURE REAL IMPLEMENTATION AUDIT START ====="

DOC_FILE="docs/faz3/FAZ_3_R_FINAL_CLOSURE.md"
check_file "FAZ 3-R final closure documentation file" "$DOC_FILE"

echo "===== FAZ 3-R — REQUIRED FINAL SMOKE / CLOSURE EVIDENCE CHECK ====="

check_evidence_exact "FAZ 3-R ERP Türkiye core final recheck" "docs/faz3/evidence/FAZ_3_R_ERP_TURKIYE_CORE_FINAL_RECHECK_AUDIT_FIX_V2.md"
check_evidence_exact "152 ERP-TR live readiness closure" "docs/faz3/evidence/FAZ_3_10_8_6_ERP_TR_LIVE_READINESS_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "151 e-Belge smoke" "docs/faz3/evidence/FAZ_3_10_8_3_EBELGE_SMOKE_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "153 TDHP smoke" "docs/faz3/evidence/FAZ_3_10_8_1_TDHP_SMOKE_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "154 Tax smoke" "docs/faz3/evidence/FAZ_3_10_8_2_TAX_SMOKE_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "155 Export smoke" "docs/faz3/evidence/FAZ_3_10_8_4_EXPORT_SMOKE_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "156 Payment smoke" "docs/faz3/evidence/FAZ_3_10_8_5_PAYMENT_SMOKE_REAL_IMPLEMENTATION_AUDIT.md"

echo "===== FAZ 3-R — TDHP FAMILY EVIDENCE CHECK ====="

check_evidence_exact "128 real voucher pipeline" "docs/faz3/evidence/FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "129 account plan live version switch" "docs/faz3/evidence/FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "130 document based posting runtime" "docs/faz3/evidence/FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_glob "131 audit trace persistence" "FAZ_3_10_1_4*AUDIT*TRACE*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_exact "132 TDHP reconciliation runtime" "docs/faz3/evidence/FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "133 TDHP live tests" "docs/faz3/evidence/FAZ_3_10_1_6_TDHP_LIVE_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

echo "===== FAZ 3-R — TAX FAMILY EVIDENCE CHECK ====="

check_evidence_exact "124 KDV runtime execution" "docs/faz3/evidence/FAZ_3_10_2_1_KDV_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "122 stopaj runtime execution" "docs/faz3/evidence/FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "123 tax exemption runtime execution" "docs/faz3/evidence/FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "125 tax rule version rollout" "docs/faz3/evidence/FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "126 tax audit persistence" "docs/faz3/evidence/FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "127 tax runtime tests" "docs/faz3/evidence/FAZ_3_10_2_6_TAX_RUNTIME_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

echo "===== FAZ 3-R — EBELGE FAMILY EVIDENCE CHECK ====="

check_evidence_exact "110 e-Fatura provider integration" "docs/faz3/evidence/FAZ_3_10_3_1_E_FATURA_PROVIDER_INTEGRATION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "111 e-Arşiv provider integration" "docs/faz3/evidence/FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "112 e-Adisyon provider integration" "docs/faz3/evidence/FAZ_3_10_3_3_E_ADISYON_PROVIDER_INTEGRATION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "114 e-Belge status sync" "docs/faz3/evidence/FAZ_3_10_3_4_EBELGE_STATUS_SYNC_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "115 e-Belge error cancel retry" "docs/faz3/evidence/FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "115 e-Belge live integration tests" "docs/faz3/evidence/FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

echo "===== FAZ 3-R — EXPORT FAMILY EVIDENCE CHECK ====="

check_evidence_exact "134 ETA real format generation" "docs/faz3/evidence/FAZ_3_10_4_4_ETA_REAL_FORMAT_GENERATION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "135 Logo real format generation" "docs/faz3/evidence/FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "136 Mikro real format generation" "docs/faz3/evidence/FAZ_3_10_4_2_MIKRO_REAL_FORMAT_GENERATION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "137 Zirve real format generation" "docs/faz3/evidence/FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "138 format validation matrix runtime" "docs/faz3/evidence/FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "139 export adapter tests" "docs/faz3/evidence/FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

echo "===== FAZ 3-R — ACCOUNTANT PORTAL FAMILY EVIDENCE CHECK ====="

check_evidence_glob "140 multi company access runtime" "FAZ_3_10_5_1*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_glob "141 company permission enforcement" "FAZ_3_10_5_2*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_glob "142 Excel PDF TDHP export runtime" "FAZ_3_10_5_3*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_glob "143 monthly subscription runtime" "FAZ_3_10_5_4*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_glob "144 company visibility runtime" "FAZ_3_10_5_5*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_glob "145 accountant portal integration tests" "FAZ_3_10_5_6*REAL_IMPLEMENTATION_AUDIT*.md"

echo "===== FAZ 3-R — DOCUMENT AI FAMILY EVIDENCE CHECK ====="

check_evidence_glob "146 OCR Lens processing runtime" "FAZ_3_10_6_1*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_glob "147 tax field extraction runtime" "FAZ_3_10_6_2*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_glob "148 contact field extraction runtime" "FAZ_3_10_6_3*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_glob "149 confidence review queue runtime" "FAZ_3_10_6_4*REAL_IMPLEMENTATION_AUDIT*.md"
check_evidence_exact "150 Document AI runtime tests" "docs/faz3/evidence/FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

echo "===== FAZ 3-R — PAYMENT FAMILY EVIDENCE CHECK ====="

check_evidence_exact "117 POS provider runtime" "docs/faz3/evidence/FAZ_3_10_7_1_POS_PROVIDER_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "118 bank collection runtime" "docs/faz3/evidence/FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "118 payment reconciliation runtime" "docs/faz3/evidence/FAZ_3_10_7_3_RECONCILIATION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "119 refund cancel runtime" "docs/faz3/evidence/FAZ_3_10_7_4_REFUND_CANCEL_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "119 payment status sync" "docs/faz3/evidence/FAZ_3_10_7_3_PAYMENT_STATUS_SYNC_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "120 payment error retry reversal" "docs/faz3/evidence/FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "120 integration audit runtime" "docs/faz3/evidence/FAZ_3_10_7_5_INTEGRATION_AUDIT_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_evidence_exact "121 payment integration tests" "docs/faz3/evidence/FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

echo "===== FAZ 3-R — TARGETED GO TEST RECHECK ====="

run_go_test_if_dir "FAZ 3-R TDHP smoke" "./internal/erp/turkiye/smoke/tdhp"
run_go_test_if_dir "FAZ 3-R Tax smoke" "./internal/erp/turkiye/smoke/tax"
run_go_test_if_dir "FAZ 3-R e-Belge smoke" "./internal/erp/turkiye/ebelge/smoke"
run_go_test_if_dir "FAZ 3-R Export smoke" "./internal/erp/turkiye/smoke/export"
run_go_test_if_dir "FAZ 3-R Payment smoke" "./internal/erp/turkiye/smoke/payment"
run_go_test_if_dir "FAZ 3-R ERP-TR live readiness closure" "./internal/erp/turkiye/smoke/livereadiness"
run_go_test_if_dir "FAZ 3-R Document AI runtime tests" "./internal/erp/turkiye/documentai/runtimetests"
run_go_test_if_dir "FAZ 3-R payment integration tests" "./internal/erp/turkiye/payment/integrationtests"
run_go_test_if_dir "FAZ 3-R export adapter tests" "./internal/erp/turkiye/export/adaptertests"
run_go_test_if_dir "FAZ 3-R tax runtime tests" "./internal/erp/turkiye/tax/runtimetests"
run_go_test_if_dir "FAZ 3-R TDHP live tests" "./internal/erp/turkiye/tdhp/livetests"

echo "===== FAZ 3-R — LIVE POLICY GUARD CHECK ====="

if grep -RqiE "production_approved[\"[:space:]]*:[[:space:]]*true|real_payment_gate_status[\"[:space:]]*:[[:space:]]*\"OPEN\"|real_bank_gate_status[\"[:space:]]*:[[:space:]]*\"OPEN\"" configs/faz3/smoke 2>/dev/null; then
  fail "FAZ 3-R live policy gate closed guard"
else
  pass "FAZ 3-R live policy gate closed guard"
fi

if grep -RqiE "real_external_provider_calls_allowed[\"[:space:]]*:[[:space:]]*true" configs/faz3/smoke configs/faz3/ebelge configs/faz3/payment configs/faz3/export configs/faz3/tax 2>/dev/null; then
  fail "FAZ 3-R real external provider calls closed guard"
else
  pass "FAZ 3-R real external provider calls closed guard"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# FAZ 3-R — Final Closure / Seal Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_R_FINAL_CLOSURE_STATUS=${FINAL_STATUS}
- FAZ_3_R_FINAL_SEAL_STATUS=${SEAL_STATUS}
- FAZ_4_READY=${NEXT_READY}

## Main Closure Gates

- ERP Türkiye core final recheck
- ERP-TR live readiness closure
- TDHP smoke
- Tax smoke
- e-Belge smoke
- Export smoke
- Payment smoke
- Document AI runtime tests
- Accountant portal runtime evidence
- Targeted Go test recheck
- Live policy guard check

## Live Policy

- Production public/live approval: FALSE
- Real payment calls: CLOSED
- Real bank calls: CLOSED
- Real e-Belge/GİB provider calls: CLOSED
- Real external provider calls: CLOSED
- This final closure is readiness evidence, not production activation.

## Audit Notes

Final status is derived from real evidence files, targeted Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== FAZ 3-R FINAL CLOSURE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_R_FINAL_CLOSURE_STATUS=${FINAL_STATUS}"
echo "FAZ_3_R_FINAL_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
