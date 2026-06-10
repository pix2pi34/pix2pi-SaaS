#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="docs/pilot/faz4c/4c_5a_data_import_scope.env"
DOC_FILE="docs/pilot/faz4c/4c_5_real_pilot_data_entry_import.md"
CSV_FILE="docs/pilot/faz4c/4c_5a_product_import_template.csv"
IMPORT_CSV="imports/pilot/faz4c/uzmanparcaci/product_import_template.csv"

PREV_REPORT="reports/pilot/faz4c/4c_4i_user_role_assignment_final_closure_report.md"
PREV_DOC="docs/pilot/faz4c/4c_4_final_closure.md"

REPORT_FILE="reports/pilot/faz4c/4c_5a_data_import_scope_freeze_report.md"

echo "===== 4C-5A DATA ENTRY / IMPORT SCOPE FREEZE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-4I final closure report yok: $PREV_REPORT"
pass "4C-4I final closure report var"

grep -q "4C_4_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-4 final PASS degil"
pass "4C-4 final PASS"

grep -q "4C_5_READY=YES" "$PREV_REPORT" || fail "4C-5 ready YES degil"
pass "4C-5 ready YES"

[ -f "$PREV_DOC" ] || fail "4C-4 final closure doc yok: $PREV_DOC"
pass "4C-4 final closure doc var"

grep -q "4C_4_PILOT_USER_EMAIL=uzmanparcaci1@gmail.com" "$PREV_DOC" || fail "Pilot user email yok"
pass "Pilot user email var"

grep -q "4C_4_PILOT_ROLE_CODE=PILOT_ADMIN" "$PREV_DOC" || fail "Pilot role code yok"
pass "Pilot role code var"

[ -f "$ENV_FILE" ] || fail "4C-5A env dosyasi yok"
pass "4C-5A env dosyasi var"

[ -f "$DOC_FILE" ] || fail "4C-5 ana dokuman yok"
pass "4C-5 ana dokuman var"

[ -f "$CSV_FILE" ] || fail "CSV template yok"
pass "CSV template var"

[ -f "$IMPORT_CSV" ] || fail "Import CSV kopyasi yok"
pass "Import CSV kopyasi var"

grep -q '^TENANT_BUSINESS_CODE="UZMANPARCACI"' "$ENV_FILE" || fail "TENANT_BUSINESS_CODE UZMANPARCACI degil"
pass "TENANT_BUSINESS_CODE UZMANPARCACI"

grep -q '^PILOT_BUSINESS_NAME="uzmanparcaci"' "$ENV_FILE" || fail "Pilot business uzmanparcaci degil"
pass "Pilot business uzmanparcaci"

grep -q '^PILOT_SECTOR="OTO_YEDEK_PARCA"' "$ENV_FILE" || fail "Pilot sector OTO_YEDEK_PARCA degil"
pass "Pilot sector OTO_YEDEK_PARCA"

grep -q '^IMPORT_TARGET_ENTITY="PRODUCT_STOCK"' "$ENV_FILE" || fail "Import target PRODUCT_STOCK degil"
pass "Import target PRODUCT_STOCK"

grep -q '^INITIAL_PRODUCT_SAMPLE_TARGET="200"' "$ENV_FILE" || fail "Initial sample target 200 degil"
pass "Initial sample target 200"

grep -q '^FULL_STOCK_ESTIMATE="1000"' "$ENV_FILE" || fail "Full stock estimate 1000 degil"
pass "Full stock estimate 1000"

grep -q '^BARCODE_REQUIRED_FOR_PILOT="NO"' "$ENV_FILE" || fail "Barcode required NO degil"
pass "Barcode required NO"

grep -q '^MARKETPLACE_LIVE_INTEGRATION="NO"' "$ENV_FILE" || fail "Marketplace live integration NO degil"
pass "Marketplace live integration NO"

grep -q '^MARKETPLACE_PHASE="FAZ_4D"' "$ENV_FILE" || fail "Marketplace phase FAZ_4D degil"
pass "Marketplace phase FAZ_4D"

