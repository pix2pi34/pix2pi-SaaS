#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_10e_pilot_handoff_final_closure_report.md"
PREV_DOC="docs/pilot/faz4c/4c_10_final_closure.md"

MAIN_DOC="docs/pilot/faz4c/4c_11_faz4c_final_closure_pilot_completion_seal.md"
PLAN_DOC="docs/pilot/faz4c/4c_11a_final_closure_inventory_seal_criteria.md"
CRITERIA_ENV="docs/pilot/faz4c/4c_11a_completion_seal_criteria.env"

HANDOFF_MANIFEST="handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md"
READINESS_FILE="handoff/pilot/faz4c/uzmanparcaci/package/readiness_gate.md"

REPORT_FILE="reports/pilot/faz4c/4c_11a_final_closure_inventory_report.md"

REQUIRED_FINAL_CLOSURES=(
  "docs/pilot/faz4c/4c_1_final_closure.md"
  "docs/pilot/faz4c/4c_2_final_closure.md"
  "docs/pilot/faz4c/4c_3_final_closure.md"
  "docs/pilot/faz4c/4c_4_final_closure.md"
  "docs/pilot/faz4c/4c_5_final_closure.md"
  "docs/pilot/faz4c/4c_6_final_closure.md"
  "docs/pilot/faz4c/4c_7_final_closure.md"
  "docs/pilot/faz4c/4c_8_final_closure.md"
  "docs/pilot/faz4c/4c_9_final_closure.md"
  "docs/pilot/faz4c/4c_10_final_closure.md"
)

echo "===== 4C-11A FINAL CLOSURE INVENTORY / SEAL CRITERIA TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-10E report yok: $PREV_REPORT"
pass "4C-10E report var"

[ -f "$PREV_DOC" ] || fail "4C-10 final closure doc yok: $PREV_DOC"
pass "4C-10 final closure doc var"

grep -q "4C_10_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-10 final PASS degil"
pass "4C-10 final PASS"

grep -q "4C_10_PILOT_HANDOFF_EVIDENCE_PACKAGE_STATUS=PASS" "$PREV_REPORT" || fail "4C-10 handoff evidence PASS degil"
pass "4C-10 handoff evidence PASS"

grep -q "4C_10_HANDOFF_PACKAGE_STATUS=READY" "$PREV_REPORT" || fail "4C-10 package READY degil"
pass "4C-10 package READY"

grep -q "4C_10_PACKAGE_EVIDENCE_COUNT=12" "$PREV_REPORT" || fail "4C-10 package evidence count 12 degil"
pass "4C-10 package evidence count 12"

grep -q "4C_10_MISSING_EVIDENCE_COUNT=0" "$PREV_REPORT" || fail "4C-10 missing evidence 0 degil"
pass "4C-10 missing evidence 0"

grep -q "4C_10_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "4C-10 DB write NO degil"
pass "4C-10 DB write NO"

grep -q "4C_11_READY=YES" "$PREV_REPORT" || fail "4C-11 ready YES yok"
pass "4C-11 ready YES"

[ -f "$MAIN_DOC" ] || fail "4C-11 main doc yok"
pass "4C-11 main doc var"

[ -f "$PLAN_DOC" ] || fail "4C-11A plan doc yok"
pass "4C-11A plan doc var"

[ -f "$CRITERIA_ENV" ] || fail "4C-11A criteria env yok"
pass "4C-11A criteria env var"

[ -f "$HANDOFF_MANIFEST" ] || fail "Handoff manifest yok"
pass "Handoff manifest var"

[ -f "$READINESS_FILE" ] || fail "Readiness file yok"
pass "Readiness file var"

grep -q "HANDOFF_PACKAGE_STATUS=READY" "$HANDOFF_MANIFEST" || fail "Handoff manifest READY degil"
pass "Handoff manifest READY"

grep -q "HANDOFF_PACKAGE_STATUS=READY" "$READINESS_FILE" || fail "Readiness file READY degil"
pass "Readiness file READY"

FOUND_COUNT=0
MISSING_COUNT=0

for f in "${REQUIRED_FINAL_CLOSURES[@]}"; do
  if [ -f "$f" ]; then
    echo "OK ✅ Final closure var: $f"
    FOUND_COUNT=$((FOUND_COUNT + 1))
  else
    echo "HATA ❌ Final closure eksik: $f"
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done

[ "$FOUND_COUNT" -eq 10 ] || fail "Found final closure count 10 degil: $FOUND_COUNT"
pass "Found final closure count 10"

[ "$MISSING_COUNT" -eq 0 ] || fail "Missing final closure count 0 degil: $MISSING_COUNT"
pass "Missing final closure count 0"

grep -q "4C_11A_FINAL_CLOSURE_INVENTORY_STATUS=PASS" "$PLAN_DOC" || fail "4C-11A status PASS yok"
pass "4C-11A status PASS"

grep -q "4C_11A_REQUIRED_FINAL_CLOSURE_COUNT=10" "$PLAN_DOC" || fail "Required final closure count 10 yok"
pass "Required final closure count 10"

