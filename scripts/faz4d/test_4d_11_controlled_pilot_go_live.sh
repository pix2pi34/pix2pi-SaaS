#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP10_REPORT="reports/faz4d/FAZ_4D_10_PARASUT_DISCOVERY_REPORT.txt"
STEP11_FILE="docs/faz4d/FAZ_4D_11_CONTROLLED_PILOT_GO_LIVE.md"
UI_FILE="web/pilot-go-live/index.html"
REPORT_FILE="reports/faz4d/FAZ_4D_11_CONTROLLED_PILOT_GO_LIVE_REPORT.txt"

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

  if grep -Fq "$pattern" "$STEP11_FILE"; then
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

echo "===== FAZ 4D-11 CONTROLLED PILOT GO-LIVE TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP10_REPORT"
check_file "$STEP11_FILE"
check_file "$UI_FILE"

check_grep_file "$MASTER_FILE" "4D-10 | Paraşüt discovery | DONE ✅" "4D-10 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-11 | Controlled Pilot Go-Live | IN_PROGRESS" "4D-11 master planda IN_PROGRESS"
check_grep_file "$STEP10_REPORT" "FAZ_4D_10_TEST_STATUS=PASS" "4D-10 test raporu PASS"

echo
echo "===== DOKUMAN KANIT TARAMASI ====="

check_doc_evidence "Go-live kontrollü pilot olarak açılır" "controlled pilot karari var"
check_doc_evidence "Pilot tenant sayısı sınırlı tutulur" "pilot tenant sinir karari var"
check_doc_evidence "Pilot kullanıcı sayısı sınırlı tutulur" "pilot kullanici sinir karari var"
check_doc_evidence "Tenant isolation korunur" "tenant isolation karari var"
check_doc_evidence "Business UI pilot yüzeyden başlar" "business UI karari var"
check_doc_evidence "Marketplace production kapalı kalır" "marketplace production kapali karari var"
check_doc_evidence "Paraşüt production kapalı kalır" "parasut production kapali karari var"
check_doc_evidence "Barkod opsiyonel kalır" "barkod opsiyonel karari var"
check_doc_evidence "Monitoring zorunlu sonraki adımdır" "monitoring sonraki adim karari var"
check_doc_evidence "Support feedback loop zorunlu sonraki adımdır" "support feedback sonraki adim karari var"
check_doc_evidence "Release/rollback gate zorunlu kapanış kapısıdır" "release rollback gate karari var"
check_doc_evidence "Kritik hata olursa no-go uygulanır" "no-go karari var"
check_doc_evidence "FAZ_4D_12_READY=NO" "4D-12 baslangicta NO"

echo
echo "===== UI GO-LIVE KANIT TARAMASI ====="

check_ui_evidence "Controlled Pilot Go-Live" "UI basligi var"
check_ui_evidence "CONTROLLED PILOT" "UI controlled pilot etiketi var"
check_ui_evidence "Tenant Kapsamı" "UI tenant kapsami var"
check_ui_evidence "Kullanıcı Kapsamı" "UI kullanici kapsami var"
check_ui_evidence "Public Launch" "UI public launch kapali var"
check_ui_evidence "No-Go" "UI no-go var"
check_ui_evidence "Pilot Tenant" "UI pilot tenant var"
check_ui_evidence "Pilot Kullanıcı" "UI pilot kullanici var"
check_ui_evidence "Business UI" "UI business UI var"
check_ui_evidence "Oto Yedek Parça" "UI oto yedek parca var"
check_ui_evidence "Marketplace Kapalı" "UI marketplace kapali var"
check_ui_evidence "Paraşüt Kapalı" "UI parasut kapali var"
check_ui_evidence "No-Go Tetikleyicileri" "UI no-go tetikleyicileri var"
check_ui_evidence "Monitoring" "UI monitoring var"
check_ui_evidence "Rollback" "UI rollback var"
check_ui_evidence "Next Gates" "UI next gates var"
check_ui_evidence "viewport" "UI responsive viewport var"
check_ui_evidence "@media" "UI mobile media query var"

if [ "$DOC_EVIDENCE_COUNT" -lt 13 ]; then
  fail_soft "controlled pilot go-live dokuman kaniti yetersiz: $DOC_EVIDENCE_COUNT/13"
else
  pass "controlled pilot go-live dokuman kaniti yeterli: $DOC_EVIDENCE_COUNT/13"
fi

if [ "$UI_EVIDENCE_COUNT" -lt 17 ]; then
  fail_soft "controlled pilot go-live UI kaniti yetersiz: $UI_EVIDENCE_COUNT/18"
else
  pass "controlled pilot go-live UI kaniti yeterli: $UI_EVIDENCE_COUNT/18"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP12_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP12_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_11_TEST_STATUS=$FINAL_STATUS
FAZ_4D_11_CONTROLLED_PILOT_GO_LIVE_STATUS=$FINAL_STATUS
FAZ_4D_11_DOC_EVIDENCE_COUNT=$DOC_EVIDENCE_COUNT
FAZ_4D_11_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_11_OK_COUNT=$OK_COUNT
FAZ_4D_11_WARN_COUNT=$WARN_COUNT
FAZ_4D_11_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_12_READY=$STEP12_READY
UI_FILE=$UI_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-11 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-11 TEST SONUCU ====="
  echo "FAZ_4D_11_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_11_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_11_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_12_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-11 TEST SONUCU ====="
  echo "FAZ_4D_11_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_11_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_11_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_12_READY=NO ❌"
  exit 1
fi
