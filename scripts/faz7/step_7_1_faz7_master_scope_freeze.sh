#!/usr/bin/env bash
set -Eeuo pipefail

echo "===== FAZ 7-1 MASTER PLAN / SCOPE FREEZE BASLADI ====="

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="backups/faz7/7-1_${TS}"

mkdir -p "$BACKUP_DIR"
mkdir -p docs/faz7/evidence
mkdir -p scripts/faz7

echo
echo "===== 7-1 BACKUP ====="

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$path" "$BACKUP_DIR/$path"
    echo "7-1 backup OK ✅ $path -> $BACKUP_DIR/$path"
  else
    echo "7-1 backup SKIP ✅ $path mevcut degil"
  fi
}

backup_if_exists "docs/faz7/FAZ_7_MASTER_PLAN.md"
backup_if_exists "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_1_SCOPE_FREEZE_EVIDENCE.md"
backup_if_exists "docs/faz7/evidence/FAZ_7_1_REAL_IMPLEMENTATION_AUDIT.md"
backup_if_exists "scripts/faz7/test_7_1_faz7_master_scope_freeze.sh"
backup_if_exists "scripts/faz7/audit_7_1_real_implementation.sh"

echo "7-1 backup tamam OK ✅"

python3 - <<'PY'
from pathlib import Path
from textwrap import dedent

files = {}

