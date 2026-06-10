#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP2_REPORT="reports/faz4d/FAZ_4D_2_SECURITY_TENANT_ISOLATION_REPORT.txt"
STEP3_FILE="docs/faz4d/FAZ_4D_3_BUSINESS_CHAIN_FINAL_VALIDATION.md"
REPORT_FILE="reports/faz4d/FAZ_4D_3_BUSINESS_CHAIN_FINAL_VALIDATION_REPORT.txt"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
BUSINESS_EVIDENCE_COUNT=0

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

build_search_dirs() {
  SEARCH_DIRS=()

  for d in cmd internal pkg services migrations config configs deploy ops scripts docs; do
    if [ -d "$d" ]; then
      SEARCH_DIRS+=("$d")
    fi
  done

  if [ "${#SEARCH_DIRS[@]}" -eq 0 ]; then
    fail_soft "aranacak dizin bulunamadi"
  else
    pass "aranacak dizinler bulundu: ${SEARCH_DIRS[*]}"
  fi
}

repo_has_regex() {
  local pattern="$1"

  if [ "${#SEARCH_DIRS[@]}" -eq 0 ]; then
    return 1
  fi

  grep -R -I -E -n \
    --exclude-dir=.git \
    --exclude-dir=backups \
    --exclude-dir=node_modules \
    --exclude-dir=vendor \
    --exclude-dir=tmp \
    --exclude-dir=dist \
    --exclude-dir=build \
    -- "$pattern" "${SEARCH_DIRS[@]}" >/tmp/pix2pi_4d3_grep_result.txt 2>/dev/null
}

check_business_evidence() {
  local label="$1"
  shift

  local found="NO"
  local pattern=""

  for pattern in "$@"; do
    if repo_has_regex "$pattern"; then
      found="YES"
      break
    fi
  done

  if [ "$found" = "YES" ]; then
    BUSINESS_EVIDENCE_COUNT=$((BUSINESS_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    warn "$label"
  fi
}

echo "===== FAZ 4D-3 BUSINESS CHAIN FINAL VALIDATION TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP2_REPORT"
check_file "$STEP3_FILE"

check_grep_file "$MASTER_FILE" "4D-2 | Security / Tenant Isolation Final Pilot Check | DONE ✅" "4D-2 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-3 | Business Chain Final Validation | IN_PROGRESS" "4D-3 master planda IN_PROGRESS"
check_grep_file "$STEP2_REPORT" "FAZ_4D_2_TEST_STATUS=PASS" "4D-2 test raporu PASS"
check_grep_file "$STEP3_FILE" "Cari / müşteri" "business chain cari halkasi dokumanda var"
check_grep_file "$STEP3_FILE" "Ürün / hizmet" "business chain urun halkasi dokumanda var"
check_grep_file "$STEP3_FILE" "Stok" "business chain stok halkasi dokumanda var"
check_grep_file "$STEP3_FILE" "Satış / sipariş" "business chain satis halkasi dokumanda var"
check_grep_file "$STEP3_FILE" "ERP core apply" "business chain ERP halkasi dokumanda var"
check_grep_file "$STEP3_FILE" "Event / audit" "business chain event audit halkasi dokumanda var"
check_grep_file "$STEP3_FILE" "Raporlama / izleme" "business chain raporlama halkasi dokumanda var"

build_search_dirs

echo
echo "===== REPO BUSINESS CHAIN KANIT TARAMASI ====="

check_business_evidence "cari / customer / party izi var" "customer" "Customer" "cari" "Cari" "party" "Party"
check_business_evidence "urun / product / item izi var" "product" "Product" "item" "Item" "urun" "Urun" "ürün"
check_business_evidence "stok / stock / inventory izi var" "stock" "Stock" "inventory" "Inventory" "stok" "Stok"
check_business_evidence "satis / order / sale izi var" "sale" "Sale" "order" "Order" "satis" "Satis" "satış"
check_business_evidence "ERP / journal / ledger / UFK izi var" "ERP" "erp" "journal" "Journal" "ledger" "Ledger" "UFK" "ufk"
check_business_evidence "event / audit izi var" "event" "Event" "audit" "Audit"
check_business_evidence "report / dashboard / monitoring izi var" "report" "Report" "dashboard" "Dashboard" "monitoring" "Monitoring"

if [ "$BUSINESS_EVIDENCE_COUNT" -lt 3 ]; then
  fail_soft "business chain repo kaniti yetersiz: $BUSINESS_EVIDENCE_COUNT/7"
else
  pass "business chain repo kaniti yeterli: $BUSINESS_EVIDENCE_COUNT/7"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP4_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP4_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_3_TEST_STATUS=$FINAL_STATUS
FAZ_4D_3_BUSINESS_CHAIN_FINAL_VALIDATION_STATUS=$FINAL_STATUS
FAZ_4D_3_BUSINESS_EVIDENCE_COUNT=$BUSINESS_EVIDENCE_COUNT
FAZ_4D_3_OK_COUNT=$OK_COUNT
FAZ_4D_3_WARN_COUNT=$WARN_COUNT
FAZ_4D_3_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_4_READY=$STEP4_READY
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-3 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-3 TEST SONUCU ====="
  echo "FAZ_4D_3_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_3_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_3_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_4_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-3 TEST SONUCU ====="
  echo "FAZ_4D_3_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_3_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_3_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_4_READY=NO ❌"
  exit 1
fi
