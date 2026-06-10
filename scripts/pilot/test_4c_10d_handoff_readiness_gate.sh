#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_10c_handoff_package_assembly_report.md"

GATE_DOC="docs/pilot/faz4c/4c_10d_handoff_readiness_gate.md"
PACKAGE_ROOT="handoff/pilot/faz4c/uzmanparcaci/package"
ASSEMBLY_MANIFEST="$PACKAGE_ROOT/assembly_manifest.md"
HANDOFF_MANIFEST="handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md"
READINESS_FILE="$PACKAGE_ROOT/readiness_gate.md"

REPORT_FILE="reports/pilot/faz4c/4c_10d_handoff_readiness_gate_report.md"

REQUIRED_PACKAGE_FILES=(
  "$PACKAGE_ROOT/final_closures/4c_1_final_closure.md"
  "$PACKAGE_ROOT/final_closures/4c_2_final_closure.md"
  "$PACKAGE_ROOT/final_closures/4c_3_final_closure.md"
  "$PACKAGE_ROOT/final_closures/4c_4_final_closure.md"
  "$PACKAGE_ROOT/final_closures/4c_5_final_closure.md"
  "$PACKAGE_ROOT/final_closures/4c_6_final_closure.md"
  "$PACKAGE_ROOT/final_closures/4c_7_final_closure.md"
  "$PACKAGE_ROOT/final_closures/4c_8_final_closure.md"
  "$PACKAGE_ROOT/final_closures/4c_9_final_closure.md"
  "$PACKAGE_ROOT/followup/followup_action_register.md"
  "$PACKAGE_ROOT/followup/followup_owner_assignment.md"
  "$PACKAGE_ROOT/carry_forward/4d_carry_forward_from_4c.md"
)

echo "===== 4C-10D HANDOFF READINESS GATE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-10C report yok: $PREV_REPORT"
pass "4C-10C report var"

grep -q "4C_10C_HANDOFF_PACKAGE_ASSEMBLY_STATUS=PASS" "$PREV_REPORT" || fail "4C-10C PASS degil"
pass "4C-10C PASS"

grep -q "4C_10C_HANDOFF_PACKAGE_STATUS=ASSEMBLED" "$PREV_REPORT" || fail "4C-10C package ASSEMBLED degil"
pass "4C-10C package ASSEMBLED"

grep -q "4C_10C_REQUIRED_EVIDENCE_COUNT=12" "$PREV_REPORT" || fail "4C-10C required evidence count 12 degil"
pass "4C-10C required evidence count 12"

grep -q "4C_10C_COPIED_EVIDENCE_COUNT=12" "$PREV_REPORT" || fail "4C-10C copied evidence count 12 degil"
pass "4C-10C copied evidence count 12"

grep -q "4C_10C_MISSING_EVIDENCE_COUNT=0" "$PREV_REPORT" || fail "4C-10C missing evidence count 0 degil"
pass "4C-10C missing evidence count 0"

grep -q "4C_10C_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "4C-10C DB write NO degil"
pass "4C-10C DB write NO"

grep -q "4C_10D_READY=YES" "$PREV_REPORT" || fail "4C-10D ready YES yok"
pass "4C-10D ready YES"

[ -f "$GATE_DOC" ] || fail "4C-10D gate doc yok"
pass "4C-10D gate doc var"

[ -d "$PACKAGE_ROOT" ] || fail "Package root yok: $PACKAGE_ROOT"
pass "Package root var"

[ -f "$ASSEMBLY_MANIFEST" ] || fail "Assembly manifest yok"
pass "Assembly manifest var"

[ -f "$HANDOFF_MANIFEST" ] || fail "Handoff manifest yok"
pass "Handoff manifest var"

grep -q "HANDOFF_PACKAGE_STATUS=ASSEMBLED" "$ASSEMBLY_MANIFEST" || fail "Assembly manifest ASSEMBLED degil"
pass "Assembly manifest ASSEMBLED"

grep -q "COPIED_EVIDENCE_COUNT=12" "$ASSEMBLY_MANIFEST" || fail "Assembly manifest copied evidence 12 degil"
pass "Assembly manifest copied evidence 12"