grep -q '^DATA_IMPORT_DB_WRITE_APPLIED="NO"' "$ENV_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "product_name,sku,category,unit,initial_stock_qty,sale_price,purchase_price,currency,oem_code,equivalent_code,vehicle_fitment_note,brand,part_group,barcode,notes" "$CSV_FILE" || fail "CSV header beklenen sekilde degil"
pass "CSV header beklenen sekilde"

grep -q "oem_code" "$DOC_FILE" || fail "Dokumanda oem_code yok"
pass "Dokumanda oem_code var"

grep -q "equivalent_code" "$DOC_FILE" || fail "Dokumanda equivalent_code yok"
pass "Dokumanda equivalent_code var"

grep -q "vehicle_fitment_note" "$DOC_FILE" || fail "Dokumanda vehicle_fitment_note yok"
pass "Dokumanda vehicle_fitment_note var"

grep -q "4C_5A_DATA_IMPORT_SCOPE_STATUS=PASS" "$DOC_FILE" || fail "4C-5A status PASS yok"
pass "4C-5A status PASS var"

grep -q "4C_5B_READY=YES" "$DOC_FILE" || fail "4C-5B ready YES yok"
pass "4C-5B ready YES var"

PENDING_COUNT="$( (grep -h -o 'PENDING' "$ENV_FILE" "$DOC_FILE" "$CSV_FILE" 2>/dev/null || true) | wc -l | tr -d ' ' )"
if [ "$PENDING_COUNT" != "0" ]; then
  echo "===== PENDING DETAY ====="
  grep -n 'PENDING' "$ENV_FILE" "$DOC_FILE" "$CSV_FILE" || true
  fail "4C-5A dosyalarinda PENDING kalmis: $PENDING_COUNT"
fi
pass "4C-5A dosyalarinda PENDING yok"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-5A Data Entry / Import Scope Freeze Report

Step: 4C-5A
Blok: Data Entry / Import Scope Freeze
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5A_DATA_IMPORT_SCOPE_STATUS=PASS
4C_5A_PREVIOUS_BLOCK_STATUS=PASS
4C_5A_TENANT_BUSINESS_CODE=UZMANPARCACI
4C_5A_TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439
4C_5A_PILOT_BUSINESS_NAME=uzmanparcaci
4C_5A_PILOT_SECTOR=OTO_YEDEK_PARCA
4C_5A_IMPORT_TARGET_ENTITY=PRODUCT_STOCK
4C_5A_IMPORT_SOURCE_TYPE=MANUAL_CSV_TEMPLATE
4C_5A_INITIAL_PRODUCT_SAMPLE_TARGET=200
4C_5A_FULL_STOCK_ESTIMATE=1000
4C_5A_TEMPLATE_CREATED=YES
4C_5A_IMPORT_TEMPLATE_PATH=imports/pilot/faz4c/uzmanparcaci/product_import_template.csv
4C_5A_BARCODE_REQUIRED_FOR_PILOT=NO
4C_5A_MARKETPLACE_LIVE_INTEGRATION=NO
4C_5A_MARKETPLACE_PHASE=FAZ_4D
4C_5A_PENDING_COUNT=0
4C_5A_DB_WRITE_APPLIED=NO
4C_5B_READY=YES

## Sonuc

uzmanparcaci pilot veri giris/import kapsami donduruldu.
CSV import template olusturuldu.
Bu adimda DB yazma islemi yapilmadi.
Sonraki adim: 4C-5B Import Template Structure Precheck.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-5A TEST SONUCU ====="
echo "4C_5A_DATA_IMPORT_SCOPE_STATUS=PASS ✅"
echo "4C_5A_PILOT_BUSINESS_NAME=uzmanparcaci ✅"
echo "4C_5A_PILOT_SECTOR=OTO_YEDEK_PARCA ✅"
echo "4C_5A_IMPORT_TARGET_ENTITY=PRODUCT_STOCK ✅"
echo "4C_5A_INITIAL_PRODUCT_SAMPLE_TARGET=200 ✅"
echo "4C_5A_TEMPLATE_CREATED=YES ✅"
echo "4C_5A_PENDING_COUNT=0 ✅"
echo "4C_5A_DB_WRITE_APPLIED=NO ✅"
echo "4C_5B_READY=YES ✅"
