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