grep -q "MISSING_EVIDENCE_COUNT=0" "$ASSEMBLY_MANIFEST" || fail "Assembly manifest missing evidence 0 degil"
pass "Assembly manifest missing evidence 0"

grep -q "HANDOFF_PACKAGE_STATUS=ASSEMBLED" "$HANDOFF_MANIFEST" || fail "Handoff manifest ASSEMBLED degil"
pass "Handoff manifest ASSEMBLED"

MISSING_COUNT=0
PACKAGE_EVIDENCE_COUNT=0

for f in "${REQUIRED_PACKAGE_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "OK ✅ Package evidence var: $f"
    PACKAGE_EVIDENCE_COUNT=$((PACKAGE_EVIDENCE_COUNT + 1))
  else
    echo "HATA ❌ Package evidence eksik: $f"
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done

[ "$PACKAGE_EVIDENCE_COUNT" -eq 12 ] || fail "Package evidence count 12 degil: $PACKAGE_EVIDENCE_COUNT"
pass "Package evidence count 12"

[ "$MISSING_COUNT" -eq 0 ] || fail "Missing package file count 0 degil: $MISSING_COUNT"
pass "Missing package file count 0"

FINAL_CLOSURE_COUNT="$(find "$PACKAGE_ROOT/final_closures" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
FOLLOWUP_FILE_COUNT="$(find "$PACKAGE_ROOT/followup" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
CARRY_FORWARD_FILE_COUNT="$(find "$PACKAGE_ROOT/carry_forward" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"

[ "$FINAL_CLOSURE_COUNT" -eq 9 ] || fail "Final closure file count 9 degil: $FINAL_CLOSURE_COUNT"
pass "Final closure file count 9"

[ "$FOLLOWUP_FILE_COUNT" -eq 2 ] || fail "Follow-up file count 2 degil: $FOLLOWUP_FILE_COUNT"
pass "Follow-up file count 2"

[ "$CARRY_FORWARD_FILE_COUNT" -eq 1 ] || fail "Carry-forward file count 1 degil: $CARRY_FORWARD_FILE_COUNT"
pass "Carry-forward file count 1"

grep -q "4C_10D_HANDOFF_READINESS_GATE_STATUS=PASS" "$GATE_DOC" || fail "4C-10D gate PASS dokumanda yok"
pass "4C-10D gate PASS dokumanda var"

grep -q "4C_10D_REQUIRED_EVIDENCE_COUNT=12" "$GATE_DOC" || fail "4C-10D required evidence 12 yok"
pass "4C-10D required evidence 12"

grep -q "4C_10D_PACKAGE_EVIDENCE_COUNT=12" "$GATE_DOC" || fail "4C-10D package evidence count 12 yok"
pass "4C-10D package evidence count 12"

grep -q "4C_10D_MISSING_PACKAGE_FILE_COUNT=0" "$GATE_DOC" || fail "4C-10D missing package file 0 yok"
pass "4C-10D missing package file 0"

grep -q "4C_10D_DB_WRITE_APPLIED=NO" "$GATE_DOC" || fail "4C-10D DB write NO yok"
pass "4C-10D DB write NO"

grep -q "4C_10E_READY=YES" "$GATE_DOC" || fail "4C-10E ready YES yok"
pass "4C-10E ready YES"

cat <<READY_EOF > "$READINESS_FILE"
# uzmanparcaci — FAZ 4C Handoff Readiness Gate

## Readiness

HANDOFF_READINESS_GATE_STATUS=PASS
HANDOFF_PACKAGE_STATUS=READY
PACKAGE_ROOT=$PACKAGE_ROOT
REQUIRED_EVIDENCE_COUNT=12
PACKAGE_EVIDENCE_COUNT=$PACKAGE_EVIDENCE_COUNT
MISSING_PACKAGE_FILE_COUNT=$MISSING_COUNT

---

## Package counts

FINAL_CLOSURE_FILE_COUNT=$FINAL_CLOSURE_COUNT
FOLLOWUP_FILE_COUNT=$FOLLOWUP_FILE_COUNT
CARRY_FORWARD_FILE_COUNT=$CARRY_FORWARD_FILE_COUNT

---

## Machine status