files["docs/faz7/FAZ_7_MASTER_PLAN.md"] = dedent("""
# FAZ 7 — Moduler Buyume / Public Launch Hazirligi / Urunlestirme / Ticari Runtime

## Giris Kosullari

- FAZ_6_12_FINAL_BLOCKER_COUNT=0
- FAZ_6_12_FINAL_GO_DECISION=GO_FOR_NEXT_PHASE
- FAZ_6_12_FINAL_STATUS=PASS
- FAZ_6_FINAL_STATUS=PASS
- FAZ_6_FINAL_SEAL_STATUS=SEALED
- FAZ_7_READY=YES

## FAZ 7 Amaci

FAZ 7'nin amaci Pix2pi cekirdek altyapisini ticari urune donusturmektir.

Ana hedefler:

1. Moduler buyume modelini netlestirmek.
2. Public launch oncesi urun, paket, fiyat, yetki ve operasyon kapilarini hazirlamak.
3. Ticari runtime icin subscription, entitlement, onboarding ve commercial ops temelini kurmak.
4. Pilot / demo / trial akisini duzenli hale getirmek.
5. Production public launch oncesi legal, KVKK, Cloudflare green mode, payment ve support kapilarini acik sekilde kilitlemek.

## FAZ 7 Kapsam Disiplini

FAZ 7 bir core rewrite fazi degildir.

FAZ 7 su alanlari kapsar:

- Product packaging
- Plan catalog
- Feature / entitlement runtime
- Subscription runtime
- Billing readiness
- Tenant onboarding
- Public landing / demo flow
- Marketplace / integration catalog foundation
- Muhasebeci portal commercial surface
- Support / CRM / ticket readiness
- Admin commercial ops console
- Legal / KVKK / contract gate
- Public launch gate
- FAZ 7 final closure

FAZ 7 su alanlari dogrudan production olarak acmaz:

- Gercek public launch
- Gercek canli odeme tahsilati
- Hukukcu onayi olmadan sozlesme yayinlama
- KVKK danismani onayi olmadan public veri toplama
- Mali musavir/vergi onayi olmadan gercek billing acma
- Cloudflare green mode aktif olmadan public production acilisi

## FAZ 7 Master Is Listesi

### 7-1 — FAZ 7 Master Plan / Scope Freeze

#### 7-1.1 FAZ 7 amaci
- 7-1.1.1 Moduler buyume kapsami
- 7-1.1.2 Public launch hazirligi
- 7-1.1.3 Urunlestirme kapsami
- 7-1.1.4 Ticari runtime kapsami

#### 7-1.2 Scope freeze
- 7-1.2.1 FAZ 7 dahil isler
- 7-1.2.2 FAZ 7 disi isler
- 7-1.2.3 Production public launch on sartlari
- 7-1.2.4 Cloudflare green mode gecis kapisi

### 7-2 — Product Packaging / Plan Catalog

#### 7-2.1 Paket mimarisi
- 7-2.1.1 Starter paket
- 7-2.1.2 Pro paket
- 7-2.1.3 Enterprise paket
- 7-2.1.4 Muhasebeci paketi
- 7-2.1.5 Marketplace / entegrasyon paketi

#### 7-2.2 Feature matrix
- 7-2.2.1 Modul bazli yetki
- 7-2.2.2 Kullanici limiti
- 7-2.2.3 Tenant limiti
- 7-2.2.4 API hakki
- 7-2.2.5 Export hakki
- 7-2.2.6 Muhasebeci erisim hakki

### 7-3 — Entitlement Runtime / Feature Gate

#### 7-3.1 Entitlement cekirdegi
- 7-3.1.1 Paket hakki kontrolu
- 7-3.1.2 Tenant bazli feature flag
- 7-3.1.3 Kullanici bazli entitlement
- 7-3.1.4 API/gateway seviyesinde paket kontrolu
- 7-3.1.5 Audit log ile entitlement izi

### 7-4 — Commercial Account / Subscription Runtime

#### 7-4.1 Subscription modeli
- 7-4.1.1 Tenant subscription kaydi
- 7-4.1.2 Plan degisikligi
- 7-4.1.3 Trial/demo suresi
- 7-4.1.4 Paket yenileme
- 7-4.1.5 Askiya alma / yeniden acma

### 7-5 — Billing Readiness

#### 7-5.1 Billing hazirligi
- 7-5.1.1 Fatura hazirlik modeli
- 7-5.1.2 Vergi/KDV uyumu
- 7-5.1.3 Muhasebeci paketi firma basi ucret modeli
- 7-5.1.4 Gercek odeme saglayici oncesi billing simulation
- 7-5.1.5 Gercek odeme entegrasyonu icin adapter hazirligi

### 7-6 — Tenant Onboarding / Self-Service Readiness

#### 7-6.1 Onboarding akisi
- 7-6.1.1 Yeni isletme kayit akisi
- 7-6.1.2 Tenant olusturma
- 7-6.1.3 Ilk admin kullanici
- 7-6.1.4 Demo veri / bos baslangic secimi
- 7-6.1.5 Onboarding audit izi

### 7-7 — Public Website / Landing / Demo Flow

#### 7-7.1 Public yuzey
- 7-7.1.1 Public landing page
- 7-7.1.2 Paket/fiyat gosterimi
- 7-7.1.3 Demo talep formu
- 7-7.1.4 Trial baslatma yuzeyi
- 7-7.1.5 SEO / schema hazirligi

### 7-8 — Marketplace / Integration Catalog Foundation

#### 7-8.1 Entegrasyon katalogu
- 7-8.1.1 Entegrasyon katalog modeli
- 7-8.1.2 Parasut entegrasyon hazirligi
- 7-8.1.3 Pazaryeri entegrasyon hazirligi
- 7-8.1.4 Webhook/public API hazirligi
- 7-8.1.5 Entegrasyon paketleme ve ucretlendirme

### 7-9 — Muhasebeci Portal Commercial Surface

#### 7-9.1 Muhasebeci ticari yuzeyi
- 7-9.1.1 Muhasebeci firma iliskisi
- 7-9.1.2 Cok firmali erisim
- 7-9.1.3 Firma basi aylik hak modeli
- 7-9.1.4 Export yetkileri
- 7-9.1.5 Muhasebeci paket entitlement

### 7-10 — Support / CRM / Ticket Runtime Readiness

#### 7-10.1 Support/CRM hazirligi
- 7-10.1.1 Support talep modeli
- 7-10.1.2 Ticket akisi
- 7-10.1.3 CRM musteri durumu
- 7-10.1.4 Pilot musteri geri bildirimleri
- 7-10.1.5 Commercial ops gorunumu

### 7-11 — Admin Commercial Ops Console

#### 7-11.1 Admin ticari operasyon paneli
- 7-11.1.1 Tenant ticari durum paneli
- 7-11.1.2 Plan/paket yonetimi
- 7-11.1.3 Trial/demo izleme
- 7-11.1.4 Askiya alma / yeniden acma
- 7-11.1.5 Commercial audit gorunumu

### 7-12 — Legal / KVKK / Contract Gate

#### 7-12.1 Legal gate
- 7-12.1.1 Kullanim sartlari
- 7-12.1.2 KVKK aydinlatma metni
- 7-12.1.3 Acik riza / ticari ileti izinleri
- 7-12.1.4 Veri saklama / silme politikasi
- 7-12.1.5 Hukukcu / KVKK danismani final onay kapisi

### 7-13 — Public Launch Gate

#### 7-13.1 Launch gate
- 7-13.1.1 Cloudflare green mode gecisi
- 7-13.1.2 WAF/rate limit aktif kontrol
- 7-13.1.3 Production smoke test
- 7-13.1.4 Public route final test
- 7-13.1.5 Go / No-Go karari

### 7-14 — FAZ 7 Final Closure / Seal

#### 7-14.1 Final closure
- 7-14.1.1 Tum FAZ 7 evidence kontrolu
- 7-14.1.2 Real implementation audit
- 7-14.1.3 Eksik/kismi/acik is listesi
- 7-14.1.4 Final blocker count
- 7-14.1.5 FAZ 7 final muhur

## FAZ 7 Cikis Kriterleri

- FAZ_7_FINAL_BLOCKER_COUNT=0
- FAZ_7_PRODUCTIZATION_STATUS=PASS
- FAZ_7_COMMERCIAL_RUNTIME_STATUS=PASS
- FAZ_7_PUBLIC_LAUNCH_READINESS_STATUS=READY_OR_GATED
- FAZ_7_FINAL_STATUS=PASS
- FAZ_7_FINAL_SEAL_STATUS=SEALED

## FAZ 7 Kritik Notlar

- Public launch, hukuki ve KVKK onaylari olmadan acilmayacak.
- Gercek odeme, mali/vergi onayi ve odeme saglayici sozlesmesi olmadan acilmayacak.
- Cloudflare gri mod karari FAZ 6'da bilincli karar olarak kaydedildi.
- Production public launch oncesi Cloudflare green mode aktif edilecek.
- FAZ 7, moduler buyume ve ticari runtime fazidir; core mimari yeniden yazilmayacak.
""").strip() + "\n"

