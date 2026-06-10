#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP9_REPORT="reports/faz4d/FAZ_4D_9_MARKETPLACE_DISCOVERY_REPORT.txt"
STEP10_FILE="docs/faz4d/FAZ_4D_10_PARASUT_DISCOVERY.md"
UI_FILE="web/parasut-discovery/index.html"
REPORT_FILE="reports/faz4d/FAZ_4D_10_PARASUT_DISCOVERY_REPORT.txt"

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

  if grep -Fq "$pattern" "$STEP10_FILE"; then
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

echo "===== FAZ 4D-10 PARASUT DISCOVERY TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP9_REPORT"
check_file "$STEP10_FILE"
check_file "$UI_FILE"

check_grep_file "$MASTER_FILE" "4D-9 | Marketplace discovery | DONE ✅" "4D-9 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-10 | Paraşüt discovery | IN_PROGRESS" "4D-10 master planda IN_PROGRESS"
check_grep_file "$STEP9_REPORT" "FAZ_4D_9_TEST_STATUS=PASS" "4D-9 test raporu PASS"

echo
echo "===== DOKUMAN KANIT TARAMASI ====="

check_doc_evidence "Paraşüt bu fazda discovery kalır" "parasut discovery karari var"
check_doc_evidence "Pix2pi ERP core ana kaynak kalır" "Pix2pi ana kaynak karari var"
check_doc_evidence "Cari/müşteri eşleme keşfedilir" "cari musteri mapping karari var"
check_doc_evidence "Ürün/hizmet eşleme keşfedilir" "urun hizmet mapping karari var"
check_doc_evidence "Satış/fatura akışı keşfedilir" "satis fatura akisi karari var"
check_doc_evidence "Tahsilat/ödeme akışı keşfedilir" "tahsilat odeme akisi karari var"
check_doc_evidence "TDHP ve muhasebe mapping korunur" "TDHP muhasebe mapping karari var"
check_doc_evidence "e-Fatura/e-Arşiv ayrı tutulur" "e-belge ayri tutulur karari var"
check_doc_evidence "Credential/secret repo içine yazılmaz" "credential secret yasak karari var"
check_doc_evidence "Tenant-aware integration zorunludur" "tenant-aware integration karari var"
check_doc_evidence "Marketplace ile karıştırılmaz" "marketplace ayrimi karari var"
check_doc_evidence "FAZ_4D_11_READY=NO" "4D-11 baslangicta NO"

echo
echo "===== UI DISCOVERY KANIT TARAMASI ====="

check_ui_evidence "Paraşüt Discovery" "UI basligi var"
check_ui_evidence "DISCOVERY" "UI discovery etiketi var"
check_ui_evidence "Gerçek API Çağrısı" "UI gercek API kapali var"
check_ui_evidence "Credential" "UI credential notu var"
check_ui_evidence "Pix2pi ERP Core" "UI Pix2pi ERP core var"
check_ui_evidence "Cari / Müşteri Eşleme" "UI cari musteri esleme var"
check_ui_evidence "Ürün / Hizmet Eşleme" "UI urun hizmet esleme var"
check_ui_evidence "Satış / Fatura Akışı" "UI satis fatura akisi var"
check_ui_evidence "Tahsilat / Ödeme" "UI tahsilat odeme var"
check_ui_evidence "TDHP / UFK Koruması" "UI TDHP UFK korumasi var"
check_ui_evidence "e-Fatura / e-Arşiv" "UI e-fatura e-arsiv var"
check_ui_evidence "Tenant-aware Integration" "UI tenant-aware integration var"
check_ui_evidence "Secret / Credential Policy" "UI secret credential policy var"
check_ui_evidence "Marketplace Ayrımı" "UI marketplace ayrimi var"
check_ui_evidence "Mapping Layer" "UI mapping layer var"
check_ui_evidence "Integration Layer" "UI integration layer var"
check_ui_evidence "Security Layer" "UI security layer var"
check_ui_evidence "viewport" "UI responsive viewport var"
check_ui_evidence "@media" "UI mobile media query var"

if [ "$DOC_EVIDENCE_COUNT" -lt 12 ]; then
  fail_soft "parasut dokuman kaniti yetersiz: $DOC_EVIDENCE_COUNT/12"
else
  pass "parasut dokuman kaniti yeterli: $DOC_EVIDENCE_COUNT/12"
fi

if [ "$UI_EVIDENCE_COUNT" -lt 18 ]; then
  fail_soft "parasut UI kaniti yetersiz: $UI_EVIDENCE_COUNT/19"
else
  pass "parasut UI kaniti yeterli: $UI_EVIDENCE_COUNT/19"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP11_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP11_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_10_TEST_STATUS=$FINAL_STATUS
FAZ_4D_10_PARASUT_DISCOVERY_STATUS=$FINAL_STATUS
FAZ_4D_10_DOC_EVIDENCE_COUNT=$DOC_EVIDENCE_COUNT
FAZ_4D_10_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_10_OK_COUNT=$OK_COUNT
FAZ_4D_10_WARN_COUNT=$WARN_COUNT
FAZ_4D_10_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_11_READY=$STEP11_READY
UI_FILE=$UI_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-10 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-10 TEST SONUCU ====="
  echo "FAZ_4D_10_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_10_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_10_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_11_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-10 TEST SONUCU ====="
  echo "FAZ_4D_10_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_10_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_10_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_11_READY=NO ❌"
  exit 1
fi
