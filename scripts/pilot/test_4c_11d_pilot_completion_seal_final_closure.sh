#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

A_REPORT="reports/pilot/faz4c/4c_11a_final_closure_inventory_report.md"
B_REPORT="reports/pilot/faz4c/4c_11b_pilot_completion_seal_guard_report.md"
C_REPORT="reports/pilot/faz4c/4c_11c_final_closure_report_package_report.md"

FINAL_DOC="docs/pilot/faz4c/4c_11d_faz4c_pilot_completion_seal_final_closure.md"
ALIAS_DOC="docs/pilot/faz4c/4c_11_final_closure.md"
PHASE_FINAL_DOC="docs/pilot/faz4c/faz4c_final_closure.md"

FINAL_PACKAGE="handoff/pilot/faz4c/uzmanparcaci/package/final_seal/faz4c_final_closure_report_package.md"
SUMMARY_FILE="handoff/pilot/faz4c/uzmanparcaci/package/final_seal/pilot_completion_summary.md"
SEAL_FILE="handoff/pilot/faz4c/uzmanparcaci/package/final_seal/pilot_completion_seal.md"

REPORT_FILE="reports/pilot/faz4c/4c_11d_pilot_completion_seal_final_closure_report.md"

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

echo "===== 4C-11D FAZ 4C PILOT COMPLETION SEAL FINAL CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

for f in "$A_REPORT" "$B_REPORT" "$C_REPORT"; do
  [ -f "$f" ] || fail "Eksik report: $f"
done
pass "4C-11A/11B/11C report dosyalari var"

[ -f "$FINAL_DOC" ] || fail "4C-11D final closure doc yok"
pass "4C-11D final closure doc var"

[ -f "$ALIAS_DOC" ] || fail "4C-11 final closure alias doc yok"
pass "4C-11 final closure alias doc var"

[ -f "$PHASE_FINAL_DOC" ] || fail "FAZ 4C final closure doc yok"
pass "FAZ 4C final closure doc var"

[ -f "$FINAL_PACKAGE" ] || fail "Final package yok"
pass "Final package var"

[ -f "$SUMMARY_FILE" ] || fail "Completion summary yok"
pass "Completion summary var"

[ -f "$SEAL_FILE" ] || fail "Pilot completion seal yok"
pass "Pilot completion seal var"

grep -q "4C_11A_FINAL_CLOSURE_INVENTORY_STATUS=PASS" "$A_REPORT" || fail "4C-11A PASS degil"
pass "4C-11A PASS"

grep -q "4C_11A_FOUND_FINAL_CLOSURE_COUNT=10" "$A_REPORT" || fail "4C-11A found closure 10 degil"
pass "4C-11A found closure 10"

grep -q "4C_11A_MISSING_FINAL_CLOSURE_COUNT=0" "$A_REPORT" || fail "4C-11A missing closure 0 degil"
pass "4C-11A missing closure 0"

grep -q "4C_11B_PILOT_COMPLETION_SEAL_GUARD_STATUS=PASS" "$B_REPORT" || fail "4C-11B guard PASS degil"
pass "4C-11B guard PASS"

grep -q "4C_11B_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED" "$B_REPORT" || fail "4C-11B recommendation APPROVED degil"
pass "4C-11B recommendation APPROVED"

grep -q "4C_11B_FINAL_GO_NO_GO_DECISION=GO" "$B_REPORT" || fail "4C-11B final GO degil"
pass "4C-11B final GO"

grep -q "4C_11B_HANDOFF_PACKAGE_STATUS=READY" "$B_REPORT" || fail "4C-11B handoff READY degil"
pass "4C-11B handoff READY"

grep -q "4C_11B_CRITICAL_BLOCKER_COUNT=0" "$B_REPORT" || fail "4C-11B critical blocker 0 degil"
pass "4C-11B critical blocker 0"

grep -q "4C_11B_BLOCKING_ACTION_COUNT=0" "$B_REPORT" || fail "4C-11B blocking action 0 degil"
pass "4C-11B blocking action 0"

grep -q "4C_11C_FINAL_CLOSURE_REPORT_PACKAGE_STATUS=PASS" "$C_REPORT" || fail "4C-11C package PASS degil"
pass "4C-11C package PASS"