files["docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md"] = dedent("""
# 7-1 — FAZ 7 Master Plan / Scope Freeze

## Adim Amaci

Bu adim FAZ 7'nin kapsamini sabitler.

7-1 adimi sonunda:

- FAZ 7 amaci netlesir.
- FAZ 7 ana is listesi sabitlenir.
- Public launch oncesi kapilar belirlenir.
- Gercek odeme, hukuk, KVKK, Cloudflare green mode gibi riskli alanlar gate olarak kaydedilir.
- 7-2 Product Packaging / Plan Catalog adimina gecis izni verilir.

## 7-1.1 FAZ 7 Amaci

### 7-1.1.1 Moduler buyume kapsami
Durum: IMPLEMENTED_OR_PRESENT

FAZ 7, Pix2pi'nin yeni modullerle buyuyebilmesi icin paket, entitlement, entegrasyon ve ticari operasyon omurgasini hazirlar.

### 7-1.1.2 Public launch hazirligi
Durum: IMPLEMENTED_OR_PRESENT

FAZ 7, public launch'i dogrudan acmaz; public launch icin gerekli tum teknik, ticari, hukuki ve edge kapilarini hazirlar.

### 7-1.1.3 Urunlestirme kapsami
Durum: IMPLEMENTED_OR_PRESENT

FAZ 7, Pix2pi'yi teknik platformdan paketlenebilir SaaS urune donusturur.

### 7-1.1.4 Ticari runtime kapsami
Durum: IMPLEMENTED_OR_PRESENT

FAZ 7; subscription, paket hakki, demo/trial, commercial ops, CRM/support ve billing readiness alanlarini kapsar.

## 7-1.2 Scope Freeze

### 7-1.2.1 FAZ 7 dahil isler
Durum: IMPLEMENTED_OR_PRESENT

Dahil isler:

- Product packaging
- Plan catalog
- Feature matrix
- Entitlement runtime
- Subscription runtime
- Billing readiness
- Tenant onboarding
- Public website / demo flow
- Marketplace / integration catalog foundation
- Muhasebeci portal commercial surface
- Support / CRM / ticket readiness
- Admin commercial ops console
- Legal / KVKK / contract gate
- Public launch gate
- FAZ 7 final closure

### 7-1.2.2 FAZ 7 disi isler
Durum: IMPLEMENTED_OR_PRESENT

FAZ 7 disinda kalan veya gate'e baglanan isler:

- Hukukcu onayi olmadan public sozlesme yayinlama
- KVKK danismani onayi olmadan public veri toplama
- Mali musavir/vergi onayi olmadan gercek billing acma
- Gercek odeme saglayici entegrasyonunu production tahsilata acma
- Cloudflare green mode aktif olmadan public production launch
- Buyuk core rewrite
- FAZ 6'da muhurlenmis SRE/DR/edge temellerini yeniden yazma

### 7-1.2.3 Production public launch on sartlari
Durum: IMPLEMENTED_OR_PRESENT

Production public launch icin on sartlar:

- Legal / KVKK / contract gate PASS
- Cloudflare green mode aktif
- WAF/rate limit aktif
- Production smoke test PASS
- Support/ticket operasyonu READY
- Billing/payment gate karari net
- Public launch GO/NO-GO kaydi mevcut

### 7-1.2.4 Cloudflare green mode gecis kapisi
Durum: IMPLEMENTED_OR_PRESENT

FAZ 6'da Cloudflare gri mod bilincli karar olarak kaydedildi.
FAZ 7 public launch gate oncesi Cloudflare green mode aktif edilmeli ve edge dogrulamasi yapilmalidir.

## 7-1 Final Karari

- FAZ_7_1_DOC_STATUS=READY
- FAZ_7_1_SCOPE_STATUS=FROZEN
- FAZ_7_1_TEST_REQUIRED=YES
- FAZ_7_1_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_2_READY_CONDITION=FAZ_7_1_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
""").strip() + "\n"

