# FAZ 4C — 4C-1.2 Pilot Execution Master Plan / Scope Freeze

## Blok

4C-1.2 — Pilot Execution Master Plan / Scope Freeze

## Ana durum

4C-1.1 Pilot isletme secimi kapanmistir.

Secilen pilot isletme:

- Isletme: uzmanparcaci
- Sektor: OTO YEDEK PARCA
- Yetkili: mert ömür
- Konum: istanbul / bahçelievler
- Sube: 1
- Kullanici: 1
- Gunluk tahmini islem: 200
- Tahmini stok kalemi: 1000
- Mevcut sistem: web sayfasi, pazar entegrasyonu, Parasut
- Web sitesi: https://uzmanparcaci.com/

---

## 1. Pilot execution amaci

Bu pilotun amaci Pix2pi sisteminin gercek bir oto yedek parca isletmesinde temel runtime zincirini dogrulamaktir.

Pilotun odagi:

1. Tenant kurulumu
2. Kullanici / rol kurulumu
3. Urun kartlari
4. Stok kartlari
5. Cari ihtiyaci kontrolu
6. Satis akisi
7. Stok dusme kontrolu
8. UAT geri bildirim
9. Bug / blocker yakalama
10. Tenant izolasyon son kontrolu
11. Go / No-Go karari

---

## 2. Pilot kapsam freeze

FAZ 4C icinde aktif kapsam:

| No | Kapsam | Durum |
|---:|--------|-------|
| 1 | Real runtime gap completion | IN_SCOPE |
| 2 | Real pilot tenant setup | IN_SCOPE |
| 3 | Real user / role assignment | IN_SCOPE |
| 4 | Real pilot data entry / import | IN_SCOPE |
| 5 | Real UAT execution | IN_SCOPE |
| 6 | Bug / blocker burn-down | IN_SCOPE |
| 7 | Security / tenant isolation final pilot check | IN_SCOPE |
| 8 | Business chain final validation | IN_SCOPE |
| 9 | Go / No-Go signoff | IN_SCOPE |
| 10 | Controlled pilot go-live | IN_SCOPE |
| 11 | Pilot monitoring / stabilization | IN_SCOPE |
| 12 | FAZ 4C final closure | IN_SCOPE |

---

## 3. FAZ 4C disi freeze

FAZ 4C icinde yapilmayacaklar:

| No | Kapsam disi konu | Karar |
|---:|------------------|-------|
| 1 | Canli pazaryeri entegrasyonu | FAZ_4D |
| 2 | Trendyol / Hepsiburada / N11 canli API | FAZ_4D |
| 3 | Canli e-Fatura / e-Arsiv zorunlulugu | OUT_OF_SCOPE |
| 4 | Canli banka / sanal POS entegrasyonu | OUT_OF_SCOPE |
| 5 | Tam TECDOC benzeri arac-parca motoru | FUTURE_MODULE |
| 6 | Cok subeli operasyon | OUT_OF_SCOPE |
| 7 | Marketplace / aggregator canli modulu | FUTURE_PHASE |
| 8 | Multi-region / cluster operasyon | FUTURE_SCALE |
| 9 | Musteriye ozel mimari kirma | BLOCKED |
| 10 | Gelismis kampanya / sadakat sistemi | FUTURE_MODULE |

---

## 4. Pilot execution sirasi

FAZ 4C icin uygulama sirasi:

### 4C-2 — Real Runtime Gap Completion

Amac:
Gercek pilota gecmeden once runtime eksiklerini tespit etmek.

Kontrol edilecekler:

1. Servislerin calisma durumu
2. API endpoint hazirligi
3. Tenant context
4. Auth/JWT durumu
5. DB baglantisi
6. Temel log / report dosyalari
7. Mevcut gap listesi

Exit gate:

4C_2_RUNTIME_GAP_SCAN_STATUS=PASS
4C_2_CRITICAL_BLOCKER_COUNT=0
4C_3_READY=YES

---

### 4C-3 — Real Pilot Tenant Setup

Amac:
uzmanparcaci icin gercek pilot tenant kaydini hazirlamak.

Kontrol edilecekler:

1. Tenant kodu
2. Tenant adi
3. Tenant schema / tenant id stratejisi
4. Tenant status
5. Tenant config
6. Tenant izolasyon notu

Exit gate:

4C_3_TENANT_SETUP_STATUS=PASS
4C_4_READY=YES

---

### 4C-4 — Real User / Role Assignment

Amac:
mert ömür icin pilot kullanici ve rol yapisini tanimlamak.

Kontrol edilecekler:

1. Admin kullanici
2. Rol
3. Yetki siniri
4. Login hazirligi
5. Tenant-user baglantisi

Exit gate:

4C_4_USER_ROLE_STATUS=PASS
4C_5_READY=YES

---

### 4C-5 — Real Pilot Data Entry / Import

Amac:
Pilot isletmenin urun/stok/cari verisini sisteme hazirlamak.

Kontrol edilecekler:

1. Urun veri sablonu
2. Stok veri sablonu
3. Cari veri ihtiyaci
4. OEM kodu
5. Esdeger parca bilgisi
6. Arac uyum notu
7. Import validasyonlari

Exit gate:

4C_5_DATA_ENTRY_IMPORT_STATUS=PASS
4C_6_READY=YES

---

### 4C-6 — Real UAT Execution

Amac:
Gercek kullanici senaryolarini calistirmak.