grep -q "4C_11C_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED" "$C_REPORT" || fail "4C-11C recommendation APPROVED degil"
pass "4C-11C recommendation APPROVED"

grep -q "4C_11C_FINAL_GO_NO_GO_DECISION=GO" "$C_REPORT" || fail "4C-11C final GO degil"
pass "4C-11C final GO"

grep -q "4C_11C_HANDOFF_PACKAGE_STATUS=READY" "$C_REPORT" || fail "4C-11C handoff READY degil"
pass "4C-11C handoff READY"

grep -q "4C_11C_FOUND_FINAL_CLOSURE_COUNT=10" "$C_REPORT" || fail "4C-11C found closure 10 degil"
pass "4C-11C found closure 10"

grep -q "4C_11C_MISSING_FINAL_CLOSURE_COUNT=0" "$C_REPORT" || fail "4C-11C missing closure 0 degil"
pass "4C-11C missing closure 0"

grep -q "4C_11D_READY=YES" "$C_REPORT" || fail "4C-11D ready YES yok"
pass "4C-11D ready YES"

FOUND_CLOSURE_COUNT=0
MISSING_CLOSURE_COUNT=0

for f in "${REQUIRED_FINAL_CLOSURES[@]}"; do
  if [ -f "$f" ]; then
    echo "OK ✅ Final closure var: $f"
    FOUND_CLOSURE_COUNT=$((FOUND_CLOSURE_COUNT + 1))
  else
    echo "HATA ❌ Final closure eksik: $f"
    MISSING_CLOSURE_COUNT=$((MISSING_CLOSURE_COUNT + 1))
  fi
done

[ "$FOUND_CLOSURE_COUNT" -eq 10 ] || fail "Found final closure count 10 degil: $FOUND_CLOSURE_COUNT"
pass "Found final closure count 10"

[ "$MISSING_CLOSURE_COUNT" -eq 0 ] || fail "Missing final closure count 0 degil: $MISSING_CLOSURE_COUNT"
pass "Missing final closure count 0"

grep -q "4C_11D_PILOT_COMPLETION_SEAL_FINAL_CLOSURE_STATUS=PASS" "$FINAL_DOC" || fail "4C-11D final closure PASS yok"
pass "4C-11D final closure PASS"

grep -q "4C_11_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-11 final status PASS yok"
pass "4C-11 final status PASS"

grep -q "FAZ_4C_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "FAZ 4C final status PASS yok"
pass "FAZ 4C final status PASS"

grep -q "FAZ_4C_PILOT_COMPLETION_STATUS=PASS" "$FINAL_DOC" || fail "FAZ 4C pilot completion PASS yok"
pass "FAZ 4C pilot completion PASS"

grep -q "FAZ_4C_PILOT_COMPLETION_SEAL_STATUS=SEALED" "$FINAL_DOC" || fail "Pilot completion seal SEALED yok"
pass "Pilot completion seal SEALED"

grep -q "FAZ_4C_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED" "$FINAL_DOC" || fail "Seal recommendation APPROVED yok"
pass "Seal recommendation APPROVED"

grep -q "FAZ_4C_FINAL_GO_NO_GO_DECISION=GO" "$FINAL_DOC" || fail "Final GO yok"
pass "Final GO"

grep -q "FAZ_4C_HANDOFF_PACKAGE_STATUS=READY" "$FINAL_DOC" || fail "Handoff READY yok"
pass "Handoff READY"

grep -q "FAZ_4C_FOUND_FINAL_CLOSURE_COUNT=10" "$FINAL_DOC" || fail "Found final closure 10 yok"
pass "Found final closure 10"

grep -q "FAZ_4C_MISSING_FINAL_CLOSURE_COUNT=0" "$FINAL_DOC" || fail "Missing final closure 0 yok"
pass "Missing final closure 0"

grep -q "FAZ_4C_PACKAGE_EVIDENCE_COUNT=12" "$FINAL_DOC" || fail "Package evidence 12 yok"
pass "Package evidence 12"

grep -q "FAZ_4C_MISSING_EVIDENCE_COUNT=0" "$FINAL_DOC" || fail "Missing evidence 0 yok"
pass "Missing evidence 0"

