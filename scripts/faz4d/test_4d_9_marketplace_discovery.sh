#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP8_REPORT="reports/faz4d/FAZ_4D_8_BARCODE_OPTIONAL_UI_NOTE_REPORT.txt"
STEP9_FILE="docs/faz4d/FAZ_4D_9_MARKETPLACE_DISCOVERY.md"
UI_FILE="web/marketplace-discovery/index.html"
REPORT_FILE="reports/faz4d/FAZ_4D_9_MARKETPLACE_DISCOVERY_REPORT.txt"

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

  if grep -Fq "$pattern" "$STEP9_FILE"; then
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

echo "===== FAZ 4D-9 MARKETPLACE DISCOVERY TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP8_REPORT"
check_file "$STEP9_FILE"
check_file "$UI_FILE"

check_grep_file "$MASTER_FILE" "4D-8 | Barkod opsiyonel UI notu | DONE ✅" "4D-8 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-9 | Marketplace discovery | IN_PROGRESS" "4D-9 master planda IN_PROGRESS"
check_grep_file "$STEP8_REPORT" "FAZ_4D_8_TEST_STATUS=PASS" "4D-8 test raporu PASS"

echo
echo "===== DOKUMAN KANIT TARAMASI ====="

check_doc_evidence "Marketplace bu fazda discovery kalır" "marketplace discovery karari var"
check_doc_evidence "Ürün yayınlama hazırlığı tanımlanır" "urun yayinlama karari var"
check_doc_evidence "Tenant izolasyonu zorunludur" "tenant izolasyonu karari var"
check_doc_evidence "Stok senkronu sonraki faza bırakılır" "stok senkronu sonraki faz karari var"
check_doc_evidence "Fiyat senkronu sonraki faza bırakılır" "fiyat senkronu sonraki faz karari var"
check_doc_evidence "Sipariş alma production yapılmaz" "siparis production kapali karari var"
check_doc_evidence "Komisyon modeli FAZ 5 ticari hazırlığa taşınır" "komisyon FAZ 5 karari var"
check_doc_evidence "Oto yedek parça uyumu keşfedilir" "oto yedek parca marketplace karari var"
check_doc_evidence "Paraşüt ile çakışma engellenir" "parasut cakisma karari var"
check_doc_evidence "FAZ_4D_10_READY=NO" "4D-10 baslangicta NO"

echo
echo "===== UI DISCOVERY KANIT TARAMASI ====="

check_ui_evidence "Marketplace Discovery" "UI basligi var"
check_ui_evidence "DISCOVERY" "UI discovery etiketi var"
check_ui_evidence "Gerçek Sipariş" "UI gercek siparis kapali var"
check_ui_evidence "Ödeme/Komisyon" "UI odeme komisyon kapali var"
check_ui_evidence "Tenant Isolation" "UI tenant isolation var"
check_ui_evidence "Ürün Yayınlama Hazırlığı" "UI urun yayinlama var"
check_ui_evidence "Tenant / Seller Ayrımı" "UI tenant seller ayrimi var"
check_ui_evidence "Stok Senkronu" "UI stok senkronu var"
check_ui_evidence "Fiyat Senkronu" "UI fiyat senkronu var"
check_ui_evidence "Sipariş Alma" "UI siparis alma var"
check_ui_evidence "Komisyon Modeli" "UI komisyon modeli var"
check_ui_evidence "Oto Yedek Parça Avantajı" "UI oto yedek parca avantaji var"
check_ui_evidence "Public API / Webhook" "UI public API webhook var"
check_ui_evidence "Paraşüt Çakışması" "UI parasut cakismasi var"
check_ui_evidence "ERP Core" "UI ERP core ayrimi var"
check_ui_evidence "Marketplace Layer" "UI marketplace layer ayrimi var"
check_ui_evidence "Integration Layer" "UI integration layer ayrimi var"
check_ui_evidence "Reporting Layer" "UI reporting layer ayrimi var"
check_ui_evidence "viewport" "UI responsive viewport var"
check_ui_evidence "@media" "UI mobile media query var"

if [ "$DOC_EVIDENCE_COUNT" -lt 10 ]; then
  fail_soft "marketplace dokuman kaniti yetersiz: $DOC_EVIDENCE_COUNT/10"
else
  pass "marketplace dokuman kaniti yeterli: $DOC_EVIDENCE_COUNT/10"
fi

if [ "$UI_EVIDENCE_COUNT" -lt 18 ]; then
  fail_soft "marketplace UI kaniti yetersiz: $UI_EVIDENCE_COUNT/20"
else
  pass "marketplace UI kaniti yeterli: $UI_EVIDENCE_COUNT/20"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP10_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP10_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_9_TEST_STATUS=$FINAL_STATUS
FAZ_4D_9_MARKETPLACE_DISCOVERY_STATUS=$FINAL_STATUS
FAZ_4D_9_DOC_EVIDENCE_COUNT=$DOC_EVIDENCE_COUNT
FAZ_4D_9_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_9_OK_COUNT=$OK_COUNT
FAZ_4D_9_WARN_COUNT=$WARN_COUNT
FAZ_4D_9_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_10_READY=$STEP10_READY
UI_FILE=$UI_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-9 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-9 TEST SONUCU ====="
  echo "FAZ_4D_9_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_9_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_9_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_10_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-9 TEST SONUCU ====="
  echo "FAZ_4D_9_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_9_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_9_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_10_READY=NO ❌"
  exit 1
fi
