#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="docs/pilot/faz4c/4c_1_1g_real_business_input_template.env"
F_GATE="docs/pilot/faz4c/4c_1_1f_final_closure_gate.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1g_real_business_input_template_report.md"

echo "===== 4C-1.1G REAL BUSINESS INPUT TEMPLATE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$ENV_FILE" ] || fail "Input template yok: $ENV_FILE"
pass "Input template var"

[ -f "$F_GATE" ] || fail "4C-1.1F final closure gate yok: $F_GATE"
pass "4C-1.1F final closure gate var"

REQUIRED_KEYS=(
  PILOT_SEKTOR
  PILOT_ISLETME_ADI
  YETKILI_KISI
  YETKILI_TELEFON
  YETKILI_EMAIL
  ADRES
  IL
  ILCE
  VERGI_NO
  VERGI_DAIRESI
  SUBE_SAYISI
  KULLANICI_SAYISI
  GUNLUK_TAHMINI_ISLEM
  TAHMINI_STOK_KALEMI
  TAHMINI_CARI_SAYISI
  TAHMINI_TEDARIKCI_SAYISI
  MEVCUT_PROGRAM
  EXCEL_URUN_STOK_VERISI_VAR_MI
  OEM_KODU_KULLANIYOR_MU
  ESDEGER_PARCA_MANTIGI_VAR_MI
  AYNI_PARCA_BIRDEN_FAZLA_ARACA_UYUYOR_MU
  ARAC_MARKA_MODEL_ARAMA_IHTIYACI_VAR_MI
  BARKOD_KULLANIYOR_MU
  RAF_LOKASYON_TAKIBI_VAR_MI
  TRENDYOL_KULLANIYOR_MU
  HEPSIBURADA_KULLANIYOR_MU
  N11_KULLANIYOR_MU
  AMAZON_KULLANIYOR_MU
  KENDI_WEB_SITESI_SATISI_VAR_MI
  PAZARYERI_4C_DISI_KABUL
  EFATURA_EARSIV_4C_ZORUNLU_DEGIL_KABUL
  BANKA_SANAL_POS_4C_DISI_KABUL
  PILOT_URUN_STOK_CARI_SATIS_UAT_ODAKLI_KABUL
  OZEL_ISTEKLER_SCOPE_DISI_KABUL
  UAT_SORUMLUSU
  GO_NO_GO_YETKILISI
  PIX2PI_TEKNIK_TAKIP_SORUMLUSU
  PILOT_BASLANGIC_HEDEF_TARIHI
  PILOT_HEDEF_KAPANIS_TARIHI
)

for key in "${REQUIRED_KEYS[@]}"; do
  grep -q "^${key}=" "$ENV_FILE" || fail "Eksik key: $key"
done
pass "Tum zorunlu key alanlari var"

grep -q 'PILOT_SEKTOR="OTO YEDEK PARCA"' "$ENV_FILE" || fail "Pilot sektor oto yedek parca degil"
pass "Pilot sektor oto yedek parca"

PENDING_COUNT="$(grep -c '="PENDING"' "$ENV_FILE" || true)"
KEY_COUNT="$(grep -E '^[A-Z0-9_]+=' "$ENV_FILE" | wc -l | tr -d ' ')"

if [ "$PENDING_COUNT" -eq 0 ]; then
  fail "Bu template artik doldurulmus gorunuyor; sonraki adim apply/final closure olmali"
fi

pass "PENDING alanlari var: $PENDING_COUNT"
pass "Toplam key sayisi: $KEY_COUNT"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1G Real Business Input Template Report

Step: 4C-1.1G
Blok: Gercek pilot isletme bilgileri input template
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1G_INPUT_TEMPLATE_STATUS=PASS
4C_1_1G_REQUIRED_KEYS_PRESENT=YES
4C_1_1G_TOTAL_KEY_COUNT=$KEY_COUNT
4C_1_1G_PENDING_FIELD_COUNT=$PENDING_COUNT
4C_1_1G_REAL_VALUES_FILLED=NO
4C_1_1G_FINAL_CLOSURE_READY=NO

## Sonuc

Gercek pilot isletme bilgileri icin env template hazirlandi.
Bu adim bilgi giris altyapisini hazirlar.
Gercek degerler girilmeden 4C-1.1 final closure yapilmayacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1G TEST SONUCU ====="
echo "4C_1_1G_INPUT_TEMPLATE_STATUS=PASS ✅"
echo "4C_1_1G_REQUIRED_KEYS_PRESENT=YES ✅"
echo "4C_1_1G_TOTAL_KEY_COUNT=$KEY_COUNT"
echo "4C_1_1G_PENDING_FIELD_COUNT=$PENDING_COUNT"
echo "4C_1_1G_REAL_VALUES_FILLED=NO"
echo "4C_1_1G_FINAL_CLOSURE_READY=NO"
