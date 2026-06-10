#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TODAY="$(date +%F)"

INPUT_ENV="docs/pilot/faz4c/4c_8a_go_no_go_decision_input.env"
DECISION_FORM="uat/pilot/faz4c/uzmanparcaci/go_no_go_decision_form.md"
PREV_REPORT="reports/pilot/faz4c/4c_8b_go_no_go_decision_apply_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_8b_2_go_no_go_decision_input_fill_report.md"

echo "===== 4C-8B-2 GO / NO-GO DECISION INPUT FILL ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

[ -f "$INPUT_ENV" ] || fail "Decision input env yok: $INPUT_ENV"
[ -f "$DECISION_FORM" ] || fail "Decision form yok: $DECISION_FORM"
[ -f "$PREV_REPORT" ] || fail "4C-8B test report yok: $PREV_REPORT"

grep -q "4C_8B_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-8B test PASS degil"
grep -q "4C_8B_GO_NO_GO_DECISION_APPLY_STATUS=BLOCKED" "$PREV_REPORT" || fail "4C-8B onceki durum BLOCKED degil"
grep -q "4C_8C_READY=NO" "$PREV_REPORT" || fail "4C-8C onceki durum NO degil"

cat <<EOF > "$INPUT_ENV"
# FAZ 4C — 4C-8A Go / No-Go Decision Input
# Final GO karari dolduruldu.
# Bu adimda DB write yapilmaz.

PILOT_BUSINESS_NAME="uzmanparcaci"
TENANT_BUSINESS_CODE="UZMANPARCACI"
PILOT_SECTOR="OTO_YEDEK_PARCA"

TECHNICAL_UAT_STATUS="PASS"
BUSINESS_ACCEPTANCE_STATUS="PASS"
BUG_BLOCKER_BURNDOWN_STATUS="PASS"
CRITICAL_BLOCKER_COUNT="0"
OPEN_WARNING_COUNT="0"
OPEN_IMPROVEMENT_COUNT_FOR_4C="0"
BLOCKING_FIX_REQUIRED="NO"

SYSTEM_RECOMMENDATION="GO"

FINAL_GO_NO_GO_DECISION="GO"
DECISION_OWNER="mert_omur"
DECISION_DATE="$TODAY"
DECISION_NOTE="FAZ 4C pilot kapsaminda teknik UAT, business acceptance ve burn-down kontrolleri PASS oldugu icin GO karari verildi."

ACCEPTS_PHASE_4D_CARRY_FORWARD="YES"
ACCEPTS_MARKETPLACE_PHASE_4D="YES"
ACCEPTS_NO_CORE_PRODUCT_APPLY_IN_4C="YES"
ACCEPTS_NO_LIVE_MARKETPLACE_IN_4C="YES"

GO_NO_GO_FINALIZATION_READY="YES"
DB_WRITE_APPLIED="NO"
NEXT_STEP="4C_8B_GO_NO_GO_DECISION_APPLY"
EOF

cat <<EOF > "$DECISION_FORM"
# uzmanparcaci — Go / No-Go Decision Form

## Pilot

PILOT_BUSINESS_NAME=uzmanparcaci
TENANT_BUSINESS_CODE=UZMANPARCACI
PILOT_SECTOR=OTO_YEDEK_PARCA

---

## Sistem durumu

TECHNICAL_UAT_STATUS=PASS
BUSINESS_ACCEPTANCE_STATUS=PASS
BUG_BLOCKER_BURNDOWN_STATUS=PASS
CRITICAL_BLOCKER_COUNT=0
OPEN_WARNING_COUNT=0
OPEN_IMPROVEMENT_COUNT_FOR_4C=0
BLOCKING_FIX_REQUIRED=NO

---

## Sistem önerisi

SYSTEM_RECOMMENDATION=GO

---

## Final karar

FINAL_GO_NO_GO_DECISION=GO
DECISION_OWNER=mert_omur
DECISION_DATE=$TODAY
DECISION_NOTE=FAZ 4C pilot kapsaminda teknik UAT, business acceptance ve burn-down kontrolleri PASS oldugu icin GO karari verildi.

ACCEPTS_PHASE_4D_CARRY_FORWARD=YES
ACCEPTS_MARKETPLACE_PHASE_4D=YES
ACCEPTS_NO_CORE_PRODUCT_APPLY_IN_4C=YES
ACCEPTS_NO_LIVE_MARKETPLACE_IN_4C=YES

---

## Gate sonucu

GO_NO_GO_FINALIZATION_READY=YES
4C_8C_READY=YES
EOF

PENDING_COUNT="$( (grep -R "PENDING" "$INPUT_ENV" "$DECISION_FORM" || true) | wc -l | tr -d ' ')"

cat <<EOF > "$REPORT_FILE"
# FAZ 4C — 4C-8B-2 Go / No-Go Decision Input Fill Report

Step: 4C-8B-2
Blok: Go / No-Go Decision Input Fill
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_8B_2_GO_NO_GO_DECISION_INPUT_FILL_STATUS=PASS
4C_8B_2_FINAL_GO_NO_GO_DECISION=GO
4C_8B_2_DECISION_OWNER=mert_omur
4C_8B_2_DECISION_DATE=$TODAY
4C_8B_2_SYSTEM_RECOMMENDATION=GO
4C_8B_2_ACCEPTS_PHASE_4D_CARRY_FORWARD=YES
4C_8B_2_ACCEPTS_MARKETPLACE_PHASE_4D=YES
4C_8B_2_ACCEPTS_NO_CORE_PRODUCT_APPLY_IN_4C=YES
4C_8B_2_ACCEPTS_NO_LIVE_MARKETPLACE_IN_4C=YES
4C_8B_2_PENDING_FIELD_COUNT=$PENDING_COUNT
4C_8B_2_DB_WRITE_APPLIED=NO
4C_8B_RETRY_READY=YES

## Sonuc

Go / No-Go decision input GO olarak dolduruldu.
DB yazma islemi yapilmadi.
4C-8B apply guard tekrar calistirilabilir.
EOF

echo "OK ✅ Go / No-Go decision input GO olarak dolduruldu: $INPUT_ENV"
echo "OK ✅ Go / No-Go decision form GO olarak guncellendi: $DECISION_FORM"
echo "OK ✅ Fill report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-8B-2 OZET ====="
echo "4C_8B_2_GO_NO_GO_DECISION_INPUT_FILL_STATUS=PASS ✅"
echo "4C_8B_2_FINAL_GO_NO_GO_DECISION=GO ✅"
echo "4C_8B_2_PENDING_FIELD_COUNT=$PENDING_COUNT"
echo "4C_8B_2_DB_WRITE_APPLIED=NO ✅"
echo "4C_8B_RETRY_READY=YES ✅"
