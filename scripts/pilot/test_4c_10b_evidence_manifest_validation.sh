#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_10a_evidence_inventory_handoff_plan_report.md"

VALIDATION_DOC="docs/pilot/faz4c/4c_10b_evidence_manifest_validation.md"
INVENTORY_FILE="handoff/pilot/faz4c/uzmanparcaci/evidence_inventory.md"
MANIFEST_FILE="handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md"
VALIDATION_FILE="handoff/pilot/faz4c/uzmanparcaci/evidence_manifest_validation.md"

REPORT_FILE="reports/pilot/faz4c/4c_10b_evidence_manifest_validation_report.md"

REQUIRED_FILES=(
  "docs/pilot/faz4c/4c_1_final_closure.md"
  "docs/pilot/faz4c/4c_2_final_closure.md"
  "docs/pilot/faz4c/4c_3_final_closure.md"
  "docs/pilot/faz4c/4c_4_final_closure.md"
  "docs/pilot/faz4c/4c_5_final_closure.md"
  "docs/pilot/faz4c/4c_6_final_closure.md"
  "docs/pilot/faz4c/4c_7_final_closure.md"
  "docs/pilot/faz4c/4c_8_final_closure.md"
  "docs/pilot/faz4c/4c_9_final_closure.md"
  "uat/pilot/faz4c/uzmanparcaci/followup_action_register.md"
  "uat/pilot/faz4c/uzmanparcaci/followup_owner_assignment.md"
  "docs/pilot/faz4d/4d_carry_forward_from_4c.md"
)

echo "===== 4C-10B EVIDENCE MANIFEST VALIDATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-10A report yok: $PREV_REPORT"
pass "4C-10A report var"

grep -q "4C_10A_EVIDENCE_INVENTORY_STATUS=PASS" "$PREV_REPORT" || fail "4C-10A PASS degil"
pass "4C-10A PASS"

grep -q "4C_10A_FINAL_GO_NO_GO_DECISION=GO" "$PREV_REPORT" || fail "4C-10A final GO degil"
pass "4C-10A final GO"

grep -q "4C_10A_HANDOFF_MANIFEST_CREATED=YES" "$PREV_REPORT" || fail "4C-10A manifest created YES degil"
pass "4C-10A manifest created YES"

grep -q "4C_10A_REQUIRED_EVIDENCE_COUNT=12" "$PREV_REPORT" || fail "4C-10A required evidence count 12 degil"
pass "4C-10A required evidence count 12"

grep -q "4C_10A_MISSING_EVIDENCE_COUNT=0" "$PREV_REPORT" || fail "4C-10A missing evidence count 0 degil"
pass "4C-10A missing evidence count 0"

grep -q "4C_10B_READY=YES" "$PREV_REPORT" || fail "4C-10B ready YES yok"
pass "4C-10B ready YES"

[ -f "$VALIDATION_DOC" ] || fail "4C-10B validation doc yok"
pass "4C-10B validation doc var"

[ -f "$INVENTORY_FILE" ] || fail "Evidence inventory yok"
pass "Evidence inventory var"

[ -f "$MANIFEST_FILE" ] || fail "Handoff manifest yok"
pass "Handoff manifest var"

[ -f "$VALIDATION_FILE" ] || fail "Evidence manifest validation file yok"
pass "Evidence manifest validation file var"

MISSING_COUNT=0
FOUND_COUNT=0

for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "OK ✅ Evidence bulundu: $f"
    FOUND_COUNT=$((FOUND_COUNT + 1))
  else
    echo "HATA ❌ Evidence eksik: $f"
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done

[ "$FOUND_COUNT" -eq 12 ] || fail "Found evidence count 12 degil: $FOUND_COUNT"
pass "Found evidence count 12"

[ "$MISSING_COUNT" -eq 0 ] || fail "Missing evidence count 0 degil: $MISSING_COUNT"
pass "Missing evidence count 0"

grep -q "4C_10B_EVIDENCE_MANIFEST_VALIDATION_STATUS=PASS" "$VALIDATION_DOC" || fail "4C-10B status PASS yok"
pass "4C-10B status PASS"

grep -q "4C_10B_HANDOFF_PACKAGE_STATUS=VALIDATED" "$VALIDATION_DOC" || fail "Handoff package VALIDATED yok"
pass "Handoff package VALIDATED"

grep -q "4C_10B_REQUIRED_EVIDENCE_COUNT=12" "$VALIDATION_DOC" || fail "Required evidence count 12 yok"
pass "Required evidence count 12"

grep -q "4C_10B_FOUND_EVIDENCE_COUNT=12" "$VALIDATION_DOC" || fail "Found evidence count 12 yok"
pass "Found evidence count 12 dokumanda var"