4C_10D_HANDOFF_READINESS_GATE_STATUS=PASS
4C_10D_HANDOFF_PACKAGE_STATUS=READY
4C_10D_DB_WRITE_APPLIED=NO
4C_10E_READY=YES
READY_EOF

cat <<MANIFEST_EOF > "$HANDOFF_MANIFEST"
# uzmanparcaci — FAZ 4C Handoff Package Manifest

## Manifest

HANDOFF_PACKAGE_STATUS=READY
PILOT_BUSINESS_NAME=uzmanparcaci
TENANT_BUSINESS_CODE=UZMANPARCACI
FINAL_GO_NO_GO_DECISION=GO

---

## Package groups

| Group | Açıklama | Status |
|-------|----------|--------|
| FINAL_CLOSURES | 4C-1..4C-9 final closure dokümanları | READY |
| UAT_EVIDENCE | UAT ve business acceptance kanıtları | READY |
| FOLLOWUP_ACTIONS | Follow-up register ve owner assignment | READY |
| CARRY_FORWARD | FAZ 4D carry-forward bağlantısı | READY |

---

## Manifest status

HANDOFF_MANIFEST_CREATED=YES
HANDOFF_MANIFEST_VALIDATION_STATUS=PASS
HANDOFF_PACKAGE_ASSEMBLY_STATUS=PASS
HANDOFF_READINESS_GATE_STATUS=PASS
REQUIRED_EVIDENCE_COUNT=12
PACKAGE_EVIDENCE_COUNT=$PACKAGE_EVIDENCE_COUNT
MISSING_PACKAGE_FILE_COUNT=$MISSING_COUNT
DB_WRITE_APPLIED=NO
4C_10E_READY=YES
MANIFEST_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-10D Handoff Readiness Gate Report

Step: 4C-10D
Blok: Handoff Readiness Gate
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_10D_HANDOFF_READINESS_GATE_STATUS=PASS
4C_10D_PREVIOUS_BLOCK_STATUS=PASS
4C_10D_HANDOFF_PACKAGE_STATUS=READY
4C_10D_PACKAGE_ROOT_EXISTS=YES
4C_10D_ASSEMBLY_MANIFEST_EXISTS=YES
4C_10D_HANDOFF_MANIFEST_EXISTS=YES
4C_10D_REQUIRED_EVIDENCE_COUNT=12
4C_10D_PACKAGE_EVIDENCE_COUNT=$PACKAGE_EVIDENCE_COUNT
4C_10D_MISSING_PACKAGE_FILE_COUNT=$MISSING_COUNT
4C_10D_FINAL_CLOSURE_FILE_COUNT=$FINAL_CLOSURE_COUNT
4C_10D_FOLLOWUP_FILE_COUNT=$FOLLOWUP_FILE_COUNT
4C_10D_CARRY_FORWARD_FILE_COUNT=$CARRY_FORWARD_FILE_COUNT
4C_10D_DB_WRITE_APPLIED=NO
4C_10E_READY=YES

## Dosyalar

PACKAGE_ROOT=$PACKAGE_ROOT
ASSEMBLY_MANIFEST=$ASSEMBLY_MANIFEST
HANDOFF_MANIFEST=$HANDOFF_MANIFEST
READINESS_FILE=$READINESS_FILE

## Karar

Handoff package readiness gate PASS.
Package READY durumuna alındı.
DB yazma işlemi yapılmadı.
Sonraki adım: 4C-10E Pilot Handoff / Evidence Package Final Closure.

## Sonuc

4C-10D Handoff Readiness Gate tamamlandı.
REPORT_EOF

pass "Readiness file olusturuldu: $READINESS_FILE"
pass "Handoff manifest READY olarak guncellendi: $HANDOFF_MANIFEST"
pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-10D TEST SONUCU ====="
echo "4C_10D_HANDOFF_READINESS_GATE_STATUS=PASS ✅"
echo "4C_10D_HANDOFF_PACKAGE_STATUS=READY ✅"
echo "4C_10D_PACKAGE_EVIDENCE_COUNT=$PACKAGE_EVIDENCE_COUNT ✅"
echo "4C_10D_MISSING_PACKAGE_FILE_COUNT=$MISSING_COUNT ✅"
echo "4C_10D_DB_WRITE_APPLIED=NO ✅"
echo "4C_10E_READY=YES ✅"
