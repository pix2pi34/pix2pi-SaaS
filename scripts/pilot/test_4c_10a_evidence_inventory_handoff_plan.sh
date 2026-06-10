#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_9d_pilot_next_action_final_closure_report.md"
PREV_DOC="docs/pilot/faz4c/4c_9_final_closure.md"

MAIN_DOC="docs/pilot/faz4c/4c_10_pilot_handoff_evidence_package.md"
PLAN_DOC="docs/pilot/faz4c/4c_10a_evidence_inventory_handoff_plan.md"
INVENTORY_FILE="handoff/pilot/faz4c/uzmanparcaci/evidence_inventory.md"
MANIFEST_FILE="handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md"

REPORT_FILE="reports/pilot/faz4c/4c_10a_evidence_inventory_handoff_plan_report.md"

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

echo "===== 4C-10A EVIDENCE INVENTORY / HANDOFF PACKAGE PLAN TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-9D report yok: $PREV_REPORT"
pass "4C-9D report var"

[ -f "$PREV_DOC" ] || fail "4C-9 final closure doc yok: $PREV_DOC"
pass "4C-9 final closure doc var"

grep -q "4C_9_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-9 final PASS degil"
pass "4C-9 final PASS"

grep -q "4C_9_PILOT_NEXT_ACTION_STATUS=PASS" "$PREV_REPORT" || fail "4C-9 pilot next action PASS degil"
pass "4C-9 pilot next action PASS"

grep -q "4C_9_FINAL_GO_NO_GO_DECISION=GO" "$PREV_REPORT" || fail "4C-9 final GO degil"
pass "4C-9 final GO"

grep -q "4C_9_BLOCKING_ACTION_COUNT=0" "$PREV_REPORT" || fail "4C-9 blocking action 0 degil"
pass "4C-9 blocking action 0"

grep -q "4C_9_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "4C-9 DB write NO degil"
pass "4C-9 DB write NO"

grep -q "4C_10_READY=YES" "$PREV_REPORT" || fail "4C-10 ready YES yok"
pass "4C-10 ready YES"

[ -f "$MAIN_DOC" ] || fail "4C-10 main doc yok"
pass "4C-10 main doc var"

[ -f "$PLAN_DOC" ] || fail "4C-10A plan doc yok"
pass "4C-10A plan doc var"

[ -f "$INVENTORY_FILE" ] || fail "Evidence inventory yok"
pass "Evidence inventory var"

[ -f "$MANIFEST_FILE" ] || fail "Handoff manifest yok"
pass "Handoff manifest var"

MISSING_COUNT=0
for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "OK ✅ Evidence var: $f"
  else
    echo "HATA ❌ Evidence eksik: $f"
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done

[ "$MISSING_COUNT" -eq 0 ] || fail "Eksik evidence sayisi: $MISSING_COUNT"

grep -q "4C_10A_EVIDENCE_INVENTORY_STATUS=PASS" "$PLAN_DOC" || fail "4C-10A status PASS yok"
pass "4C-10A status PASS"

grep -q "4C_10A_HANDOFF_MANIFEST_CREATED=YES" "$PLAN_DOC" || fail "Handoff manifest created YES yok"
pass "Handoff manifest created YES"

grep -q "4C_10A_REQUIRED_EVIDENCE_COUNT=12" "$PLAN_DOC" || fail "Required evidence count 12 yok"
pass "Required evidence count 12"

grep -q "4C_10A_MISSING_EVIDENCE_COUNT=0" "$PLAN_DOC" || fail "Missing evidence count 0 yok"
pass "Missing evidence count 0"

grep -q "4C_10A_FINAL_GO_NO_GO_DECISION=GO" "$PLAN_DOC" || fail "Final GO yok"
pass "Final GO"

grep -q "4C_10A_DB_WRITE_APPLIED=NO" "$PLAN_DOC" || fail "DB write NO yok"
pass "DB write NO"

grep -q "4C_10B_READY=YES" "$PLAN_DOC" || fail "4C-10B ready YES yok"
pass "4C-10B ready YES"

grep -q "EVIDENCE_INVENTORY_STATUS=FROZEN" "$INVENTORY_FILE" || fail "Inventory frozen yok"
pass "Inventory frozen"

grep -q "HANDOFF_MANIFEST_CREATED=YES" "$MANIFEST_FILE" || fail "Manifest created YES yok"
pass "Manifest created YES"

grep -q "4C_10B_READY=YES" "$MANIFEST_FILE" || fail "Manifest 4C-10B ready YES yok"
pass "Manifest 4C-10B ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-10A Evidence Inventory / Handoff Package Plan Report

Step: 4C-10A
Blok: Evidence Inventory / Handoff Package Plan
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_10A_EVIDENCE_INVENTORY_STATUS=PASS
4C_10A_PREVIOUS_BLOCK_STATUS=PASS
4C_10A_FINAL_GO_NO_GO_DECISION=GO
4C_10A_HANDOFF_MANIFEST_CREATED=YES
4C_10A_REQUIRED_EVIDENCE_COUNT=12
4C_10A_MISSING_EVIDENCE_COUNT=$MISSING_COUNT
4C_10A_DB_WRITE_APPLIED=NO
4C_10B_READY=YES

## Dosyalar

EVIDENCE_INVENTORY=handoff/pilot/faz4c/uzmanparcaci/evidence_inventory.md
HANDOFF_MANIFEST=handoff/pilot/faz4c/uzmanparcaci/handoff_package_manifest.md

## Karar

FAZ 4C pilot handoff evidence inventory oluşturuldu.
Gerekli evidence dosyaları bulundu.
DB yazma işlemi yapılmadı.
Sonraki adım: 4C-10B Evidence Manifest Validation.

## Sonuc

4C-10A Evidence Inventory / Handoff Package Plan tamamlandı.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-10A TEST SONUCU ====="
echo "4C_10A_EVIDENCE_INVENTORY_STATUS=PASS ✅"
echo "4C_10A_FINAL_GO_NO_GO_DECISION=GO ✅"
echo "4C_10A_HANDOFF_MANIFEST_CREATED=YES ✅"
echo "4C_10A_REQUIRED_EVIDENCE_COUNT=12 ✅"
echo "4C_10A_MISSING_EVIDENCE_COUNT=$MISSING_COUNT ✅"
echo "4C_10A_DB_WRITE_APPLIED=NO ✅"
echo "4C_10B_READY=YES ✅"