grep -q "FAZ_4C_CRITICAL_BLOCKER_COUNT=0" "$FINAL_DOC" || fail "Critical blocker 0 yok"
pass "Critical blocker 0"

grep -q "FAZ_4C_BLOCKING_ACTION_COUNT=0" "$FINAL_DOC" || fail "Blocking action 0 yok"
pass "Blocking action 0"

grep -q "FAZ_4C_DB_WRITE_APPLIED=NO" "$FINAL_DOC" || fail "DB write NO yok"
pass "DB write NO"

grep -q "FAZ_4D_READY=YES" "$FINAL_DOC" || fail "FAZ 4D ready YES yok"
pass "FAZ 4D ready YES"

grep -q "PILOT_COMPLETION_SEAL_STATUS=SEALED" "$SEAL_FILE" || fail "Seal file SEALED yok"
pass "Seal file SEALED"

grep -q "FAZ_4D_READY=YES" "$SEAL_FILE" || fail "Seal file FAZ 4D ready YES yok"
pass "Seal file FAZ 4D ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-11D Pilot Completion Seal Final Closure Report

Step: 4C-11D
Blok: FAZ 4C Pilot Completion Seal Final Closure
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_11D_PILOT_COMPLETION_SEAL_FINAL_CLOSURE_STATUS=PASS
4C_11_FINAL_STATUS=PASS
FAZ_4C_FINAL_STATUS=PASS
FAZ_4C_PILOT_COMPLETION_STATUS=PASS
FAZ_4C_PILOT_COMPLETION_SEAL_STATUS=SEALED
FAZ_4C_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED
FAZ_4C_FINAL_GO_NO_GO_DECISION=GO
FAZ_4C_HANDOFF_PACKAGE_STATUS=READY
FAZ_4C_REQUIRED_FINAL_CLOSURE_COUNT=10
FAZ_4C_FOUND_FINAL_CLOSURE_COUNT=$FOUND_CLOSURE_COUNT
FAZ_4C_MISSING_FINAL_CLOSURE_COUNT=$MISSING_CLOSURE_COUNT
FAZ_4C_PACKAGE_EVIDENCE_COUNT=12
FAZ_4C_MISSING_EVIDENCE_COUNT=0
FAZ_4C_CRITICAL_BLOCKER_COUNT=0
FAZ_4C_BLOCKING_ACTION_COUNT=0
FAZ_4C_DB_WRITE_APPLIED=NO
FAZ_4D_READY=YES

## Pilot

PILOT_BUSINESS_NAME=uzmanparcaci
TENANT_BUSINESS_CODE=UZMANPARCACI
PILOT_SECTOR=OTO_YEDEK_PARCA

## Dosyalar

FINAL_DOC=docs/pilot/faz4c/4c_11d_faz4c_pilot_completion_seal_final_closure.md
ALIAS_DOC=docs/pilot/faz4c/4c_11_final_closure.md
PHASE_FINAL_DOC=docs/pilot/faz4c/faz4c_final_closure.md
SEAL_FILE=handoff/pilot/faz4c/uzmanparcaci/package/final_seal/pilot_completion_seal.md

## Karar

FAZ 4C gerçek pilot fazı tamamlandı.
Pilot completion seal verildi.
FAZ 4D geçişi açıldı.
DB yazma işlemi yapılmadı.

## Sonuc

FAZ 4C resmi olarak tamamlandı.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-11D TEST SONUCU ====="
echo "4C_11D_PILOT_COMPLETION_SEAL_FINAL_CLOSURE_STATUS=PASS ✅"
echo "4C_11_FINAL_STATUS=PASS ✅"
echo "FAZ_4C_FINAL_STATUS=PASS ✅"
echo "FAZ_4C_PILOT_COMPLETION_SEAL_STATUS=SEALED ✅"
echo "FAZ_4C_FINAL_GO_NO_GO_DECISION=GO ✅"
echo "FAZ_4C_HANDOFF_PACKAGE_STATUS=READY ✅"
echo "FAZ_4C_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "FAZ_4C_BLOCKING_ACTION_COUNT=0 ✅"
echo "FAZ_4D_READY=YES ✅"
