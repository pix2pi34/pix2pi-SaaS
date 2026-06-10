#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP12_REPORT="reports/faz4d/FAZ_4D_12_PILOT_MONITORING_STABILIZATION_REPORT.txt"
STEP13_FILE="docs/faz4d/FAZ_4D_13_SUPPORT_FEEDBACK_LOOP.md"
UI_FILE="web/pilot-support-feedback/index.html"
REPORT_FILE="reports/faz4d/FAZ_4D_13_SUPPORT_FEEDBACK_LOOP_REPORT.txt"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
DOC_EVIDENCE_COUNT=0
UI_EVIDENCE_COUNT=0

pass() {
  OK_COUNT=$((OK_COUNT + 1))
  echo "OK ✅ $1"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "UYARI ⚠️ $1"
}

fail_soft() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "HATA ❌ $1"
}

check_file() {
  local file="$1"
  if [ -f "$file" ]; then
    pass "dosya var: $file"
  else
    fail_soft "dosya yok: $file"
  fi
}

check_grep_file() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    fail_soft "$label dosya yok: $file"
    return
  fi

  if grep -Fq "$pattern" "$file"; then
    pass "$label"
  else
    fail_soft "$label"
  fi
}

check_doc_evidence() {
  local pattern="$1"
  local label="$2"

  if grep -Fq "$pattern" "$STEP13_FILE"; then
    DOC_EVIDENCE_COUNT=$((DOC_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    fail_soft "$label"
  fi
}

check_ui_evidence() {
  local pattern="$1"
  local label="$2"

  if grep -Fq "$pattern" "$UI_FILE"; then
    UI_EVIDENCE_COUNT=$((UI_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    fail_soft "$label"
  fi
}

echo "===== FAZ 4D-13 SUPPORT / FEEDBACK LOOP TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP12_REPORT"
check_file "$STEP13_FILE"
check_file "$UI_FILE"

check_grep_file "$MASTER_FILE" "4D-12 | Pilot Monitoring / Stabilization | DONE ✅" "4D-12 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-13 | Support / Feedback Loop | IN_PROGRESS" "4D-13 master planda IN_PROGRESS"
check_grep_file "$STEP12_REPORT" "FAZ_4D_12_TEST_STATUS=PASS" "4D-12 monitoring raporu PASS"

echo
echo "===== DOKUMAN KANIT TARAMASI ====="

check_doc_evidence "Pilot feedback loop zorunludur" "feedback loop karari var"
check_doc_evidence "Feedback türleri sınıflandırılır" "feedback turleri karari var"
check_doc_evidence "Critical blocker no-go sebebidir" "critical blocker no-go karari var"
check_doc_evidence "Tenant/security bildirimi önceliklidir" "tenant security feedback karari var"
check_doc_evidence "Business flow bildirimi takip edilir" "business flow feedback karari var"
check_doc_evidence "UI/UX feedback ayrı tutulur" "UI UX feedback karari var"
check_doc_evidence "Oto yedek parça feedback ayrı tutulur" "oto yedek parca feedback karari var"
check_doc_evidence "Marketplace/Paraşüt feedback production açmaz" "marketplace parasut production acmaz karari var"
check_doc_evidence "Support response owner belirlenir" "support owner karari var"
check_doc_evidence "Feedback kapanış durumu tutulur" "feedback status karari var"
check_doc_evidence "Pilot feedback 4D final kararı etkiler" "feedback final karar etkisi var"
check_doc_evidence "Mobile feedback 4D-14'e taşınır" "mobile feedback 4D-14 karari var"
check_doc_evidence "FAZ_4D_14_READY=NO" "4D-14 baslangicta NO"

echo
echo "===== UI SUPPORT FEEDBACK KANIT TARAMASI ====="

check_ui_evidence "Support / Feedback Loop" "UI basligi var"
check_ui_evidence "Feedback Loop" "UI feedback loop var"
check_ui_evidence "Critical Blocker" "UI critical blocker var"
check_ui_evidence "Security / Tenant" "UI security tenant var"
check_ui_evidence "Access / Login" "UI access login var"
check_ui_evidence "Business Flow" "UI business flow var"
check_ui_evidence "Oto Yedek Parça" "UI oto yedek parca var"
check_ui_evidence "UI / UX" "UI UX var"
check_ui_evidence "Marketplace Discovery" "UI marketplace discovery var"
check_ui_evidence "Paraşüt Discovery" "UI parasut discovery var"
check_ui_evidence "Mobile PWA" "UI mobile PWA var"
check_ui_evidence "Feedback Types" "UI feedback types var"
check_ui_evidence "Status Flow" "UI status flow var"
check_ui_evidence "Required Fields" "UI required fields var"
check_ui_evidence "tenant_id" "UI tenant_id var"
check_ui_evidence "owner" "UI owner var"
check_ui_evidence "resolution_note" "UI resolution note var"
check_ui_evidence "viewport" "UI responsive viewport var"
check_ui_evidence "@media" "UI mobile media query var"

if [ "$DOC_EVIDENCE_COUNT" -lt 13 ]; then
  fail_soft "support feedback dokuman kaniti yetersiz: $DOC_EVIDENCE_COUNT/13"
else
  pass "support feedback dokuman kaniti yeterli: $DOC_EVIDENCE_COUNT/13"
fi

if [ "$UI_EVIDENCE_COUNT" -lt 18 ]; then
  fail_soft "support feedback UI kaniti yetersiz: $UI_EVIDENCE_COUNT/19"
else
  pass "support feedback UI kaniti yeterli: $UI_EVIDENCE_COUNT/19"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP14_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP14_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_13_TEST_STATUS=$FINAL_STATUS
FAZ_4D_13_SUPPORT_FEEDBACK_LOOP_STATUS=$FINAL_STATUS
FAZ_4D_13_DOC_EVIDENCE_COUNT=$DOC_EVIDENCE_COUNT
FAZ_4D_13_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_13_OK_COUNT=$OK_COUNT
FAZ_4D_13_WARN_COUNT=$WARN_COUNT
FAZ_4D_13_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_14_READY=$STEP14_READY
UI_FILE=$UI_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-13 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-13 TEST SONUCU ====="
  echo "FAZ_4D_13_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_13_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_13_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_14_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-13 TEST SONUCU ====="
  echo "FAZ_4D_13_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_13_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_13_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_14_READY=NO ❌"
  exit 1
fi
