#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FINAL_DOC="docs/pilot/faz4c/4c_10e_pilot_handoff_evidence_package_final_closure.md"
ALIAS_DOC="docs/pilot/faz4c/4c_10_final_closure.md"

A_REPORT="reports/pilot/faz4c/4c_10a_evidence_inventory_handoff_plan_report.md"
B_REPORT="reports/pilot/faz4c/4c_10b_evidence_manifest_validation_report.md"
C_REPORT="reports/pilot/faz4c/4c_10c_handoff_package_assembly_report.md"
D_REPORT="reports/pilot/faz4c/4c_10d_handoff_readiness_gate_report.md"

PACKAGE_ROOT="handoff/pilot/faz4c/uzmanparcaci/package"
ASSEMBLY_MANIFEST="$PACKAGE_ROOT/assembly_manifest.md"
READINESS_FILE="$PACKAGE_ROOT/readiness_gate.md"
HANDOFF_MANIFEST="handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md"

REPORT_FILE="reports/pilot/faz4c/4c_10e_pilot_handoff_final_closure_report.md"

echo "===== 4C-10E PILOT HANDOFF / EVIDENCE PACKAGE FINAL CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FINAL_DOC" ] || fail "4C-10E final closure dokumani yok"
pass "4C-10E final closure dokumani var"

[ -f "$ALIAS_DOC" ] || fail "4C-10 final closure alias dokumani yok"
pass "4C-10 final closure alias dokumani var"

for report in "$A_REPORT" "$B_REPORT" "$C_REPORT" "$D_REPORT"; do
  [ -f "$report" ] || fail "Eksik report: $report"
done
pass "4C-10A/10B/10C/10D report dosyalari var"

[ -d "$PACKAGE_ROOT" ] || fail "Package root yok"
pass "Package root var"

[ -f "$ASSEMBLY_MANIFEST" ] || fail "Assembly manifest yok"
pass "Assembly manifest var"

[ -f "$READINESS_FILE" ] || fail "Readiness file yok"
pass "Readiness file var"

[ -f "$HANDOFF_MANIFEST" ] || fail "Handoff manifest yok"
pass "Handoff manifest var"

grep -q "4C_10A_EVIDENCE_INVENTORY_STATUS=PASS" "$A_REPORT" || fail "4C-10A PASS degil"
pass "4C-10A PASS"

grep -q "4C_10A_REQUIRED_EVIDENCE_COUNT=12" "$A_REPORT" || fail "4C-10A required evidence 12 degil"
pass "4C-10A required evidence 12"

grep -q "4C_10A_MISSING_EVIDENCE_COUNT=0" "$A_REPORT" || fail "4C-10A missing evidence 0 degil"
pass "4C-10A missing evidence 0"

grep -q "4C_10B_EVIDENCE_MANIFEST_VALIDATION_STATUS=PASS" "$B_REPORT" || fail "4C-10B PASS degil"
pass "4C-10B PASS"

grep -q "4C_10B_HANDOFF_PACKAGE_STATUS=VALIDATED" "$B_REPORT" || fail "4C-10B package VALIDATED degil"
pass "4C-10B package VALIDATED"

grep -q "4C_10B_FOUND_EVIDENCE_COUNT=12" "$B_REPORT" || fail "4C-10B found evidence 12 degil"
pass "4C-10B found evidence 12"

grep -q "4C_10C_HANDOFF_PACKAGE_ASSEMBLY_STATUS=PASS" "$C_REPORT" || fail "4C-10C PASS degil"
pass "4C-10C PASS"

grep -q "4C_10C_HANDOFF_PACKAGE_STATUS=ASSEMBLED" "$C_REPORT" || fail "4C-10C package ASSEMBLED degil"
pass "4C-10C package ASSEMBLED"

grep -q "4C_10C_COPIED_EVIDENCE_COUNT=12" "$C_REPORT" || fail "4C-10C copied evidence 12 degil"
pass "4C-10C copied evidence 12"

grep -q "4C_10D_HANDOFF_READINESS_GATE_STATUS=PASS" "$D_REPORT" || fail "4C-10D PASS degil"
pass "4C-10D PASS"

grep -q "4C_10D_HANDOFF_PACKAGE_STATUS=READY" "$D_REPORT" || fail "4C-10D package READY degil"
pass "4C-10D package READY"

grep -q "4C_10D_PACKAGE_EVIDENCE_COUNT=12" "$D_REPORT" || fail "4C-10D package evidence 12 degil"
pass "4C-10D package evidence 12"

grep -q "4C_10D_MISSING_PACKAGE_FILE_COUNT=0" "$D_REPORT" || fail "4C-10D missing package file 0 degil"
pass "4C-10D missing package file 0"

grep -q "4C_10D_DB_WRITE_APPLIED=NO" "$D_REPORT" || fail "4C-10D DB write NO degil"
pass "4C-10D DB write NO"

grep -q "4C_10E_READY=YES" "$D_REPORT" || fail "4C-10E ready YES yok"
pass "4C-10E ready YES"

grep -q "HANDOFF_PACKAGE_STATUS=READY" "$READINESS_FILE" || fail "Readiness file package READY degil"
pass "Readiness file package READY"

