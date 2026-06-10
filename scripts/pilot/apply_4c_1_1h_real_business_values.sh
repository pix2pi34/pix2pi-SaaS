#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="docs/pilot/faz4c/4c_1_1g_real_business_input_template.env"
OUT_DOC="docs/pilot/faz4c/4c_1_1h_real_business_profile_applied.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1h_real_business_apply_guard_report.md"

echo "===== 4C-1.1H REAL BUSINESS APPLY GUARD ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$ENV_FILE" ] || fail "Env template bulunamadi: $ENV_FILE"

KEY_COUNT="$(grep -E '^[A-Z0-9_]+=' "$ENV_FILE" | wc -l | tr -d ' ')"
PENDING_COUNT="$(grep -c '="PENDING"' "$ENV_FILE" || true)"

pass "Env dosyasi var"
pass "Toplam key sayisi: $KEY_COUNT"
pass "PENDING sayisi: $PENDING_COUNT"

if [ "$PENDING_COUNT" -gt 0 ]; then
  cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1H Real Business Apply Guard Report

Step: 4C-1.1H
Blok: Real Business Apply Guard
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1H_ENV_FILE_FOUND=YES
4C_1_1H_TOTAL_KEY_COUNT=$KEY_COUNT
4C_1_1H_PENDING_FIELD_COUNT=$PENDING_COUNT
4C_1_1H_REAL_VALUES_FILLED=NO
4C_1_1H_APPLY_STATUS=BLOCKED
4C_1_1H_BLOCKER_REASON=PENDING_FIELDS_EXIST
4C_1_1H_FINAL_CLOSURE_READY=NO

## Sonuc

Gercek isletme bilgileri henuz tam doldurulmadigi icin apply islemi bloklandi.
Bu teknik hata degildir.
Bu kalite kapisidir.
REPORT_EOF

  echo
  echo "===== 4C-1.1H APPLY SONUCU ====="
  echo "4C_1_1H_APPLY_STATUS=BLOCKED"
  echo "4C_1_1H_BLOCKER_REASON=PENDING_FIELDS_EXIST"
  echo "4C_1_1H_PENDING_FIELD_COUNT=$PENDING_COUNT"
  echo "4C_1_1H_FINAL_CLOSURE_READY=NO"
  exit 0
fi

# Bu noktaya gelindiyse tum PENDING alanlar doldurulmus demektir.
# shellcheck disable=SC1090
source "$ENV_FILE"

cat <<PROFILE_EOF > "$OUT_DOC"
# FAZ 4C — 4C-1.1H Real Business Profile Applied

## Pilot isletme

Pilot sektor:
$PILOT_SEKTOR

Pilot isletme adi:
$PILOT_ISLETME_ADI

Yetkili kisi:
$YETKILI_KISI

Yetkili telefon:
$YETKILI_TELEFON

Yetkili email:
$YETKILI_EMAIL

Adres:
$ADRES

Il / Ilce:
$IL / $ILCE

Vergi no:
$VERGI_NO

Vergi dairesi:
$VERGI_DAIRESI

---

## Operasyon profili

Sube sayisi:
$SUBE_SAYISI

Kullanici sayisi:
$KULLANICI_SAYISI

Gunluk tahmini islem:
$GUNLUK_TAHMINI_ISLEM

Tahmini stok kalemi:
$TAHMINI_STOK_KALEMI

Tahmini cari sayisi:
$TAHMINI_CARI_SAYISI

Tahmini tedarikci sayisi:
$TAHMINI_TEDARIKCI_SAYISI

Mevcut program:
$MEVCUT_PROGRAM

Excel urun/stok verisi var mi:
$EXCEL_URUN_STOK_VERISI_VAR_MI

---

## Oto yedek parca bilgileri

OEM kodu kullaniyor mu:
$OEM_KODU_KULLANIYOR_MU

Esdeger parca mantigi var mi:
$ESDEGER_PARCA_MANTIGI_VAR_MI

Ayni parca birden fazla araca uyuyor mu:
$AYNI_PARCA_BIRDEN_FAZLA_ARACA_UYUYOR_MU

Arac marka/model arama ihtiyaci var mi:
$ARAC_MARKA_MODEL_ARAMA_IHTIYACI_VAR_MI

Barkod kullaniyor mu:
$BARKOD_KULLANIYOR_MU

Raf/lokasyon takibi var mi:
$RAF_LOKASYON_TAKIBI_VAR_MI

---

## Pazaryeri discovery

Trendyol kullaniyor mu:
$TRENDYOL_KULLANIYOR_MU

Hepsiburada kullaniyor mu:
$HEPSIBURADA_KULLANIYOR_MU

N11 kullaniyor mu:
$N11_KULLANIYOR_MU

Amazon kullaniyor mu:
$AMAZON_KULLANIYOR_MU

Kendi web sitesi satisi var mi:
$KENDI_WEB_SITESI_SATISI_VAR_MI

---

## Scope kabul

Pazaryeri 4C disi kabul:
$PAZARYERI_4C_DISI_KABUL

E-Fatura / E-Arsiv 4C zorunlu degil kabul:
$EFATURA_EARSIV_4C_ZORUNLU_DEGIL_KABUL

Banka / sanal POS 4C disi kabul:
$BANKA_SANAL_POS_4C_DISI_KABUL

Pilot urun/stok/cari/satis/UAT odakli kabul:
$PILOT_URUN_STOK_CARI_SATIS_UAT_ODAKLI_KABUL

Ozel istekler scope disi kabul:
$OZEL_ISTEKLER_SCOPE_DISI_KABUL

---

## UAT ve karar

UAT sorumlusu:
$UAT_SORUMLUSU

Go / No-Go yetkilisi:
$GO_NO_GO_YETKILISI

Pix2pi teknik takip sorumlusu:
$PIX2PI_TEKNIK_TAKIP_SORUMLUSU

Pilot baslangic hedef tarihi:
$PILOT_BASLANGIC_HEDEF_TARIHI

Pilot hedef kapanis tarihi:
$PILOT_HEDEF_KAPANIS_TARIHI

---

## Status

4C_1_1H_REAL_BUSINESS_PROFILE_APPLIED=YES
4C_1_1H_FINAL_CLOSURE_READY=YES
PROFILE_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1H Real Business Apply Guard Report

Step: 4C-1.1H
Blok: Real Business Apply Guard
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1H_ENV_FILE_FOUND=YES
4C_1_1H_TOTAL_KEY_COUNT=$KEY_COUNT
4C_1_1H_PENDING_FIELD_COUNT=0
4C_1_1H_REAL_VALUES_FILLED=YES
4C_1_1H_APPLY_STATUS=PASS
4C_1_1H_REAL_BUSINESS_PROFILE_CREATED=YES
4C_1_1H_FINAL_CLOSURE_READY=YES

## Sonuc

Gercek pilot isletme bilgileri basariyla profile dokumanina islendi.
4C-1.1I final closure adimina gecilebilir.
REPORT_EOF

echo
echo "===== 4C-1.1H APPLY SONUCU ====="
echo "4C_1_1H_APPLY_STATUS=PASS ✅"
echo "4C_1_1H_REAL_BUSINESS_PROFILE_CREATED=YES ✅"
echo "4C_1_1H_FINAL_CLOSURE_READY=YES ✅"