files["docs/faz7/evidence/FAZ_7_1_SCOPE_FREEZE_EVIDENCE.md"] = dedent("""
# FAZ 7-1 Scope Freeze Evidence

## Evidence Summary

- 7-1 master plan document created.
- 7-1 scope freeze document created.
- FAZ 7 includes productization, commercial runtime, public launch readiness and modular growth.
- Production public launch is gated.
- Real payment, legal/KVKK, tax/billing and Cloudflare green mode are explicitly gated.
- 7-2 Product Packaging / Plan Catalog is the next step after 7-1 passes.

## Evidence Files

- docs/faz7/FAZ_7_MASTER_PLAN.md
- docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md
- docs/faz7/evidence/FAZ_7_1_SCOPE_FREEZE_EVIDENCE.md
- scripts/faz7/test_7_1_faz7_master_scope_freeze.sh
- scripts/faz7/audit_7_1_real_implementation.sh

## Initial Seal Target

- FAZ_7_1_DOC_STATUS=READY
- FAZ_7_1_SCOPE_STATUS=FROZEN
- FAZ_7_1_TEST_STATUS=PENDING_UNTIL_SCRIPT_RUN
- FAZ_7_1_REAL_IMPLEMENTATION_STATUS=PENDING_UNTIL_AUDIT_RUN
""").strip() + "\n"

files["scripts/faz7/test_7_1_faz7_master_scope_freeze.sh"] = dedent(r"""
#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$1 OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$1 HATA ❌"
}

check_file() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    ok "$label file mevcut: $path"
  else
    fail "$label file eksik: $path"
  fi
}

check_grep() {
  local label="$1"
  local path="$2"
  local pattern="$3"
  if [ -f "$path" ] && grep -Fq "$pattern" "$path"; then
    ok "$label bulundu"
  else
    fail "$label bulunamadi"
  fi
}

echo "===== FAZ 7-1 TEST BASLADI ====="

check_file "7-1" "docs/faz7/FAZ_7_MASTER_PLAN.md"
check_file "7-1" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md"
check_file "7-1" "docs/faz7/evidence/FAZ_7_1_SCOPE_FREEZE_EVIDENCE.md"
check_file "7-1" "scripts/faz7/test_7_1_faz7_master_scope_freeze.sh"
check_file "7-1" "scripts/faz7/audit_7_1_real_implementation.sh"

check_grep "7-1.1 FAZ 7 amaci" "docs/faz7/FAZ_7_MASTER_PLAN.md" "FAZ 7 Amaci"
check_grep "7-1.1.1 Moduler buyume kapsami" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Moduler buyume"
check_grep "7-1.1.2 Public launch hazirligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Public launch"
check_grep "7-1.1.3 Urunlestirme kapsami" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Urunlestirme"
check_grep "7-1.1.4 Ticari runtime kapsami" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Ticari runtime"

check_grep "7-1.2 Scope freeze" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Scope Freeze"
check_grep "7-1.2.1 FAZ 7 dahil isler" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "FAZ 7 dahil isler"
check_grep "7-1.2.2 FAZ 7 disi isler" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "FAZ 7 disi isler"
check_grep "7-1.2.3 Production public launch on sartlari" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Production public launch icin on sartlar"
check_grep "7-1.2.4 Cloudflare green mode gecis kapisi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Cloudflare green mode"

check_grep "7-2 Product Packaging siradaki adim" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-2 — Product Packaging"
check_grep "7-3 Entitlement runtime kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-3 — Entitlement Runtime"
check_grep "7-4 Subscription runtime kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-4 — Commercial Account"
check_grep "7-5 Billing readiness kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-5 — Billing Readiness"
check_grep "7-13 Public launch gate kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-13 — Public Launch Gate"
check_grep "7-14 Final closure kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-14 — FAZ 7 Final Closure"

echo
echo "===== FAZ 7-1 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_1_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-1 testleri basariyla gecti"
else
  echo "FAZ_7_1_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-1 testlerinde hata var"
  exit 1
fi
""").strip() + "\n"

