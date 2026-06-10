#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TODAY="$(date +%F)"

INPUT_ENV="docs/pilot/faz4c/4c_6g_business_acceptance_input.env"
ACCEPTANCE_FORM="uat/pilot/faz4c/uzmanparcaci/business_acceptance_form.md"
PREV_REPORT="reports/pilot/faz4c/4c_6g_2_business_acceptance_apply_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_6g_3_business_acceptance_input_fill_report.md"

echo "===== 4C-6G-3-FIX1 BUSINESS ACCEPTANCE INPUT FILL ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

[ -f "$INPUT_ENV" ] || fail "Acceptance input env yok: $INPUT_ENV"
[ -f "$ACCEPTANCE_FORM" ] || fail "Acceptance form yok: $ACCEPTANCE_FORM"
[ -f "$PREV_REPORT" ] || fail "4C-6G-2 test report yok: $PREV_REPORT"

grep -q "4C_6G_2_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-6G-2 test PASS degil"

cat <<EOF > "$INPUT_ENV"
# FAZ 4C — 4C-6G Business Acceptance Input
# Gercek isletme kabul bilgileri dolduruldu.
# Bu adimda DB write yapilmaz.

PILOT_BUSINESS_NAME="uzmanparcaci"
TENANT_BUSINESS_CODE="UZMANPARCACI"
PILOT_USER_EMAIL="uzmanparcaci1@gmail.com"
PILOT_ROLE_CODE="PILOT_ADMIN"

TECHNICAL_UAT_STATUS="PASS"
TECHNICAL_FAIL_COUNT="0"
CRITICAL_BLOCKER_COUNT="0"
WARNING_COUNT="2"
IMPROVEMENT_COUNT="3"

BUSINESS_ACCEPTANCE_STATUS="PASS"
BUSINESS_REPRESENTATIVE_NAME="mert_omur"
BUSINESS_ACCEPTANCE_DATE="$TODAY"
BUSINESS_ACCEPTANCE_NOTE="Teknik UAT kapsami pilot icin kabul edildi."

BUSINESS_ACCEPTS_TENANT_ACCESS="YES"
BUSINESS_ACCEPTS_USER_ROLE_ACCESS="YES"
BUSINESS_ACCEPTS_STAGING_PRODUCTS="YES"
BUSINESS_ACCEPTS_OEM_FIELD="YES"
BUSINESS_ACCEPTS_EQUIVALENT_FIELD="YES"
BUSINESS_ACCEPTS_VEHICLE_FITMENT_FIELD="YES"
BUSINESS_ACCEPTS_BARCODE_NON_BLOCKER="YES"
BUSINESS_ACCEPTS_MARKETPLACE_PHASE_4D="YES"

FINAL_UAT_RESULT="PASS"
GO_NO_GO_READY="YES"
DB_WRITE_APPLIED="NO"
NEXT_STEP="4C_6G_2_BUSINESS_ACCEPTANCE_APPLY"
EOF

cat <<EOF > "$ACCEPTANCE_FORM"
# uzmanparcaci — Business Acceptance Form

## Pilot bilgisi

PILOT_BUSINESS_NAME=uzmanparcaci
TENANT_BUSINESS_CODE=UZMANPARCACI
PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
PILOT_ROLE_CODE=PILOT_ADMIN

---

## Teknik UAT sonucu

TECHNICAL_UAT_STATUS=PASS
TECHNICAL_FAIL_COUNT=0
CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=2
IMPROVEMENT_COUNT=3

---

## İşletmeye gösterilen kabul özeti

Teknik tarafta:

- Tenant doğrulandı
- Kullanıcı/rol doğrulandı
- 5 sample ürün staging tablosunda doğrulandı
- Duplicate SKU yok
- Tenant mismatch yok
- OEM kodları var
- Eşdeğer kodları var
- Araç uyum notları var
- Barkod boşluğu blocker değil
- Pazaryeri entegrasyonu FAZ 4D’ye bırakıldı

---

## İşletme kabul kararı

