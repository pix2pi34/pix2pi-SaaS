#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DOC_FILE="docs/pilot/faz4c/4c_1_1f_final_closure_gate.md"
E_DOC="docs/pilot/faz4c/4c_1_1e_real_business_confirmation.md"
E_REPORT="reports/pilot/faz4c/4c_1_1e_real_business_confirmation_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1f_final_closure_gate_report.md"

echo "===== 4C-1.1F FINAL CLOSURE GATE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$DOC_FILE" ] || fail "Final closure gate dokumani yok: $DOC_FILE"
pass "Final closure gate dokumani var"

[ -f "$E_DOC" ] || fail "4C-1.1E confirmation dokumani yok: $E_DOC"
pass "4C-1.1E confirmation dokumani var"

[ -f "$E_REPORT" ] || fail "4C-1.1E report yok: $E_REPORT"
pass "4C-1.1E report var"

grep -q "OTO YEDEK PARÇA" "$DOC_FILE" || fail "Pilot sektor karari yok"
pass "Pilot sektor karari var"

grep -q "FAZ 4D'ye ayrıldı" "$DOC_FILE" || fail "Pazaryeri FAZ 4D karari yok"
pass "Pazaryeri FAZ 4D karari var"

grep -q "4C_1_1F_FINAL_CLOSURE_STATUS=BLOCKED" "$DOC_FILE" || fail "Final closure BLOCKED status yok"
pass "Final closure BLOCKED status var"

grep -q "4C_1_1F_BLOCKER_REASON=REAL_BUSINESS_INFO_MISSING" "$DOC_FILE" || fail "Blocker reason yok"
pass "Blocker reason var"

grep -q "4C_1_1F_NEXT_STEP_READY=NO" "$DOC_FILE" || fail "Next step NO status yok"
pass "Next step NO status var"

grep -q "4C_1_1E_REAL_BUSINESS_VALUES_STATUS=PENDING" "$E_REPORT" || fail "4C-1.1E real business pending reportta yok"
pass "4C-1.1E real business pending status raporda var"

PENDING_COUNT="$(grep -o "\[ PENDING \]" "$E_DOC" | wc -l | tr -d ' ')"

if [ "$PENDING_COUNT" -eq 0 ]; then
  fail "PENDING alan yok; gerçek bilgiler doldurulmuş olabilir, 4C-1.1G gerekir"
fi

pass "Eksik bilgi alanlari tespit edildi: $PENDING_COUNT"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1F Final Closure Gate Report

Step: 4C-1.1F
Blok: Final Closure Gate / Missing Business Info Blocker
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1F_FINAL_GATE_DOC_STATUS=PASS
4C_1_1F_PILOT_PROFILE_STATUS=PASS
4C_1_1F_SCOPE_DECISION_STATUS=PASS
4C_1_1F_REAL_BUSINESS_INFO_STATUS=PENDING
4C_1_1F_PENDING_FIELD_COUNT=$PENDING_COUNT
4C_1_1F_FINAL_CLOSURE_STATUS=BLOCKED
4C_1_1F_BLOCKER_REASON=REAL_BUSINESS_INFO_MISSING
4C_1_1F_NEXT_STEP_READY=NO

## Sonuc

4C-1.1 ana blok henuz tam kapanamaz.
Sebep teknik hata degil; gercek pilot isletme bilgileri eksik.
Gercek isletme bilgileri girildikten sonra 4C-1.1G ile final PASS yapilacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1F TEST SONUCU ====="
echo "4C_1_1F_FINAL_GATE_DOC_STATUS=PASS ✅"
echo "4C_1_1F_PILOT_PROFILE_STATUS=PASS ✅"
echo "4C_1_1F_SCOPE_DECISION_STATUS=PASS ✅"
echo "4C_1_1F_REAL_BUSINESS_INFO_STATUS=PENDING"
echo "4C_1_1F_PENDING_FIELD_COUNT=$PENDING_COUNT"
echo "4C_1_1F_FINAL_CLOSURE_STATUS=BLOCKED"
echo "4C_1_1F_BLOCKER_REASON=REAL_BUSINESS_INFO_MISSING"
echo "4C_1_1F_NEXT_STEP_READY=NO"