files["scripts/faz7/audit_7_1_real_implementation.sh"] = dedent(r"""
#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_1_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p docs/faz7/evidence

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$1 REQUIRED_FAIL ❌"
}

warn() {
  OPTIONAL_WARN=$((OPTIONAL_WARN+1))
  echo "$1 OPTIONAL_WARN ⚠️"
}

has_file() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

has_text() {
  local label="$1"
  local path="$2"
  local pattern="$3"
  if [ -f "$path" ] && grep -Fq "$pattern" "$path"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 7-1 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-1.1 Master plan dokumani" "docs/faz7/FAZ_7_MASTER_PLAN.md"
has_file "7-1.2 Scope freeze dokumani" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md"
has_file "7-1.3 Evidence dokumani" "docs/faz7/evidence/FAZ_7_1_SCOPE_FREEZE_EVIDENCE.md"
has_file "7-1.4 Test scripti" "scripts/faz7/test_7_1_faz7_master_scope_freeze.sh"
has_file "7-1.5 Real implementation audit scripti" "scripts/faz7/audit_7_1_real_implementation.sh"

has_text "7-1.1.1 Moduler buyume dokuman karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Moduler buyume"
has_text "7-1.1.2 Public launch dokuman karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Public launch"
has_text "7-1.1.3 Urunlestirme dokuman karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Urunlestirme"
has_text "7-1.1.4 Ticari runtime dokuman karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Ticari runtime"

has_text "7-1.2.1 Dahil isler scope karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "FAZ 7 dahil isler"
has_text "7-1.2.2 Dis isler scope karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "FAZ 7 disi isler"
has_text "7-1.2.3 Production launch gate karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Production public launch icin on sartlar"
has_text "7-1.2.4 Cloudflare green mode gate karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Cloudflare green mode"

has_text "7-1.3.1 Gercek odeme gate karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Gercek odeme"
has_text "7-1.3.2 Hukuk/KVKK gate karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "KVKK"
has_text "7-1.3.3 Billing/tax gate karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "mali/vergi"
has_text "7-1.3.4 Core rewrite dislama karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Buyuk core rewrite"

echo
echo "===== FAZ 7-1 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "REQUIRED_FAIL=$FAIL_COUNT"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$FAIL_COUNT" -eq 0 ]; then
  STATUS="PASS"
  STATUS_ICON="✅"
else
  STATUS="FAIL"
  STATUS_ICON="❌"
fi

cat > "$AUDIT_FILE" <<AUDIT
# FAZ 7-1 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_1_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_1_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_MASTER_PLAN.md
- docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md
- docs/faz7/evidence/FAZ_7_1_SCOPE_FREEZE_EVIDENCE.md
- scripts/faz7/test_7_1_faz7_master_scope_freeze.sh
- scripts/faz7/audit_7_1_real_implementation.sh

## Real Implementation Decision

7-1 real implementation audit confirms that the FAZ 7 master plan, scope freeze, evidence, test script and audit script exist as code/config/script/document artifacts.

## Final Status

FAZ_7_1_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_1_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_1_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-1 real implementation audit basariyla gecti"
else
  echo "FAZ_7_1_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-1 real implementation audit basarisiz"
  exit 1
fi
""").strip() + "\n"

for path, content in files.items():
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    print(f"OK ✅ yazildi: {path}")
PY

chmod +x scripts/faz7/step_7_1_faz7_master_scope_freeze.sh
chmod +x scripts/faz7/test_7_1_faz7_master_scope_freeze.sh
chmod +x scripts/faz7/audit_7_1_real_implementation.sh

echo
echo "===== 7-1 TEST CALISIYOR ====="
bash scripts/faz7/test_7_1_faz7_master_scope_freeze.sh

echo
echo "===== 7-1 REAL IMPLEMENTATION AUDIT CALISIYOR ====="
bash scripts/faz7/audit_7_1_real_implementation.sh

echo
echo "===== FAZ 7-1 FINAL OZET ====="
echo "FAZ_7_1_DOC_STATUS=READY ✅"
echo "FAZ_7_1_SCOPE_STATUS=FROZEN ✅"
echo "FAZ_7_1_TEST_STATUS=PASS ✅"
echo "FAZ_7_1_REAL_IMPLEMENTATION_STATUS=PASS ✅"
echo "FAZ_7_1_FINAL_STATUS=PASS ✅"
echo "FAZ_7_2_READY=YES ✅"
echo "OK ✅ FAZ 7-1 Master Plan / Scope Freeze tamamlandi"
