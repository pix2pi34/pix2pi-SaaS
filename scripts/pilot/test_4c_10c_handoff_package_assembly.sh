#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_10b_evidence_manifest_validation_report.md"
ASSEMBLY_DOC="docs/pilot/faz4c/4c_10c_handoff_package_assembly.md"
MANIFEST_FILE="handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md"
ASSEMBLY_MANIFEST="handoff/pilot/faz4c/uzmanparcaci/package/assembly_manifest.md"
PACKAGE_ROOT="handoff/pilot/faz4c/uzmanparcaci/package"
REPORT_FILE="reports/pilot/faz4c/4c_10c_handoff_package_assembly_report.md"

declare -A COPY_MAP=(
  ["docs/pilot/faz4c/4c_1_final_closure.md"]="final_closures/4c_1_final_closure.md"
  ["docs/pilot/faz4c/4c_2_final_closure.md"]="final_closures/4c_2_final_closure.md"
  ["docs/pilot/faz4c/4c_3_final_closure.md"]="final_closures/4c_3_final_closure.md"
  ["docs/pilot/faz4c/4c_4_final_closure.md"]="final_closures/4c_4_final_closure.md"
  ["docs/pilot/faz4c/4c_5_final_closure.md"]="final_closures/4c_5_final_closure.md"
  ["docs/pilot/faz4c/4c_6_final_closure.md"]="final_closures/4c_6_final_closure.md"
  ["docs/pilot/faz4c/4c_7_final_closure.md"]="final_closures/4c_7_final_closure.md"
  ["docs/pilot/faz4c/4c_8_final_closure.md"]="final_closures/4c_8_final_closure.md"
  ["docs/pilot/faz4c/4c_9_final_closure.md"]="final_closures/4c_9_final_closure.md"
  ["uat/pilot/faz4c/uzmanparcaci/followup_action_register.md"]="followup/followup_action_register.md"
  ["uat/pilot/faz4c/uzmanparcaci/followup_owner_assignment.md"]="followup/followup_owner_assignment.md"
  ["docs/pilot/faz4d/4d_carry_forward_from_4c.md"]="carry_forward/4d_carry_forward_from_4c.md"
)

echo "===== 4C-10C HANDOFF PACKAGE ASSEMBLY TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-10B report yok: $PREV_REPORT"
pass "4C-10B report var"

grep -q "4C_10B_EVIDENCE_MANIFEST_VALIDATION_STATUS=PASS" "$PREV_REPORT" || fail "4C-10B PASS degil"
pass "4C-10B PASS"

grep -q "4C_10B_HANDOFF_PACKAGE_STATUS=VALIDATED" "$PREV_REPORT" || fail "4C-10B package VALIDATED degil"
pass "4C-10B package VALIDATED"

grep -q "4C_10B_REQUIRED_EVIDENCE_COUNT=12" "$PREV_REPORT" || fail "Required evidence count 12 degil"
pass "Required evidence count 12"

grep -q "4C_10B_FOUND_EVIDENCE_COUNT=12" "$PREV_REPORT" || fail "Found evidence count 12 degil"
pass "Found evidence count 12"

grep -q "4C_10B_MISSING_EVIDENCE_COUNT=0" "$PREV_REPORT" || fail "Missing evidence count 0 degil"
pass "Missing evidence count 0"

grep -q "4C_10C_READY=YES" "$PREV_REPORT" || fail "4C-10C ready YES yok"
pass "4C-10C ready YES"

[ -f "$ASSEMBLY_DOC" ] || fail "4C-10C assembly doc yok"
pass "4C-10C assembly doc var"

mkdir -p "$PACKAGE_ROOT/final_closures" "$PACKAGE_ROOT/uat" "$PACKAGE_ROOT/followup" "$PACKAGE_ROOT/carry_forward"

COPIED_COUNT=0
MISSING_COUNT=0

for src in "${!COPY_MAP[@]}"; do
  dst="$PACKAGE_ROOT/${COPY_MAP[$src]}"

  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    echo "OK ✅ Kopyalandi: $src -> $dst"
    COPIED_COUNT=$((COPIED_COUNT + 1))
  else
    echo "HATA ❌ Kaynak evidence eksik: $src"
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done

[ "$COPIED_COUNT" -eq 12 ] || fail "Copied evidence count 12 degil: $COPIED_COUNT"
pass "Copied evidence count 12"

[ "$MISSING_COUNT" -eq 0 ] || fail "Missing evidence count 0 degil: $MISSING_COUNT"
pass "Missing evidence count 0"

cat <<MANIFEST_EOF > "$ASSEMBLY_MANIFEST"
# uzmanparcaci — FAZ 4C Handoff Assembly Manifest

## Assembly

HANDOFF_PACKAGE_STATUS=ASSEMBLED
PACKAGE_ROOT=$PACKAGE_ROOT
REQUIRED_EVIDENCE_COUNT=12
COPIED_EVIDENCE_COUNT=$COPIED_COUNT
MISSING_EVIDENCE_COUNT=$MISSING_COUNT
DB_WRITE_APPLIED=NO

---

## Package contents

FINAL_CLOSURE_COUNT=9
FOLLOWUP_FILE_COUNT=2
CARRY_FORWARD_FILE_COUNT=1
UAT_FILE_COUNT=0

---

## Machine status

4C_10C_HANDOFF_PACKAGE_ASSEMBLY_STATUS=PASS
4C_10C_ASSEMBLY_MANIFEST_CREATED=YES
4C_10C_HANDOFF_PACKAGE_STATUS=ASSEMBLED
4C_10D_READY=YES
MANIFEST_EOF

cat <<MANIFEST_EOF > "$MANIFEST_FILE"
# uzmanparcaci — FAZ 4C Handoff Package Manifest