grep -q "4C_10B_MISSING_EVIDENCE_COUNT=0" "$VALIDATION_DOC" || fail "Missing evidence count 0 yok"
pass "Missing evidence count 0 dokumanda var"

grep -q "4C_10B_FINAL_CLOSURE_GROUP_STATUS=VALIDATED" "$VALIDATION_DOC" || fail "Final closure group VALIDATED yok"
pass "Final closure group VALIDATED"

grep -q "4C_10B_UAT_EVIDENCE_GROUP_STATUS=VALIDATED" "$VALIDATION_DOC" || fail "UAT evidence group VALIDATED yok"
pass "UAT evidence group VALIDATED"

grep -q "4C_10B_FOLLOWUP_ACTION_GROUP_STATUS=VALIDATED" "$VALIDATION_DOC" || fail "Follow-up group VALIDATED yok"
pass "Follow-up group VALIDATED"

grep -q "4C_10B_CARRY_FORWARD_GROUP_STATUS=VALIDATED" "$VALIDATION_DOC" || fail "Carry-forward group VALIDATED yok"
pass "Carry-forward group VALIDATED"

grep -q "4C_10B_DB_WRITE_APPLIED=NO" "$VALIDATION_DOC" || fail "DB write NO yok"
pass "DB write NO"

grep -q "4C_10C_READY=YES" "$VALIDATION_DOC" || fail "4C-10C ready YES yok"
pass "4C-10C ready YES"

grep -q "EVIDENCE_INVENTORY_STATUS=VALIDATED" "$INVENTORY_FILE" || fail "Inventory VALIDATED yok"
pass "Inventory VALIDATED"

grep -q "HANDOFF_PACKAGE_STATUS=VALIDATED" "$MANIFEST_FILE" || fail "Manifest package VALIDATED yok"
pass "Manifest package VALIDATED"

grep -q "HANDOFF_MANIFEST_VALIDATION_STATUS=PASS" "$MANIFEST_FILE" || fail "Manifest validation PASS yok"
pass "Manifest validation PASS"

grep -q "VALIDATION_STATUS=PASS" "$VALIDATION_FILE" || fail "Validation file PASS yok"
pass "Validation file PASS"

grep -q "4C_10C_READY=YES" "$VALIDATION_FILE" || fail "Validation file 4C-10C ready YES yok"
pass "Validation file 4C-10C ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-10B Evidence Manifest Validation Report

Step: 4C-10B
Blok: Evidence Manifest Validation
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_10B_EVIDENCE_MANIFEST_VALIDATION_STATUS=PASS
4C_10B_PREVIOUS_BLOCK_STATUS=PASS
4C_10B_HANDOFF_PACKAGE_STATUS=VALIDATED
4C_10B_REQUIRED_EVIDENCE_COUNT=12
4C_10B_FOUND_EVIDENCE_COUNT=$FOUND_COUNT
4C_10B_MISSING_EVIDENCE_COUNT=$MISSING_COUNT
4C_10B_FINAL_CLOSURE_GROUP_STATUS=VALIDATED
4C_10B_UAT_EVIDENCE_GROUP_STATUS=VALIDATED
4C_10B_FOLLOWUP_ACTION_GROUP_STATUS=VALIDATED
4C_10B_CARRY_FORWARD_GROUP_STATUS=VALIDATED
4C_10B_DB_WRITE_APPLIED=NO
4C_10C_READY=YES

## Dosyalar

EVIDENCE_INVENTORY=handoff/pilot/faz4c/uzmanparcaci/evidence_inventory.md
HANDOFF_MANIFEST=handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md
VALIDATION_FILE=handoff/pilot/faz4c/uzmanparcaci/evidence_manifest_validation.md

## Karar

Evidence manifest doğrulandı.
12 required evidence dosyası bulundu.
Eksik evidence yok.
DB yazma işlemi yapılmadı.
Sonraki adım: 4C-10C Handoff Package Assembly.

## Sonuc

4C-10B Evidence Manifest Validation tamamlandı.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-10B TEST SONUCU ====="
echo "4C_10B_EVIDENCE_MANIFEST_VALIDATION_STATUS=PASS ✅"
echo "4C_10B_HANDOFF_PACKAGE_STATUS=VALIDATED ✅"
echo "4C_10B_REQUIRED_EVIDENCE_COUNT=12 ✅"
echo "4C_10B_FOUND_EVIDENCE_COUNT=$FOUND_COUNT ✅"
echo "4C_10B_MISSING_EVIDENCE_COUNT=$MISSING_COUNT ✅"
echo "4C_10B_DB_WRITE_APPLIED=NO ✅"
echo "4C_10C_READY=YES ✅"
