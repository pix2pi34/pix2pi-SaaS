#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP3_REPORT="reports/faz4d/FAZ_4D_3_BUSINESS_CHAIN_FINAL_VALIDATION_REPORT.txt"
STEP4_FILE="docs/faz4d/FAZ_4D_4_ERP_CORE_PRODUCT_APPLY_STAGING_CORE_DECISIONS.md"
REPORT_FILE="reports/faz4d/FAZ_4D_4_ERP_CORE_PRODUCT_APPLY_STAGING_CORE_DECISIONS_REPORT.txt"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
ERP_EVIDENCE_COUNT=0

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
    -- "$pattern" "${SEARCH_DIRS[@]}" >/tmp/pix2pi_4d4_grep_result.txt 2>/dev/null
}

check_erp_evidence() {
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
    ERP_EVIDENCE_COUNT=$((ERP_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    warn "$label"
  fi
}

echo "===== FAZ 4D-4 ERP CORE PRODUCT APPLY / STAGING CORE DECISIONS TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP3_REPORT"
check_file "$STEP4_FILE"

check_grep_file "$MASTER_FILE" "4D-3 | Business Chain Final Validation | DONE ✅" "4D-3 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-4 | ERP core product apply / staging → core kararları | IN_PROGRESS" "4D-4 master planda IN_PROGRESS"
check_grep_file "$STEP3_REPORT" "FAZ_4D_3_TEST_STATUS=PASS" "4D-3 test raporu PASS"

check_grep_file "$STEP4_FILE" "Ürün master core kalır" "urun master karari var"
check_grep_file "$STEP4_FILE" "Stok etkisi zorunlu karar alanıdır" "stok etkisi karari var"
check_grep_file "$STEP4_FILE" "Satış/sipariş ERP apply hattına bağlanır" "satis siparis ERP apply karari var"
check_grep_file "$STEP4_FILE" "Event/audit izi zorunludur" "event audit karari var"
check_grep_file "$STEP4_FILE" "Journal/ledger pilotta staging kabul edilir" "journal ledger staging karari var"
check_grep_file "$STEP4_FILE" "TDHP mapping core kararına bağlanır" "TDHP mapping karari var"
check_grep_file "$STEP4_FILE" "Oto yedek parça detayları extension kalır" "oto yedek parca extension karari var"
check_grep_file "$STEP4_FILE" "Tenant-aware apply zorunludur" "tenant-aware apply karari var"
check_grep_file "$STEP4_FILE" "Idempotent apply hedeflenir" "idempotent apply karari var"
check_grep_file "$STEP4_FILE" "FAZ_4D_5_READY=NO" "4D-5 baslangicta NO"

build_search_dirs

echo
echo "===== REPO ERP CORE / APPLY KANIT TARAMASI ====="

check_erp_evidence "product / item izi var" "product" "Product" "item" "Item" "urun" "Urun"
check_erp_evidence "stock / inventory izi var" "stock" "Stock" "inventory" "Inventory" "stok" "Stok"
check_erp_evidence "sale / order izi var" "sale" "Sale" "order" "Order" "satis" "Satis"
check_erp_evidence "ERP / UFK izi var" "ERP" "erp" "UFK" "ufk"
check_erp_evidence "journal / ledger izi var" "journal" "Journal" "ledger" "Ledger"
check_erp_evidence "event / audit izi var" "event" "Event" "audit" "Audit"
check_erp_evidence "tenant izi var" "tenant_id" "TenantID" "TenantId" "X-Tenant-ID"
check_erp_evidence "idempotency / duplicate koruma izi var" "idempot" "Idempot" "duplicate" "Duplicate"
check_erp_evidence "TDHP / hesap plani izi var" "TDHP" "tdhp" "hesap" "account" "Account"

if [ "$ERP_EVIDENCE_COUNT" -lt 4 ]; then
  fail_soft "ERP core/apply repo kaniti yetersiz: $ERP_EVIDENCE_COUNT/9"
else
  pass "ERP core/apply repo kaniti yeterli: $ERP_EVIDENCE_COUNT/9"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP5_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP5_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_4_TEST_STATUS=$FINAL_STATUS
FAZ_4D_4_ERP_CORE_PRODUCT_APPLY_STAGING_CORE_DECISIONS_STATUS=$FINAL_STATUS
FAZ_4D_4_ERP_EVIDENCE_COUNT=$ERP_EVIDENCE_COUNT
FAZ_4D_4_OK_COUNT=$OK_COUNT
FAZ_4D_4_WARN_COUNT=$WARN_COUNT
FAZ_4D_4_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_5_READY=$STEP5_READY
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-4 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-4 TEST SONUCU ====="
  echo "FAZ_4D_4_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_4_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_4_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_5_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-4 TEST SONUCU ====="
  echo "FAZ_4D_4_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_4_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_4_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_5_READY=NO ❌"
  exit 1
fi
