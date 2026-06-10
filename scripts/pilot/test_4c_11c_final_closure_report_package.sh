#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

A_REPORT="reports/pilot/faz4c/4c_11a_final_closure_inventory_report.md"
B_REPORT="reports/pilot/faz4c/4c_11b_pilot_completion_seal_guard_report.md"
GUARD_DOC="docs/pilot/faz4c/4c_11b_pilot_completion_seal_guard.md"

PACKAGE_DOC="docs/pilot/faz4c/4c_11c_faz4c_final_closure_report_package.md"
FINAL_PACKAGE="handoff/pilot/faz4c/uzmanparcaci/package/final_seal/faz4c_final_closure_report_package.md"
SUMMARY_FILE="handoff/pilot/faz4c/uzmanparcaci/package/final_seal/pilot_completion_summary.md"

HANDOFF_MANIFEST="handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md"
READINESS_FILE="handoff/pilot/faz4c/uzmanparcaci/package/readiness_gate.md"

REPORT_FILE="reports/pilot/faz4c/4c_11c_final_closure_report_package_report.md"

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

echo "===== 4C-11C FINAL CLOSURE REPORT PACKAGE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

for f in "$A_REPORT" "$B_REPORT" "$GUARD_DOC" "$HANDOFF_MANIFEST" "$READINESS_FILE"; do
  [ -f "$f" ] || fail "Gerekli dosya yok: $f"
done
pass "Gerekli kaynak dosyalar var"

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

grep -q "4C_11C_READY=YES" "$B_REPORT" || fail "4C-11C ready YES yok"
pass "4C-11C ready YES"

grep -q "HANDOFF_PACKAGE_STATUS=READY" "$HANDOFF_MANIFEST" || fail "Handoff manifest READY degil"
pass "Handoff manifest READY"

grep -q "HANDOFF_PACKAGE_STATUS=READY" "$READINESS_FILE" || fail "Readiness file READY degil"
pass "Readiness file READY"

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

[ "$FOUND_CLOSURE_COUNT" -eq 10 ] || fail "Found closure count 10 degil: $FOUND_CLOSURE_COUNT"
pass "Found closure count 10"

[ "$MISSING_CLOSURE_COUNT" -eq 0 ] || fail "Missing closure count 0 degil: $MISSING_CLOSURE_COUNT"
pass "Missing closure count 0"

[ -f "$PACKAGE_DOC" ] || fail "4C-11C package doc yok"
pass "4C-11C package doc var"

[ -f "$FINAL_PACKAGE" ] || fail "Final closure report package yok"
pass "Final closure report package var"

[ -f "$SUMMARY_FILE" ] || fail "Pilot completion summary yok"
pass "Pilot completion summary var"

grep -q "4C_11C_FINAL_CLOSURE_REPORT_PACKAGE_STATUS=PASS" "$PACKAGE_DOC" || fail "4C-11C status PASS yok"
pass "4C-11C status PASS"

grep -q "4C_11C_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED" "$PACKAGE_DOC" || fail "4C-11C recommendation APPROVED yok"
pass "4C-11C recommendation APPROVED"

grep -q "4C_11C_FINAL_GO_NO_GO_DECISION=GO" "$PACKAGE_DOC" || fail "4C-11C final GO yok"
pass "4C-11C final GO"

grep -q "4C_11C_HANDOFF_PACKAGE_STATUS=READY" "$PACKAGE_DOC" || fail "4C-11C handoff READY yok"
pass "4C-11C handoff READY"

grep -q "4C_11C_FOUND_FINAL_CLOSURE_COUNT=10" "$PACKAGE_DOC" || fail "4C-11C found closure 10 yok"
pass "4C-11C found closure 10"

grep -q "4C_11C_MISSING_FINAL_CLOSURE_COUNT=0" "$PACKAGE_DOC" || fail "4C-11C missing closure 0 yok"
pass "4C-11C missing closure 0"

grep -q "4C_11C_PACKAGE_EVIDENCE_COUNT=12" "$PACKAGE_DOC" || fail "4C-11C evidence count 12 yok"
pass "4C-11C evidence count 12"