grep -q "PACKAGE_EVIDENCE_COUNT=12" "$READINESS_FILE" || fail "Readiness file package evidence 12 degil"
pass "Readiness file package evidence 12"

grep -q "MISSING_PACKAGE_FILE_COUNT=0" "$READINESS_FILE" || fail "Readiness file missing count 0 degil"
pass "Readiness file missing count 0"

grep -q "HANDOFF_PACKAGE_STATUS=READY" "$HANDOFF_MANIFEST" || fail "Handoff manifest READY degil"
pass "Handoff manifest READY"

grep -q "4C_10_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-10 final status PASS yok"
pass "4C-10 final status PASS"

grep -q "4C_10_PILOT_HANDOFF_EVIDENCE_PACKAGE_STATUS=PASS" "$FINAL_DOC" || fail "4C-10 handoff evidence status PASS yok"
pass "4C-10 handoff evidence status PASS"

grep -q "4C_10_HANDOFF_PACKAGE_STATUS=READY" "$FINAL_DOC" || fail "4C-10 package READY yok"
pass "4C-10 package READY"

grep -q "4C_10_REQUIRED_EVIDENCE_COUNT=12" "$FINAL_DOC" || fail "4C-10 required evidence 12 yok"
pass "4C-10 required evidence 12"

grep -q "4C_10_PACKAGE_EVIDENCE_COUNT=12" "$FINAL_DOC" || fail "4C-10 package evidence 12 yok"
pass "4C-10 package evidence 12"

grep -q "4C_10_MISSING_EVIDENCE_COUNT=0" "$FINAL_DOC" || fail "4C-10 missing evidence 0 yok"
pass "4C-10 missing evidence 0"

grep -q "4C_10_FINAL_CLOSURE_FILE_COUNT=9" "$FINAL_DOC" || fail "4C-10 final closure file count 9 yok"
pass "4C-10 final closure file count 9"

grep -q "4C_10_FOLLOWUP_FILE_COUNT=2" "$FINAL_DOC" || fail "4C-10 followup file count 2 yok"
pass "4C-10 followup file count 2"

grep -q "4C_10_CARRY_FORWARD_FILE_COUNT=1" "$FINAL_DOC" || fail "4C-10 carry forward file count 1 yok"
pass "4C-10 carry forward file count 1"

grep -q "4C_10_HANDOFF_READINESS_GATE_STATUS=PASS" "$FINAL_DOC" || fail "4C-10 readiness gate PASS yok"
pass "4C-10 readiness gate PASS"

grep -q "4C_10_DB_WRITE_APPLIED=NO" "$FINAL_DOC" || fail "4C-10 DB write NO yok"
pass "4C-10 DB write NO"

grep -q "4C_11_READY=YES" "$FINAL_DOC" || fail "4C-11 ready YES yok"
pass "4C-11 ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-10E Pilot Handoff / Evidence Package Final Closure Report

Step: 4C-10E
Blok: Pilot Handoff / Evidence Package Final Closure
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_10E_FINAL_DOC_STATUS=PASS
4C_10E_ALIAS_DOC_STATUS=PASS
4C_10A_STATUS=PASS
4C_10B_STATUS=PASS
4C_10C_STATUS=PASS
4C_10D_STATUS=PASS
4C_10_FINAL_STATUS=PASS
4C_10_PILOT_HANDOFF_EVIDENCE_PACKAGE_STATUS=PASS
4C_10_HANDOFF_PACKAGE_STATUS=READY
4C_10_REQUIRED_EVIDENCE_COUNT=12
4C_10_PACKAGE_EVIDENCE_COUNT=12
4C_10_MISSING_EVIDENCE_COUNT=0
4C_10_FINAL_CLOSURE_FILE_COUNT=9
4C_10_FOLLOWUP_FILE_COUNT=2
4C_10_CARRY_FORWARD_FILE_COUNT=1
4C_10_HANDOFF_READINESS_GATE_STATUS=PASS
4C_10_DB_WRITE_APPLIED=NO
4C_11_READY=YES

## Dosyalar

PACKAGE_ROOT=handoff/pilot/faz4c/uzmanparcaci/package
ASSEMBLY_MANIFEST=handoff/pilot/faz4c/uzmanparcaci/package/assembly_manifest.md
READINESS_FILE=handoff/pilot/faz4c/uzmanparcaci/package/readiness_gate.md
HANDOFF_MANIFEST=handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md

## Karar

4C-10 Pilot Handoff / Evidence Package ana blogu kapandi.
Handoff package READY durumunda.
DB yazma islemi yapilmadi.
Sonraki ana blok: 4C-11 FAZ 4C Final Closure / Pilot Completion Seal.

## Sonuc

4C-10E final closure tamamlandi.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-10E TEST SONUCU ====="
echo "4C_10_FINAL_STATUS=PASS ✅"
echo "4C_10_PILOT_HANDOFF_EVIDENCE_PACKAGE_STATUS=PASS ✅"
echo "4C_10_HANDOFF_PACKAGE_STATUS=READY ✅"
echo "4C_10_PACKAGE_EVIDENCE_COUNT=12 ✅"
echo "4C_10_MISSING_EVIDENCE_COUNT=0 ✅"
echo "4C_10_DB_WRITE_APPLIED=NO ✅"
echo "4C_11_READY=YES ✅"