## Manifest

HANDOFF_PACKAGE_STATUS=ASSEMBLED
PILOT_BUSINESS_NAME=uzmanparcaci
TENANT_BUSINESS_CODE=UZMANPARCACI
FINAL_GO_NO_GO_DECISION=GO

---

## Package groups

| Group | Açıklama | Status |
|-------|----------|--------|
| FINAL_CLOSURES | 4C-1..4C-9 final closure dokümanları | ASSEMBLED |
| UAT_EVIDENCE | UAT ve business acceptance kanıtları | VALIDATED |
| FOLLOWUP_ACTIONS | Follow-up register ve owner assignment | ASSEMBLED |
| CARRY_FORWARD | FAZ 4D carry-forward bağlantısı | ASSEMBLED |

---

## Manifest status

HANDOFF_MANIFEST_CREATED=YES
HANDOFF_MANIFEST_VALIDATION_STATUS=PASS
HANDOFF_PACKAGE_ASSEMBLY_STATUS=PASS
REQUIRED_EVIDENCE_COUNT=12
COPIED_EVIDENCE_COUNT=$COPIED_COUNT
MISSING_EVIDENCE_COUNT=$MISSING_COUNT
DB_WRITE_APPLIED=NO
4C_10D_READY=YES
MANIFEST_EOF

grep -q "4C_10C_HANDOFF_PACKAGE_ASSEMBLY_STATUS=PASS" "$ASSEMBLY_DOC" || fail "4C-10C status PASS dokumanda yok"
pass "4C-10C status PASS dokumanda var"

grep -q "4C_10C_COPIED_EVIDENCE_COUNT=12" "$ASSEMBLY_DOC" || fail "4C-10C copied evidence count 12 dokumanda yok"
pass "4C-10C copied evidence count 12 dokumanda var"

grep -q "4C_10C_MISSING_EVIDENCE_COUNT=0" "$ASSEMBLY_DOC" || fail "4C-10C missing evidence count 0 dokumanda yok"
pass "4C-10C missing evidence count 0 dokumanda var"

grep -q "4C_10C_HANDOFF_PACKAGE_STATUS=ASSEMBLED" "$ASSEMBLY_DOC" || fail "4C-10C package assembled dokumanda yok"
pass "4C-10C package assembled dokumanda var"

grep -q "4C_10D_READY=YES" "$ASSEMBLY_DOC" || fail "4C-10D ready YES dokumanda yok"
pass "4C-10D ready YES dokumanda var"

[ -f "$ASSEMBLY_MANIFEST" ] || fail "Assembly manifest yok"
pass "Assembly manifest var"

grep -q "HANDOFF_PACKAGE_STATUS=ASSEMBLED" "$ASSEMBLY_MANIFEST" || fail "Assembly manifest package assembled yok"
pass "Assembly manifest package assembled"

grep -q "COPIED_EVIDENCE_COUNT=12" "$ASSEMBLY_MANIFEST" || fail "Assembly manifest copied count 12 yok"
pass "Assembly manifest copied count 12"

grep -q "MISSING_EVIDENCE_COUNT=0" "$ASSEMBLY_MANIFEST" || fail "Assembly manifest missing count 0 yok"
pass "Assembly manifest missing count 0"

grep -q "HANDOFF_PACKAGE_STATUS=ASSEMBLED" "$MANIFEST_FILE" || fail "Handoff manifest assembled yok"
pass "Handoff manifest assembled"

grep -q "4C_10D_READY=YES" "$MANIFEST_FILE" || fail "Handoff manifest 4C-10D ready YES yok"
pass "Handoff manifest 4C-10D ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-10C Handoff Package Assembly Report

Step: 4C-10C
Blok: Handoff Package Assembly
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_10C_HANDOFF_PACKAGE_ASSEMBLY_STATUS=PASS
4C_10C_PREVIOUS_BLOCK_STATUS=PASS
4C_10C_HANDOFF_PACKAGE_STATUS=ASSEMBLED
4C_10C_PACKAGE_ROOT=$PACKAGE_ROOT
4C_10C_REQUIRED_EVIDENCE_COUNT=12
4C_10C_COPIED_EVIDENCE_COUNT=$COPIED_COUNT
4C_10C_MISSING_EVIDENCE_COUNT=$MISSING_COUNT
4C_10C_ASSEMBLY_MANIFEST_CREATED=YES
4C_10C_DB_WRITE_APPLIED=NO
4C_10D_READY=YES

## Dosyalar

PACKAGE_ROOT=$PACKAGE_ROOT
ASSEMBLY_MANIFEST=$ASSEMBLY_MANIFEST
HANDOFF_MANIFEST=$MANIFEST_FILE

## Karar

Handoff package assembly tamamlandı.
12 evidence dosyası package dizinine kopyalandı.
DB yazma işlemi yapılmadı.
Sonraki adım: 4C-10D Handoff Readiness Gate.

## Sonuc

4C-10C Handoff Package Assembly tamamlandı.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-10C TEST SONUCU ====="
echo "4C_10C_HANDOFF_PACKAGE_ASSEMBLY_STATUS=PASS ✅"
echo "4C_10C_HANDOFF_PACKAGE_STATUS=ASSEMBLED ✅"
echo "4C_10C_REQUIRED_EVIDENCE_COUNT=12 ✅"
echo "4C_10C_COPIED_EVIDENCE_COUNT=$COPIED_COUNT ✅"
echo "4C_10C_MISSING_EVIDENCE_COUNT=$MISSING_COUNT ✅"
echo "4C_10C_DB_WRITE_APPLIED=NO ✅"
echo "4C_10D_READY=YES ✅"