grep -q "4C_11C_MISSING_EVIDENCE_COUNT=0" "$PACKAGE_DOC" || fail "4C-11C missing evidence 0 yok"
pass "4C-11C missing evidence 0"

grep -q "4C_11C_CRITICAL_BLOCKER_COUNT=0" "$PACKAGE_DOC" || fail "4C-11C critical blocker 0 yok"
pass "4C-11C critical blocker 0"

grep -q "4C_11C_BLOCKING_ACTION_COUNT=0" "$PACKAGE_DOC" || fail "4C-11C blocking action 0 yok"
pass "4C-11C blocking action 0"

grep -q "4C_11C_DB_WRITE_APPLIED=NO" "$PACKAGE_DOC" || fail "4C-11C DB write NO yok"
pass "4C-11C DB write NO"

grep -q "4C_11D_READY=YES" "$PACKAGE_DOC" || fail "4C-11D ready YES yok"
pass "4C-11D ready YES"

grep -q "FINAL_CLOSURE_REPORT_PACKAGE_STATUS=PASS" "$FINAL_PACKAGE" || fail "Final package PASS yok"
pass "Final package PASS"

grep -q "PILOT_COMPLETION_SUMMARY_STATUS=PASS" "$SUMMARY_FILE" || fail "Completion summary PASS yok"
pass "Completion summary PASS"

grep -q "4C_11D_READY=YES" "$SUMMARY_FILE" || fail "Summary 4C-11D ready YES yok"
pass "Summary 4C-11D ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-11C Final Closure Report Package Report

Step: 4C-11C
Blok: FAZ 4C Final Closure Report Package
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_11C_FINAL_CLOSURE_REPORT_PACKAGE_STATUS=PASS
4C_11C_PREVIOUS_BLOCK_STATUS=PASS
4C_11C_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED
4C_11C_FINAL_GO_NO_GO_DECISION=GO
4C_11C_HANDOFF_PACKAGE_STATUS=READY
4C_11C_REQUIRED_FINAL_CLOSURE_COUNT=10
4C_11C_FOUND_FINAL_CLOSURE_COUNT=$FOUND_CLOSURE_COUNT
4C_11C_MISSING_FINAL_CLOSURE_COUNT=$MISSING_CLOSURE_COUNT
4C_11C_PACKAGE_EVIDENCE_COUNT=12
4C_11C_MISSING_EVIDENCE_COUNT=0
4C_11C_CRITICAL_BLOCKER_COUNT=0
4C_11C_BLOCKING_ACTION_COUNT=0
4C_11C_REPORT_PACKAGE_CREATED=YES
4C_11C_DB_WRITE_APPLIED=NO
4C_11D_READY=YES

## Dosyalar

PACKAGE_DOC=docs/pilot/faz4c/4c_11c_faz4c_final_closure_report_package.md
FINAL_PACKAGE=handoff/pilot/faz4c/uzmanparcaci/package/final_seal/faz4c_final_closure_report_package.md
SUMMARY_FILE=handoff/pilot/faz4c/uzmanparcaci/package/final_seal/pilot_completion_summary.md

## Karar

FAZ 4C final closure report package oluşturuldu.
Completion seal final closure adımına geçilebilir.
DB yazma işlemi yapılmadı.
Sonraki adım: 4C-11D FAZ 4C Pilot Completion Seal Final Closure.

## Sonuc

4C-11C Final Closure Report Package tamamlandı.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-11C TEST SONUCU ====="
echo "4C_11C_FINAL_CLOSURE_REPORT_PACKAGE_STATUS=PASS ✅"
echo "4C_11C_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED ✅"
echo "4C_11C_FINAL_GO_NO_GO_DECISION=GO ✅"
echo "4C_11C_HANDOFF_PACKAGE_STATUS=READY ✅"
echo "4C_11C_FOUND_FINAL_CLOSURE_COUNT=$FOUND_CLOSURE_COUNT ✅"
echo "4C_11C_MISSING_FINAL_CLOSURE_COUNT=$MISSING_CLOSURE_COUNT ✅"
echo "4C_11C_DB_WRITE_APPLIED=NO ✅"
echo "4C_11D_READY=YES ✅"