grep -q "4C_11A_FOUND_FINAL_CLOSURE_COUNT=10" "$PLAN_DOC" || fail "Found final closure count 10 yok"
pass "Found final closure count 10 dokumanda var"

grep -q "4C_11A_MISSING_FINAL_CLOSURE_COUNT=0" "$PLAN_DOC" || fail "Missing final closure count 0 yok"
pass "Missing final closure count 0 dokumanda var"

grep -q "4C_11A_COMPLETION_SEAL_CRITERIA_STATUS=FROZEN" "$PLAN_DOC" || fail "Completion seal criteria FROZEN yok"
pass "Completion seal criteria FROZEN"

grep -q "4C_11A_FINAL_GO_NO_GO_DECISION=GO" "$PLAN_DOC" || fail "Final GO yok"
pass "Final GO"

grep -q "4C_11A_HANDOFF_PACKAGE_STATUS=READY" "$PLAN_DOC" || fail "Handoff package READY yok"
pass "Handoff package READY"

grep -q "4C_11A_CRITICAL_BLOCKER_COUNT=0" "$PLAN_DOC" || fail "Critical blocker count 0 yok"
pass "Critical blocker count 0"

grep -q "4C_11A_BLOCKING_ACTION_COUNT=0" "$PLAN_DOC" || fail "Blocking action count 0 yok"
pass "Blocking action count 0"

grep -q "4C_11A_DB_WRITE_APPLIED=NO" "$PLAN_DOC" || fail "DB write NO yok"
pass "DB write NO"

grep -q "4C_11B_READY=YES" "$PLAN_DOC" || fail "4C-11B ready YES yok"
pass "4C-11B ready YES"

grep -q '^FINAL_GO_NO_GO_DECISION="GO"' "$CRITERIA_ENV" || fail "Criteria env final GO degil"
pass "Criteria env final GO"

grep -q '^HANDOFF_PACKAGE_STATUS="READY"' "$CRITERIA_ENV" || fail "Criteria env handoff READY degil"
pass "Criteria env handoff READY"

grep -q '^MISSING_FINAL_CLOSURE_COUNT="0"' "$CRITERIA_ENV" || fail "Criteria env missing closure 0 degil"
pass "Criteria env missing closure 0"

grep -q '^CRITICAL_BLOCKER_COUNT="0"' "$CRITERIA_ENV" || fail "Criteria env critical blocker 0 degil"
pass "Criteria env critical blocker 0"

grep -q '^BLOCKING_ACTION_COUNT="0"' "$CRITERIA_ENV" || fail "Criteria env blocking action 0 degil"
pass "Criteria env blocking action 0"

grep -q '^4C_11B_READY="YES"' "$CRITERIA_ENV" || fail "Criteria env 4C-11B ready YES degil"
pass "Criteria env 4C-11B ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-11A Final Closure Inventory / Seal Criteria Report

Step: 4C-11A
Blok: Final Closure Inventory / Seal Criteria Freeze
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_11A_FINAL_CLOSURE_INVENTORY_STATUS=PASS
4C_11A_PREVIOUS_BLOCK_STATUS=PASS
4C_11A_REQUIRED_FINAL_CLOSURE_COUNT=10
4C_11A_FOUND_FINAL_CLOSURE_COUNT=$FOUND_COUNT
4C_11A_MISSING_FINAL_CLOSURE_COUNT=$MISSING_COUNT
4C_11A_COMPLETION_SEAL_CRITERIA_STATUS=FROZEN
4C_11A_FINAL_GO_NO_GO_DECISION=GO
4C_11A_HANDOFF_PACKAGE_STATUS=READY
4C_11A_CRITICAL_BLOCKER_COUNT=0
4C_11A_BLOCKING_ACTION_COUNT=0
4C_11A_DB_WRITE_APPLIED=NO
4C_11B_READY=YES

## Dosyalar

MAIN_DOC=docs/pilot/faz4c/4c_11_faz4c_final_closure_pilot_completion_seal.md
PLAN_DOC=docs/pilot/faz4c/4c_11a_final_closure_inventory_seal_criteria.md
CRITERIA_ENV=docs/pilot/faz4c/4c_11a_completion_seal_criteria.env

## Karar

FAZ 4C final closure inventory tamamlandi.
10 ana blok final closure dosyasi bulundu.
Completion seal kriterleri donduruldu.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-11B Pilot Completion Seal Guard.

## Sonuc

4C-11A Final Closure Inventory / Seal Criteria Freeze tamamlandi.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-11A TEST SONUCU ====="
echo "4C_11A_FINAL_CLOSURE_INVENTORY_STATUS=PASS ✅"
echo "4C_11A_REQUIRED_FINAL_CLOSURE_COUNT=10 ✅"
echo "4C_11A_FOUND_FINAL_CLOSURE_COUNT=$FOUND_COUNT ✅"
echo "4C_11A_MISSING_FINAL_CLOSURE_COUNT=$MISSING_COUNT ✅"
echo "4C_11A_COMPLETION_SEAL_CRITERIA_STATUS=FROZEN ✅"
echo "4C_11A_DB_WRITE_APPLIED=NO ✅"
echo "4C_11B_READY=YES ✅"
