#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

APPLY_SCRIPT="scripts/pilot/apply_4c_1_1h_real_business_values.sh"
ENV_FILE="docs/pilot/faz4c/4c_1_1g_real_business_input_template.env"
REPORT_FILE="reports/pilot/faz4c/4c_1_1h_real_business_apply_guard_report.md"

echo "===== 4C-1.1H REAL BUSINESS APPLY GUARD TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$APPLY_SCRIPT" ] || fail "Apply script yok: $APPLY_SCRIPT"
pass "Apply script var"

[ -x "$APPLY_SCRIPT" ] || fail "Apply script executable degil"
pass "Apply script executable"

[ -f "$ENV_FILE" ] || fail "Env template yok: $ENV_FILE"
pass "Env template var"

bash "$APPLY_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "Apply guard report yok: $REPORT_FILE"
pass "Apply guard report var"

grep -q "4C_1_1H_ENV_FILE_FOUND=YES" "$REPORT_FILE" || fail "Env found status yok"
pass "Env found status var"

if grep -q '="PENDING"' "$ENV_FILE"; then
  grep -q "4C_1_1H_APPLY_STATUS=BLOCKED" "$REPORT_FILE" || fail "PENDING varken BLOCKED olmadi"
  grep -q "4C_1_1H_FINAL_CLOSURE_READY=NO" "$REPORT_FILE" || fail "PENDING varken final closure NO olmadi"
  pass "PENDING varken apply dogru sekilde bloklandi"
else
  grep -q "4C_1_1H_APPLY_STATUS=PASS" "$REPORT_FILE" || fail "PENDING yokken PASS olmadi"
  grep -q "4C_1_1H_FINAL_CLOSURE_READY=YES" "$REPORT_FILE" || fail "PENDING yokken final closure YES olmadi"
  pass "Gercek degerler varken apply PASS oldu"
fi

echo
echo "===== 4C-1.1H TEST SONUCU ====="
cat "$REPORT_FILE"

echo
echo "OK ✅ 4C-1.1H apply guard calisti"
