#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DOC_FILE="docs/pilot/faz4c/4c_1_1_pilot_isletme_secimi.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1b_2_marketplace_scope_guard_report.md"

echo "===== 4C-1.1B-2 MARKETPLACE SCOPE GUARD TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$DOC_FILE" ] || fail "Dokuman bulunamadi: $DOC_FILE"
pass "Dokuman var"

grep -q "Pazaryeri entegrasyonu kapsam karari" "$DOC_FILE" || fail "Pazaryeri kapsam karari yok"
pass "Pazaryeri kapsam karari var"

grep -q "4C_MARKETPLACE_LIVE_INTEGRATION=NO" "$DOC_FILE" || fail "Canli entegrasyon NO karari yok"
pass "Canli pazaryeri entegrasyonu 4C disi"

grep -q "4C_MARKETPLACE_DISCOVERY_ONLY=YES" "$DOC_FILE" || fail "Discovery only karari yok"
pass "4C discovery only karari var"

grep -q "4C_MARKETPLACE_SCOPE_GUARD=PASS" "$DOC_FILE" || fail "Scope guard PASS yok"
pass "Marketplace scope guard PASS"

grep -q "FUTURE_MARKETPLACE_PHASE=FAZ_5A_CHANNEL_MARKETPLACE_INTEGRATIONS" "$DOC_FILE" || fail "Gelecek faz adi yok"
pass "Gelecek marketplace fazi belirlendi"

grep -q "Trendyol canli API entegrasyonu" "$DOC_FILE" || fail "Trendyol scope disi maddesi yok"
pass "Trendyol canli entegrasyon scope disi"

grep -q "stok senkron" "$DOC_FILE" || fail "Stok senkron ihtiyaci yok"
pass "Stok senkron ihtiyaci not edildi"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1B-2 Marketplace Scope Guard Report

Step: 4C-1.1B-2
Blok: Pazaryeri entegrasyonu kapsam karari
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Karar

4C_MARKETPLACE_LIVE_INTEGRATION=NO
4C_MARKETPLACE_DISCOVERY_ONLY=YES
4C_MARKETPLACE_SCOPE_GUARD=PASS
FUTURE_MARKETPLACE_PHASE=FAZ_5A_CHANNEL_MARKETPLACE_INTEGRATIONS

## Sonuc

Pazaryeri entegrasyonu FAZ 4C icinde canli entegrasyon olarak yapilmayacak.
FAZ 4C icinde sadece discovery ve gelecek faz hazirligi yapilacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1B-2 TEST SONUCU ====="
echo "4C_MARKETPLACE_LIVE_INTEGRATION=NO ✅"
echo "4C_MARKETPLACE_DISCOVERY_ONLY=YES ✅"
echo "4C_MARKETPLACE_SCOPE_GUARD=PASS ✅"
echo "FUTURE_MARKETPLACE_PHASE=FAZ_5A_CHANNEL_MARKETPLACE_INTEGRATIONS ✅"