UAT senaryolari:

1. Kullanici girisi
2. Urun arama
3. Urun karti kontrolu
4. Stok kontrolu
5. Satis denemesi
6. Stoktan dusme kontrolu
7. Cari hareket kontrolu
8. Rapor kontrolu
9. Hata geri bildirimi
10. Kullanici deneyimi notu

Exit gate:

4C_6_UAT_STATUS=PASS
4C_7_READY=YES

---

### 4C-7 — Bug / Blocker Burn-down

Amac:
UAT ve runtime testlerde cikan hatalari kapatmak.

Kategoriler:

1. Critical blocker
2. High bug
3. Medium bug
4. Low bug
5. UX note
6. Future request

Exit gate:

4C_7_CRITICAL_BLOCKER_COUNT=0
4C_7_HIGH_BUG_COUNT=0
4C_8_READY=YES

---

### 4C-8 — Security / Tenant Isolation Final Pilot Check

Amac:
Pilot canliya yaklasmadan tenant izolasyonunu son kez kontrol etmek.

Kontrol edilecekler:

1. Tenant id dogrulugu
2. Kullanici tenant baglantisi
3. Cross-tenant access denemesi
4. Event payload tenant notu
5. Loglarda tenant ayrimi
6. Export / report tenant ayrimi

Exit gate:

4C_8_TENANT_ISOLATION_STATUS=PASS
4C_9_READY=YES

---

### 4C-9 — Business Chain Final Validation

Amac:
Is zincirinin bastan sona calistigini dogrulamak.

Zincir:

Urun -> Stok -> Satis -> Stok Dusme -> Cari/Rapor -> UAT Onay

Exit gate:

4C_9_BUSINESS_CHAIN_STATUS=PASS
4C_10_READY=YES

---

### 4C-10 — Go / No-Go Signoff

Amac:
Pilot kontrollu acilisa hazir mi kararini almak.

Karar yetkilisi:
mert ömür

Teknik takip:
PIX2PI_EKIBI

Exit gate:

4C_10_GO_NO_GO_STATUS=GO
4C_11_READY=YES

---

### 4C-11 — Controlled Pilot Go-Live

Amac:
Pilot isletmeyi kontrollu sekilde kullanima almak.

Kurallar:

1. Sinirli kullanici
2. Sinirli kapsam
3. Gunluk takip
4. Kritik hata durumunda durdurma
5. Pazaryeri canli entegrasyonu yok
6. e-Fatura/e-Arsiv zorunlulugu yok

Exit gate:

4C_11_CONTROLLED_GO_LIVE_STATUS=PASS
4C_12_READY=YES

---

### 4C-12 — Pilot Monitoring / Stabilization

Amac:
Pilot kullanim sirasinda sistemi izlemek ve stabil hale getirmek.

Kontrol edilecekler:

1. Hata loglari
2. Kullanici geri bildirimi
3. Islem basarisi
4. Performans notlari
5. Data tutarliligi
6. Bug listesi

Exit gate:

4C_12_STABILIZATION_STATUS=PASS
4C_13_READY=YES

---

### 4C-13 — FAZ 4C Final Closure

Amac:
FAZ 4C pilot fazini kapatmak ve FAZ 4D / FAZ 5 gecis kararini vermek.

Exit gate:

FAZ_4C_FINAL_STATUS=PASS
FAZ_4D_READY=YES
FAZ_5_TRANSITION_READY=YES

---

## 5. Pilot risk kaydi

| Risk | Seviye | Onlem |
|------|--------|-------|
| Pazar entegrasyonu beklentisi scope'u sisirebilir | HIGH | FAZ 4D olarak ayrildi |
| Paraşüt mevcut kullanimi veri beklentisi dogurabilir | MEDIUM | FAZ 4C'de sadece not/discovery |
| Urun/stok verisi Excel olarak yok | HIGH | Manuel veya kucuk veri setiyle baslanacak |
| 1000 stok kalemi import hatasi dogurabilir | MEDIUM | Once ornek veri, sonra genisletme |
| OEM/esdeger parca karmasasi | HIGH | Ilk pilotta not alani seviyesinde tutulacak |
| Barkod kullanilmamasi hizli satisi etkileyebilir | MEDIUM | Urun arama/OEM/stok kodu ile test |
| Tek kullaniciya bagimli UAT | MEDIUM | UAT notlari net kaydedilecek |

---

## 6. Pilot basari kriterleri

FAZ 4C basarili sayilmasi icin:

1. Tenant kurulmus olmali
2. Kullanici/rol calismali
3. Urun/stok verisi girilmeli
4. En az bir satis senaryosu calismali
5. Stok dusme dogrulanmali
6. Cari veya rapor hareketi dogrulanmali
7. UAT geri bildirimi alinmali
8. Kritik blocker kalmamali
9. Tenant izolasyon final check gecmeli
10. Go / No-Go karari alinmali

---

## 7. 4C-1.2 status

4C_1_2_EXECUTION_MASTER_PLAN_STATUS=PASS
4C_1_2_SELECTED_BUSINESS=uzmanparcaci
4C_1_2_SELECTED_SECTOR=OTO_YEDEK_PARCA
4C_1_2_SCOPE_FREEZE_STATUS=PASS
4C_1_2_MARKETPLACE_PHASE=FAZ_4D
4C_1_2_NEXT_STEP=4C_2
4C_2_READY=YES