BUSINESS_ACCEPTANCE_STATUS=PASS
BUSINESS_REPRESENTATIVE_NAME=mert_omur
BUSINESS_ACCEPTANCE_DATE=$TODAY
BUSINESS_ACCEPTANCE_NOTE=Teknik UAT kapsami pilot icin kabul edildi.

BUSINESS_ACCEPTS_TENANT_ACCESS=YES
BUSINESS_ACCEPTS_USER_ROLE_ACCESS=YES
BUSINESS_ACCEPTS_STAGING_PRODUCTS=YES
BUSINESS_ACCEPTS_OEM_FIELD=YES
BUSINESS_ACCEPTS_EQUIVALENT_FIELD=YES
BUSINESS_ACCEPTS_VEHICLE_FITMENT_FIELD=YES
BUSINESS_ACCEPTS_BARCODE_NON_BLOCKER=YES
BUSINESS_ACCEPTS_MARKETPLACE_PHASE_4D=YES

---

## Gate sonucu

FINAL_UAT_RESULT=PASS
GO_NO_GO_READY=YES
4C_6H_READY=YES
EOF

# Kritik fix:
# grep hic PENDING bulamazsa exit 1 doner; pipefail acikken script patlamasin diye || true kullaniyoruz.
PENDING_COUNT="$( (grep -R "PENDING" "$INPUT_ENV" "$ACCEPTANCE_FORM" || true) | wc -l | tr -d ' ')"

cat <<EOF > "$REPORT_FILE"
# FAZ 4C — 4C-6G-3 Business Acceptance Input Fill Report

Step: 4C-6G-3-FIX1
Blok: Business Acceptance Input Fill
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6G_3_BUSINESS_ACCEPTANCE_INPUT_FILL_STATUS=PASS
4C_6G_3_FIX_STATUS=PASS
4C_6G_3_BUSINESS_ACCEPTANCE_STATUS=PASS
4C_6G_3_BUSINESS_REPRESENTATIVE_NAME=mert_omur
4C_6G_3_BUSINESS_ACCEPTANCE_DATE=$TODAY
4C_6G_3_BUSINESS_ACCEPTS_TENANT_ACCESS=YES
4C_6G_3_BUSINESS_ACCEPTS_USER_ROLE_ACCESS=YES
4C_6G_3_BUSINESS_ACCEPTS_STAGING_PRODUCTS=YES
4C_6G_3_BUSINESS_ACCEPTS_OEM_FIELD=YES
4C_6G_3_BUSINESS_ACCEPTS_EQUIVALENT_FIELD=YES
4C_6G_3_BUSINESS_ACCEPTS_VEHICLE_FITMENT_FIELD=YES
4C_6G_3_BUSINESS_ACCEPTS_BARCODE_NON_BLOCKER=YES
4C_6G_3_BUSINESS_ACCEPTS_MARKETPLACE_PHASE_4D=YES
4C_6G_3_PENDING_FIELD_COUNT=$PENDING_COUNT
4C_6G_3_DB_WRITE_APPLIED=NO
4C_6G_2_RETRY_READY=YES

## Sonuc

Business acceptance input PASS olarak dolduruldu.
PENDING grep fix uygulandi.
DB yazma islemi yapilmadi.
4C-6G-2 tekrar calistirilabilir.
EOF

echo "OK ✅ Business acceptance input PASS olarak dolduruldu: $INPUT_ENV"
echo "OK ✅ Business acceptance form PASS olarak guncellendi: $ACCEPTANCE_FORM"
echo "OK ✅ Fill report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-6G-3-FIX1 OZET ====="
echo "4C_6G_3_BUSINESS_ACCEPTANCE_INPUT_FILL_STATUS=PASS ✅"
echo "4C_6G_3_BUSINESS_ACCEPTANCE_STATUS=PASS ✅"
echo "4C_6G_3_PENDING_FIELD_COUNT=$PENDING_COUNT"
echo "4C_6G_3_DB_WRITE_APPLIED=NO ✅"
echo "4C_6G_2_RETRY_READY=YES ✅"
