#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DOC_FILE="docs/pilot/faz4c/4c_1_1_pilot_isletme_secimi.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1_final_report.md"

echo "===== 4C-1.1 PILOT ISLETME SECIMI TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$DOC_FILE" ] || fail "Dokuman bulunamadi: $DOC_FILE"
pass "Dokuman var"

grep -q "FAZ 4C" "$DOC_FILE" || fail "FAZ 4C basligi yok"
pass "FAZ 4C basligi var"

grep -q "4C-1.1" "$DOC_FILE" || fail "4C-1.1 basligi yok"
pass "4C-1.1 basligi var"

grep -q "Pilot isletme secimi" "$DOC_FILE" || fail "Pilot isletme secimi basligi yok"
pass "Pilot isletme secimi basligi var"

grep -q "Scope freeze" "$DOC_FILE" || fail "Scope freeze alani yok"
pass "Scope freeze alani var"

grep -q "kapsam disi" "$DOC_FILE" || fail "Kapsam disi alani yok"
pass "Kapsam disi alani var"

grep -q "Kabul kriterleri" "$DOC_FILE" || fail "Kabul kriterleri yok"
pass "Kabul kriterleri var"

grep -q "Risk notlari" "$DOC_FILE" || fail "Risk notlari yok"
pass "Risk notlari var"

grep -q "4C_1_1_PILOT_SELECTION_STATUS=PENDING" "$DOC_FILE" || fail "Pilot selection status yok"
pass "Pilot selection status var"

grep -q "4C_1_1_SCOPE_FREEZE_STATUS=PENDING" "$DOC_FILE" || fail "Scope freeze status yok"
pass "Scope freeze status var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1 Final Report

Step: 4C-1.1A
Blok: Pilot isletme secimi
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1_DOCUMENT_CREATED=YES
4C_1_1_TEST_SCRIPT_CREATED=YES
4C_1_1_REQUIRED_FIELDS_PRESENT=YES
4C_1_1_DOCUMENT_KIT_STATUS=PASS
4C_1_1_PILOT_SELECTION_STATUS=PENDING
4C_1_1_SCOPE_FREEZE_STATUS=PENDING
4C_1_1_NEXT_STEP_READY=NO

## Not

Bu adim teknik dokuman ve kontrol paketini hazirlar.
Pilot isletme gercek bilgilerle doldurulduktan sonra 4C-1.1B ile PASS durumuna alinacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1 TEST SONUCU ====="
echo "4C_1_1_DOCUMENT_KIT_STATUS=PASS ✅"
echo "4C_1_1_PILOT_SELECTION_STATUS=PENDING"
echo "4C_1_1_SCOPE_FREEZE_STATUS=PENDING"
echo "4C_1_1_NEXT_STEP_READY=NO"
